import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/business/domain/business_post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../interests/domain/interest_model.dart';
import '../../interests/data/interest_service.dart';

class BusinessPostService {
  final _supabase = Supabase.instance.client;
  final _interestService = InterestService();

  Future<List<InterestModel>> fetchAllInterests() async {
    try {
      final response = await _supabase
          .from('interests')
          .select('*');
      
      return response.map<InterestModel>((json) => 
          InterestModel.fromJson(json)).toList();
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
      final validInterests = interests.where((interest) => 
        allInterests.any((ai) => ai.id == interest.id)).toList();

      if (validInterests.isEmpty) {
        throw Exception('No valid interests selected. Please select at least one interest.');
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
}

final businessPostServiceProvider = Provider<BusinessPostService>((ref) {
  return BusinessPostService();
});