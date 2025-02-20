import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pfe1/features/home/domain/comment_model.dart';

class BusinessPostCommentService {
  final _supabase = Supabase.instance.client;

  Future<List<CommentModel>> fetchComments(int businessPostId) async {
    try {
      debugPrint('Fetching comments for business post ID: $businessPostId');
      
      final response = await _supabase
          .from('business_post_comments')
          .select('*, user:user_email(name, family_name, profile_image_url)')
          .eq('business_post_id', businessPostId)
          .order('created_at', ascending: false);

      debugPrint('Raw response: $response');

      // Validate and map comments
      return (response as List).map((json) {
        // Handle user data
        final userData = json['user'] is List && json['user'].isNotEmpty 
          ? json['user'][0] 
          : {};

        // Construct comment JSON
        final commentJson = {
          'id': json['id'],
          'postId': json['business_post_id'],
          'userEmail': json['user_email'],
          'userName': userData['name'] ?? userData['family_name'] ?? 'Anonymous',
          'userProfileImage': userData['profile_image_url'] ?? 
              _generateDefaultProfileImage(
                userData['name'] ?? userData['family_name'] ?? 'Anonymous'
              ),
          'commentText': json['comment_text'],
          'createdAt': json['created_at'],
        };

        return CommentModel.fromJson(commentJson);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching business post comments: $e');
      return [];
    }
  }

  Future<CommentModel> addComment({
    required int businessPostId, 
    required String commentText,
    required String userEmail,
  }) async {
    try {
      final response = await _supabase
          .from('business_post_comments')
          .insert({
            'business_post_id': businessPostId,
            'user_email': userEmail,
            'comment_text': commentText,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*, user:user_email(name, family_name, profile_image_url)')
          .single();

      debugPrint('Add comment response: $response');

      // Handle user data
      final userData = response['user'] is List && response['user'].isNotEmpty 
        ? response['user'][0] 
        : {};

      // Construct comment JSON
      final commentJson = {
        'id': response['id'],
        'postId': response['business_post_id'],
        'userEmail': response['user_email'],
        'userName': userData['name'] ?? userData['family_name'] ?? 'Anonymous',
        'userProfileImage': userData['profile_image_url'] ?? 
            _generateDefaultProfileImage(
              userData['name'] ?? userData['family_name'] ?? 'Anonymous'
            ),
        'commentText': response['comment_text'],
        'createdAt': response['created_at'],
      };

      return CommentModel.fromJson(commentJson);
    } catch (e) {
      debugPrint('Error adding business post comment: $e');
      rethrow;
    }
  }

  // Helper method to generate default profile image
  String _generateDefaultProfileImage(String name) {
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff&size=200';
  }
}

final businessPostCommentServiceProvider = Provider<BusinessPostCommentService>((ref) {
  return BusinessPostCommentService();
});