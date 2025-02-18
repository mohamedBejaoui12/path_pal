import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/business/data/business_profile_service.dart';
import 'package:pfe1/features/business/data/business_provider.dart';
import 'package:pfe1/features/business/data/business_service.dart';
import 'package:pfe1/features/business/domain/business_post_model.dart';
import 'package:pfe1/features/interests/domain/interest_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'business_post_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../business/data/business_profile_provider.dart';

// Declare businessProfileServiceProvider first
final businessProfileServiceProvider = Provider<BusinessProfileService>((ref) {
  return BusinessProfileService();
});

// Declare BusinessProfileProvider before using it
final businessProfileProvider = Provider<BusinessProfileProvider>((ref) {
  return BusinessProfileProvider(ref);
});

// Declare businessPostServiceProvider before using it
final businessPostServiceProvider = Provider<BusinessPostService>((ref) {
  return BusinessPostService();
});

// Declare businessServiceProvider before using it
final businessServiceProvider = Provider<BusinessService>((ref) {
  return BusinessService();
});

// Interest Provider
final interestProvider = FutureProvider<List<InterestModel>>((ref) async {
  final service = ref.read(businessPostServiceProvider);
  return service.fetchAllInterests();
});

final createBusinessPostProvider = StateNotifierProvider<CreateBusinessPostNotifier, AsyncValue<BusinessPostModel?>>((ref) {
  return CreateBusinessPostNotifier(ref);
});

class CreateBusinessPostNotifier extends StateNotifier<AsyncValue<BusinessPostModel?>> {
  final Ref ref;

  CreateBusinessPostNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<BusinessPostModel?> createBusinessPost({
    required String title,
    String? description,
    File? imageFile,
    required List<InterestModel> interests,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Get current user and business
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;
      
      if (userEmail == null) {
        throw Exception('User must be authenticated');
      }

      // More robust business retrieval
      final businessProfileProviderInstance = ref.read(businessProfileProvider);
      final businesses = await businessProfileProviderInstance.getUserBusinesses(userEmail);
      
      if (businesses.isEmpty) {
        throw Exception('No business found for the current user');
      }

      // Use the first business if multiple exist
      final business = businesses.first;

      // Debug print to check business object
      print('Business Object: $business');
      print('Business ID: ${business.id}');

      // Ensure businessId is a valid number
      final businessId = business.id;
      if (businessId == null) {
        throw Exception('Business ID is null');
      }

      // Upload image if exists
      String? imageUrl;
      if (imageFile != null) {
        final businessService = ref.read(businessServiceProvider);
        final imageBytes = await imageFile.readAsBytes();
        imageUrl = await businessService.uploadBusinessProfileImage(
          imageBytes, 
          imageFile.path
        );
      }

      // Create business post
      final businessPostService = ref.read(businessPostServiceProvider);
      final businessPost = await businessPostService.createBusinessPost(
        businessId: businessId,  // Use the original business ID
        userEmail: userEmail,
        businessName: business.businessName,
        title: title,
        description: description,
        imageUrl: imageUrl,
        interests: interests,
      );

      state = AsyncValue.data(businessPost);
      return businessPost;
    } catch (e, stackTrace) {
      // Log the full error for debugging
      print('Error in createBusinessPost: $e');
      print('Stacktrace: $stackTrace');
      
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
}