import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      
      // Check if post is liked by current user
      final likes = json['post_likes'] as List?;
      json['is_liked_by_current_user'] = 
        likes != null && 
        likes.any((like) => like['user_email'] == userEmail);
      json['likes_count'] = likes?.length ?? 0;

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

    // Update the post locally
    currentPosts[postIndex] = currentPost.copyWith(
      isLikedByCurrentUser: !isCurrentlyLiked,
      likesCount: isCurrentlyLiked 
        ? currentPost.likesCount - 1 
        : currentPost.likesCount + 1,
    );

    // Update the state with the modified posts
    state = state.copyWith(posts: currentPosts);
  } catch (e) {
    debugPrint('Error toggling like: $e');
    rethrow;
  }
}}

final postListProvider = StateNotifierProvider<PostListNotifier, PostListState>((ref) {
  return PostListNotifier(ref);
});