import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/home/domain/comment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/providers/auth_provider.dart';
import '../../authentication/data/user_details_provider.dart';

class CommentService {
  final _supabase = Supabase.instance.client;

  Future<CommentModel> addComment({
    required int postId, 
    required String commentText,
    required String userEmail,
  }) async {
    try {
      // Fetch user details
      final userDetails = await _fetchUserDetails(userEmail);

      // Prepare comment data
      final commentData = {
        'post_id': postId,
        'user_email': userEmail,
        'comment_text': commentText,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert comment to database
      final response = await _supabase
          .from('post_comments')
          .insert(commentData)
          .select()
          .single();

      // Update comment count in user_posts
      await _supabase
          .rpc('increment_post_comment_count', params: {
            'p_post_id': postId,
          });

      // Convert to CommentModel
      return CommentModel(
        id: response['id'],
        userEmail: userEmail,
        userName: '${userDetails['name']} ${userDetails['family_name']}'.trim(),
        userProfileImage: userDetails['profile_image_url'] ?? '',
        commentText: commentText,
        createdAt: DateTime.now(),
        postId: postId,
      );
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  Future<List<CommentModel>> fetchComments(int postId) async {
    try {
      debugPrint('Fetching comments for postId: $postId');

      // First, fetch comments for the specific post
      final commentsResponse = await _supabase
          .from('post_comments')
          .select('*')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      debugPrint('Raw comments response: $commentsResponse');

      if (commentsResponse.isEmpty) {
        debugPrint('No comments found for post $postId');
        return [];
      }

      // Process comments and fetch user details for each comment
      final List<CommentModel> comments = [];
      for (var commentData in commentsResponse) {
        // Fetch user details for each comment
        final userResponse = await _supabase
            .from('user')
            .select('name, family_name, profile_image_url')
            .eq('email', commentData['user_email'])
            .single();

        debugPrint('User details for comment: $userResponse');

        comments.add(CommentModel(
          id: commentData['id'],
          userEmail: commentData['user_email'] ?? '',
          userName: '${userResponse['name'] ?? ''} ${userResponse['family_name'] ?? ''}'.trim(),
          userProfileImage: userResponse['profile_image_url'] ?? '',
          commentText: commentData['comment_text'] ?? '',
          createdAt: DateTime.tryParse(commentData['created_at'].toString()) ?? DateTime.now(),
          postId: postId,
        ));
      }

      debugPrint('Processed comments: $comments');
      return comments;
    } catch (e, stackTrace) {
      debugPrint('Comprehensive error fetching comments:');
      debugPrint('Error: $e');
      debugPrint('Stacktrace: $stackTrace');
      return [];
    }
  }

  Future<dynamic> _fetchUserDetails(String userEmail) async {
    final response = await _supabase
        .from('user')
        .select()
        .eq('email', userEmail)
        .single();
            print('User details structure: ${response.runtimeType}');
    print('User details content: $response');
    return response;
  }
}

// Provider for CommentService
final commentServiceProvider = Provider<CommentService>((ref) {
  return CommentService();
});