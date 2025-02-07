import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path_util;

import '../domain/post_model.dart';
import '../../authentication/providers/auth_provider.dart';

class PostListState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;

  PostListState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });

  get hasMore => null;

  PostListState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    String? error,
  }) {
    return PostListState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PostListNotifier extends StateNotifier<PostListState> {
  final Ref ref;
  final _supabase = Supabase.instance.client;

  PostListNotifier(this.ref) : super(PostListState());

  Future<void> fetchPosts() async {
    try {
      state = state.copyWith(isLoading: true);

      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;

      if (userEmail == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('user_post')
          .select('''
        *,
        user:user_email(name, family_name, profile_image_url),
        post_likes(*)
      ''')
          .order('created_at', ascending: false);

      final posts = (response as List).map((json) {
        // Safely extract user data
        final userData = (json['user'] is List && json['user'].isNotEmpty)
            ? json['user'][0]
            : {};

        // Provide fallback for user details
        json['user_name'] = userData['name'] ?? 'Anonymous';
        json['user_profile_image'] = userData['profile_image_url'] ??
            _generateDefaultProfileImage(userData['name'] ?? 'A');

        // Explicitly check likes for current user
        final likes = json['post_likes'] as List? ?? [];
        final isLikedByCurrentUser = likes.any(
          (like) => like['user_email'] == userEmail
        );

        // Update JSON with explicit like information
        json['is_liked_by_current_user'] = isLikedByCurrentUser;
        json['likes_count'] = likes.length;

        return PostModel.fromJson(json);
      }).toList();

      state = state.copyWith(
        posts: posts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      debugPrint('Error fetching posts: $e');
    }
  }

  // Add this helper method
  String _generateDefaultProfileImage(String name) {
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff&size=200';
  }

  String _getContentType(String filePath) {
    final extension = path_util.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> toggleLike(int postId) async {
    try {
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;

      if (userEmail == null) {
        throw Exception('User not authenticated');
      }

      // Create a copy of current posts to modify
      final currentPosts = [...state.posts];

      // Find the index of the post to update
      final postIndex = currentPosts.indexWhere((post) => post.id == postId);

      if (postIndex == -1) {
        throw Exception('Post not found');
      }

      final currentPost = currentPosts[postIndex];

      // Determine if the post is currently liked
      final isCurrentlyLiked = currentPost.isLikedByCurrentUser;

      // Perform like/unlike operation with error handling
      try {
        // Try to find existing like
        final existingLikeResponse = await _supabase
            .from('post_likes')
            .select('id')
            .eq('post_id', postId)
            .eq('user_email', userEmail)
            .maybeSingle();

        if (existingLikeResponse != null) {
          // Unlike: remove the like
          await _supabase
              .from('post_likes')
              .delete()
              .eq('post_id', postId)
              .eq('user_email', userEmail);
        } else {
          // Like: add a new like
          await _supabase
              .from('post_likes')
              .insert({
                'post_id': postId,
                'user_email': userEmail,
              });
        }
      } on PostgrestException catch (postgrestError) {
        // Handle Supabase-specific errors
        debugPrint('Supabase Error during like toggle: ${postgrestError.message}');
        throw Exception('Failed to update like status: ${postgrestError.message}');
      }

      // Update the post locally with optimistic update
      currentPosts[postIndex] = currentPost.copyWith(
        isLikedByCurrentUser: !isCurrentlyLiked,
        likesCount: isCurrentlyLiked 
          ? currentPost.likesCount - 1 
          : currentPost.likesCount + 1,
      );

      // Update the state with the modified posts
      state = state.copyWith(posts: currentPosts);
    } catch (e) {
      // Log the error and rethrow to allow UI to handle
      debugPrint('Comprehensive Error toggling like: $e');
      rethrow;
    }
  }

  Future<void> deletePost(int postId, {VoidCallback? onPostDeleted}) async {
    try {
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;

      if (userEmail == null) {
        throw Exception('User not authenticated');
      }

      // First, verify the post belongs to the current user
      final postToDelete = await _supabase
          .from('user_post')
          .select('user_email')
          .eq('id', postId)
          .single();

      if (postToDelete['user_email'] != userEmail) {
        throw Exception('You can only delete your own posts');
      }

      // Delete related likes first to avoid foreign key constraints
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId);

      // Delete the post
      await _supabase
          .from('user_post')
          .delete()
          .eq('id', postId);

      // Remove the post from local state
      final updatedPosts = state.posts.where((post) => post.id != postId).toList();
      state = state.copyWith(posts: updatedPosts);

      // Call the optional callback if provided
      onPostDeleted?.call();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  Future<void> updatePost({
    required int postId,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? interests,
    VoidCallback? onPostUpdated,
  }) async {
    try {
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;

      if (userEmail == null) {
        throw Exception('User not authenticated');
      }

      // First, verify the post belongs to the current user
      final postToUpdate = await _supabase
          .from('user_post')
          .select('user_email')
          .eq('id', postId)
          .single();

      if (postToUpdate['user_email'] != userEmail) {
        throw Exception('You can only update your own posts');
      }

      // Prepare update data (only include non-null values)
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      
      // Handle local file upload
      if (imageUrl != null) {
        final file = File(imageUrl);
        if (file.existsSync()) {
          // Validate file size
          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            throw Exception('Image size exceeds 10MB limit');
          }

          // Generate unique filename
          final fileName = '${userEmail}_post_${postId}_${DateTime.now().millisecondsSinceEpoch}${path_util.extension(imageUrl)}';

          // Upload to Supabase storage
          await _supabase.storage
              .from('post_images')
              .upload(
                fileName, 
                file,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: _getContentType(imageUrl),
                ),
              );

          // Get public URL
          final uploadedImageUrl = _supabase.storage
              .from('post_images')
              .getPublicUrl(fileName);
          
          updateData['image_link'] = uploadedImageUrl;
        } else if (imageUrl.startsWith('http')) {
          // If it's already a URL, use it directly
          updateData['image_link'] = imageUrl;
        }
      }
      
      if (interests != null) updateData['interests'] = interests;

      // Update the post in Supabase
      await _supabase
          .from('user_post')
          .update(updateData)
          .eq('id', postId);

      // Update the post in local state
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            title: title ?? post.title,
            description: description ?? post.description,
            imageUrl: updateData['image_link'] ?? post.imageUrl,
            interests: interests ?? post.interests,
          );
        }
        return post;
      }).toList();

      state = state.copyWith(posts: updatedPosts);

      // Call the optional callback if provided
      onPostUpdated?.call();
    } catch (e) {
      debugPrint('Error updating post: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final postListProvider = StateNotifierProvider<PostListNotifier, PostListState>((ref) {
  return PostListNotifier(ref);
});