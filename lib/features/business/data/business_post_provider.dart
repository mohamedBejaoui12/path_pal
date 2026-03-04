import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/business/data/business_profile_service.dart';

import 'package:pfe1/features/business/data/business_service.dart';
import 'package:pfe1/features/business/domain/business_post_model.dart';
import 'package:pfe1/features/interests/domain/interest_model.dart';


import 'business_post_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../business/data/business_profile_provider.dart';

final businessProfileServiceProvider = Provider<BusinessProfileService>((ref) {
  return BusinessProfileService();
});


final businessPostsProvider = FutureProvider<List<BusinessPostModel>>((ref) async {
  final service = ref.read(businessPostServiceProvider);
  return await service.fetchAllBusinessPosts();
});

final businessProfileProvider = Provider<BusinessProfileProvider>((ref) {
  return BusinessProfileProvider(ref);
});

final businessPostServiceProvider = Provider<BusinessPostService>((ref) {
  return BusinessPostService();
});

final businessServiceProvider = Provider<BusinessService>((ref) {
  return BusinessService();
});


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
   
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;
      
      if (userEmail == null) {
        throw Exception('User must be authenticated');
      }

      final businessProfileProviderInstance = ref.read(businessProfileProvider);
      final businesses = await businessProfileProviderInstance.getUserBusinesses(userEmail);
      
      if (businesses.isEmpty) {
        throw Exception('No business found for the current user');
      }

      final business = businesses.first;

      print('Business Object: $business');
      print('Business ID: ${business.id}');

      final businessId = business.id;
      if (businessId == null) {
        throw Exception('Business ID is null');
      }

      String? imageUrl;
      if (imageFile != null) {
        final businessService = ref.read(businessServiceProvider);
        final imageBytes = await imageFile.readAsBytes();
        imageUrl = await businessService.uploadBusinessProfileImage(
          imageBytes, 
          imageFile.path
        );
      }

      final businessPostService = ref.read(businessPostServiceProvider);
      final businessPost = await businessPostService.createBusinessPost(
        businessId: businessId,  
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
      print('Error in createBusinessPost: $e');
      print('Stacktrace: $stackTrace');
      
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<BusinessPostModel?> updateBusinessPost({
    required int postId,
    required String title,
    String? description,
    File? imageFile,
    List<InterestModel>? interests,
  }) async {
    state = const AsyncValue.loading();

    try {
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;
      
      if (userEmail == null) {
        throw Exception('User must be authenticated');
      }

      String? imageUrl;
      if (imageFile != null) {
        final businessService = ref.read(businessServiceProvider);
        final imageBytes = await imageFile.readAsBytes();
        imageUrl = await businessService.uploadBusinessProfileImage(
          imageBytes, 
          imageFile.path
        );
      }

      final businessPostService = ref.read(businessPostServiceProvider);
      final businessPost = await businessPostService.updateBusinessPost(
        postId: postId,
        userEmail: userEmail,
        title: title,
        description: description,
        imageUrl: imageUrl,
        interests: interests,
      );

      state = AsyncValue.data(businessPost);
      return businessPost;
    } catch (e, stackTrace) {
      print('Error in updateBusinessPost: $e');
      print('Stacktrace: $stackTrace');
      
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<void> deleteBusinessPost({
    required int postId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;
      
      if (userEmail == null) {
        throw Exception('User must be authenticated');
      }

      final businessPostService = ref.read(businessPostServiceProvider);
      await businessPostService.deleteBusinessPost(
        postId: postId,
        userEmail: userEmail,
      );

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      print('Error in deleteBusinessPost: $e');
      print('Stacktrace: $stackTrace');
      
      state = AsyncValue.error(e, stackTrace);
    }
  }
}