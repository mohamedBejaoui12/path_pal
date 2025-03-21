import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/post_model.dart';
import '../../interests/domain/interest_model.dart';
import '../../interests/data/interest_service.dart';

class PostService {
  final _supabase = Supabase.instance.client;
  final _interestService = InterestService();

  Future<PostModel> createPost({
    required String userEmail,
    required String title, 
    String? description, 
    String? imageUrl,
    required List<InterestModel> interests,
  }) async {
    try {
      // Validate inputs
      if (userEmail.isEmpty) {
        throw Exception('User email cannot be empty');
      }
      if (title.isEmpty) {
        throw Exception('Title cannot be empty');
      }

      // Verify interests exist in the database
      final allInterests = await _interestService.fetchAllInterests();
      final validInterests = interests.where((interest) => 
        allInterests.any((ai) => ai.id == interest.id)).toList();

      if (validInterests.isEmpty) {
        throw Exception('No valid interests selected');
      }

      // Prepare interests as list of names
      final interestNames = validInterests.map((i) => i.name).toList();

      // Prepare the insert data with null-safe checks
      final insertData = {
        'user_email': userEmail,
        'title': title,
        'description': description ?? '',
        'interests': interestNames,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add image link only if it's not null
      if (imageUrl != null && imageUrl.isNotEmpty) {
        insertData['image_link'] = imageUrl;
      }

      final response = await _supabase
          .from('user_post')
          .insert(insertData)
          .select()
          .single();

      // Ensure all required fields are present
      if (response == null) {
        throw Exception('Failed to create post');
      }

      return PostModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  Future<String?> uploadPostImage(String filePath) async {
    final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}${File(filePath).path.split('.').last}';
    
    try {
      await _supabase.storage
          .from('post_images')
          .upload(
            fileName, 
            File(filePath),
            fileOptions: FileOptions(upsert: true),
          );

      return _supabase.storage
          .from('post_images')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<List<InterestModel>> fetchInterests() async {
    return await InterestService().fetchAllInterests();
  }

  Future<List<PostModel>> fetchPosts() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
  
      // Update the query to include is_verified field
      final response = await _supabase.from('user_post').select('''
            *,
            user:user_email(name, family_name, profile_image_url, is_verified),
            post_likes:likes(user_email),
            comments_count:comments(count)
          ''').order('created_at', ascending: false);
  
      // Add verification status and current user email to each post
      return response.map<PostModel>((post) {
        final userEmail = post['user_email'].toString();
        post['current_user_email'] = currentUser.email;
        
        // Extract user data
        dynamic userData;
        if (post['user'] is List && post['user'].isNotEmpty) {
          userData = post['user'][0];
        } else if (post['user'] is Map) {
          userData = post['user'];
        } else {
          userData = {};
        }
        
        // Set verification status
        post['is_user_verified'] = userData['is_verified'] == true;
        
        return PostModel.fromJson(post);
      }).toList();
    } catch (e) {
      print('Error fetching posts: $e');
      throw Exception('Failed to fetch posts: $e');
    }
  }
}

// Add the provider
final postServiceProvider = Provider<PostService>((ref) {
  return PostService();
});