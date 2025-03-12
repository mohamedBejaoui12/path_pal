import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/business_rate_model.dart';

class BusinessRateService {
  final _supabase = Supabase.instance.client;

  // Fetch all ratings for a business
  Future<List<BusinessRateModel>> fetchBusinessRatings(int businessId) async {
    try {
      // Fetch ratings for the business
      final response = await _supabase
          .from('business_rates')
          .select('*')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      // Process each rating to include user details
      final List<BusinessRateModel> ratings = [];
      for (var ratingJson in response) {
        // Get user details for each rating
        final userEmail = ratingJson['user_email'];
        final userResponse = await _supabase
            .from('user')  // Changed from 'profiles' to 'user'
            .select('name, family_name, profile_image_url')
            .eq('email', userEmail)
            .single();

        // Create a full name from name and family name
        final userName = userResponse != null
            ? '${userResponse['name']} ${userResponse['family_name']}'
            : 'Unknown User';

        // Add the rating with user details
        ratings.add(BusinessRateModel.fromJson({
          ...ratingJson,
          'user_name': userName,
          'user_profile_image': userResponse?['profile_image_url'],
        }));
      }

      return ratings;
    } catch (e) {
      debugPrint('Error fetching business ratings: $e');
      return [];
    }
  }

  // Calculate average rating for a business
  Future<double> calculateAverageRating(int businessId) async {
    try {
      final response = await _supabase
          .from('business_rates')
          .select('rating')
          .eq('business_id', businessId);

      if (response.isEmpty) {
        return 0.0;
      }

      final totalRating = response.fold<int>(
          0, (sum, item) => sum + (item['rating'] as int));
      return totalRating / response.length;
    } catch (e) {
      debugPrint('Error calculating average rating: $e');
      return 0.0;
    }
  }

  // Add or update a rating
  Future<BusinessRateModel> rateBusinesss({
    required int businessId,
    required String userEmail,
    required int rating,
    String? comment,
  }) async {
    try {
      // Validate inputs
      if (businessId <= 0) {
        throw Exception('Invalid business ID');
      }
      if (userEmail.isEmpty) {
        throw Exception('User email cannot be empty');
      }
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Check if user has already rated this business
      final existingRating = await _supabase
          .from('business_rates')
          .select()
          .eq('business_id', businessId)
          .eq('user_email', userEmail)
          .maybeSingle();

      Map<String, dynamic> response;
      if (existingRating != null) {
        // Update existing rating
        response = await _supabase
            .from('business_rates')
            .update({
              'rating': rating,
              'comment': comment,
              'created_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingRating['id'])
            .select()
            .single();
      } else {
        // Create new rating
        response = await _supabase
            .from('business_rates')
            .insert({
              'business_id': businessId,
              'user_email': userEmail,
              'rating': rating,
              'comment': comment,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
      }

      // Get user details
      final userResponse = await _supabase
          .from('user')  // Changed from 'profiles' to 'user'
          .select('name, family_name, profile_image_url')
          .eq('email', userEmail)
          .single();

      // Create a full name from name and family name
      final userName = userResponse != null
          ? '${userResponse['name']} ${userResponse['family_name']}'
          : 'Unknown User';

      // Return the rating with user details
      return BusinessRateModel.fromJson({
        ...response,
        'user_name': userName,
        'user_profile_image': userResponse?['profile_image_url'],
      });
    } catch (e) {
      debugPrint('Error rating business: $e');
      rethrow;
    }
  }

  // Delete a rating
  Future<void> deleteRating({
    required int ratingId,
    required String userEmail,
  }) async {
    try {
      // Validate inputs
      if (ratingId <= 0) {
        throw Exception('Invalid rating ID');
      }
      if (userEmail.isEmpty) {
        throw Exception('User email cannot be empty');
      }

      // Verify the rating belongs to the user before deleting
      final existingRating = await _supabase
          .from('business_rates')
          .select()
          .eq('id', ratingId)
          .eq('user_email', userEmail)
          .single();

      if (existingRating == null) {
        throw Exception(
            'Rating not found or you do not have permission to delete');
      }

      // Delete the rating
      await _supabase.from('business_rates').delete().eq('id', ratingId);
    } catch (e) {
      debugPrint('Error deleting rating: $e');
      rethrow;
    }
  }
}

final businessRateServiceProvider = Provider<BusinessRateService>((ref) {
  return BusinessRateService();
});