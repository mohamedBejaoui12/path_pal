import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/business/domain/business_post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../interests/domain/interest_model.dart';

class BusinessPostService {
  final _supabase = Supabase.instance.client;

  Future<List<InterestModel>> fetchAllInterests() async {
    try {
      final response = await _supabase.from('interests').select('*');

      return response
          .map<InterestModel>((json) => InterestModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching interests: $e');
      return [];
    }
  }

  Future<BusinessPostModel> createBusinessPost({
    required int businessId,
    required String userEmail,
    required String businessName,
    required String title,
    String? description,
    String? imageUrl,
    required List<InterestModel> interests,
  }) async {
    try {
      // Validate inputs
      if (businessId <= 0) {
        throw Exception('Invalid business ID');
      }
      if (userEmail.isEmpty) {
        throw Exception('User email cannot be empty');
      }
      if (title.isEmpty) {
        throw Exception('Title cannot be empty');
      }

      // Verify interests exist in the database
      final allInterests = await fetchAllInterests();
      final validInterests = interests
          .where((interest) => allInterests.any((ai) => ai.id == interest.id))
          .toList();

      if (validInterests.isEmpty) {
        throw Exception(
            'No valid interests selected. Please select at least one interest.');
      }

      // Prepare interests as list of names
      final interestNames = validInterests.map((i) => i.name).toList();

      // Prepare the insert data with null-safe checks
      final insertData = {
        'business_id': businessId,
        'user_email': userEmail,
        'business_name': businessName,
        'title': title,
        'description': description ?? '',
        'interests': interestNames,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add image link only if it's not null
      if (imageUrl != null && imageUrl.isNotEmpty) {
        insertData['image_url'] = imageUrl;
      }

      // Insert the post and return the full inserted object
      final response = await _supabase
          .from('business_posts')
          .insert(insertData)
          .select()
          .single();

      // Explicitly print the response to debug
      debugPrint('Business Post Response: $response');

      return BusinessPostModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating business post: $e');
      rethrow;
    }
  }
  // Add this method to the BusinessPostService class

  Future<List<BusinessPostModel>> fetchBusinessPostsByBusinessId(
      int businessId) async {
    try {
      // Get current user's email directly from Supabase
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userEmail = currentUser?.email;

      // Fetch business posts for the specific business
      final postsResponse = await _supabase
          .from('business_posts')
          .select('*, businesses:business_id(*)')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      // Debug: Print the first post response to see structure
      if (postsResponse.isNotEmpty) {
        debugPrint('First post response: ${postsResponse[0]}');
        if (postsResponse[0]['businesses'] != null) {
          debugPrint('Business data: ${postsResponse[0]['businesses']}');
        }
      }

      // Prepare the final list of business posts
      final List<BusinessPostModel> businessPosts = [];
      for (var postJson in postsResponse) {
        // Count likes for this post
        final likesCountResponse = await _supabase
            .from('business_post_likes')
            .select('*')
            .eq('post_id', postJson['id']);

        // Check if current user liked the post
        bool isLikedByCurrentUser = false;
        if (userEmail != null) {
          final userLikeResponse = await _supabase
              .from('business_post_likes')
              .select()
              .eq('post_id', postJson['id'])
              .eq('user_email', userEmail)
              .maybeSingle();
          isLikedByCurrentUser = userLikeResponse != null;
        }

        // Get business profile image from the joined business data
        String? businessProfileImage;
        if (postJson['businesses'] != null &&
            postJson['businesses']['image_url'] != null) {
          // Use the URL directly from the database without any manipulation
          businessProfileImage = postJson['businesses']['image_url'];
          debugPrint('Using business profile image URL: $businessProfileImage');
        }

        final businessPost = BusinessPostModel.fromJson({
          ...postJson,
          'business_profile_image': businessProfileImage,
          'likesCount': likesCountResponse.length,
          'isLikedByCurrentUser': isLikedByCurrentUser,
        });
        businessPosts.add(businessPost);
      }
      return businessPosts;
    } catch (e) {
      debugPrint('Error fetching business posts by business ID: $e');
      return [];
    }
  }

  Future<List<BusinessPostModel>> fetchAllBusinessPosts() async {
    try {
      // Modify the query to include business data for profile images
      final response = await _supabase.from('business_posts').select('''
            *,
            business_post_likes(count),
            business_post_comments(count),
            businesses:business_id(image_url)
          ''').order('created_at', ascending: false);

      debugPrint('Raw business posts response: ${response.length} posts');

      // Get current user email for checking if post is liked
      final currentUserEmail = _supabase.auth.currentUser?.email;

      // Process the response
      return Future.wait((response as List).map((json) async {
        // Get likes count
        final likesCount = json['business_post_likes']?[0]?['count'] ?? 0;

        // Get comments count
        final commentsCount = json['business_post_comments']?[0]?['count'] ?? 0;

        // Get business profile image from the joined businesses table
        String? businessProfileImage;
        if (json['businesses'] != null &&
            json['businesses']['image_url'] != null) {
          businessProfileImage = json['businesses']['image_url'];
          // Clean the URL to ensure it's valid
          if (businessProfileImage != null) {
            businessProfileImage = businessProfileImage.trim();
          }
          debugPrint('Business profile image from DB: $businessProfileImage');
        }

        // Check if current user has liked the post
        bool isLikedByCurrentUser = false;
        if (currentUserEmail != null) {
          final likeResponse = await _supabase
              .from('business_post_likes')
              .select()
              .eq('post_id', json['id'])
              .eq('user_email', currentUserEmail)
              .maybeSingle();
          isLikedByCurrentUser = likeResponse != null;
        }

        // Map interests
        List<String> interests = [];
        if (json['interests'] != null) {
          interests = List<String>.from(json['interests']);
        }

        return BusinessPostModel(
          id: json['id'],
          businessId: json['business_id'],
          userEmail: json['user_email'],
          businessName: json['business_name'],
          businessProfileImage: businessProfileImage,
          title: json['title'],
          description: json['description'],
          imageUrl: json['image_url'],
          createdAt: DateTime.parse(json['created_at']),
          interests: interests,
          likesCount: likesCount,
          commentsCount: commentsCount,
          isLikedByCurrentUser: isLikedByCurrentUser,
        );
      }).toList());
    } catch (e, stackTrace) {
      debugPrint('Error fetching business posts: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<BusinessPostModel> updateBusinessPost({
    required int postId,
    required String userEmail,
    String? title,
    String? description,
    String? imageUrl,
    List<InterestModel>? interests,
  }) async {
    try {
      // Validate inputs
      if (postId <= 0) {
        throw Exception('Invalid post ID');
      }
      if (userEmail.isEmpty) {
        throw Exception('User email cannot be empty');
      }

      // Prepare the update data
      final updateData = <String, dynamic>{};

      // Add fields to update if they are not null
      if (title != null && title.isNotEmpty) {
        updateData['title'] = title;
      }
      if (description != null) {
        updateData['description'] = description;
      }
      if (imageUrl != null) {
        updateData['image_url'] = imageUrl;
      }
      if (interests != null && interests.isNotEmpty) {
        final validInterests = await fetchAllInterests();
        final interestNames = interests
            .where(
                (interest) => validInterests.any((ai) => ai.id == interest.id))
            .map((i) => i.name)
            .toList();

        if (interestNames.isNotEmpty) {
          updateData['interests'] = interestNames;
        }
      }

      // Verify the post belongs to the user
      final existingPost = await _supabase
          .from('business_posts')
          .select()
          .eq('id', postId)
          .eq('user_email', userEmail)
          .single();

      if (existingPost == null) {
        throw Exception(
            'Post not found or you do not have permission to update');
      }

      // Perform the update
      final response = await _supabase
          .from('business_posts')
          .update(updateData)
          .eq('id', postId)
          .select()
          .single();

      return BusinessPostModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating business post: $e');
      rethrow;
    }
  }

  Future<void> deleteBusinessPost({
    required int postId,
    required String userEmail,
  }) async {
    try {
      // Validate inputs
      if (postId <= 0) {
        throw Exception('Invalid post ID');
      }
      if (userEmail.isEmpty) {
        throw Exception('User email cannot be empty');
      }

      // Verify the post belongs to the user before deleting
      final existingPost = await _supabase
          .from('business_posts')
          .select()
          .eq('id', postId)
          .eq('user_email', userEmail)
          .single();

      if (existingPost == null) {
        throw Exception(
            'Post not found or you do not have permission to delete');
      }

      // Delete the post
      await _supabase.from('business_posts').delete().eq('id', postId);
    } catch (e) {
      debugPrint('Error deleting business post: $e');
      rethrow;
    }
  }
}

final businessPostServiceProvider = Provider<BusinessPostService>((ref) {
  return BusinessPostService();
});
