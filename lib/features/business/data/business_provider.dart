import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:io';

import '../domain/business_model.dart';
import 'business_service.dart';
import '../../authentication/providers/auth_provider.dart';

final businessServiceProvider = Provider<BusinessService>((ref) {
  return BusinessService();
});

final createBusinessProvider = StateNotifierProvider<CreateBusinessNotifier, AsyncValue<BusinessModel?>>((ref) {
  return CreateBusinessNotifier(ref);
});

class CreateBusinessNotifier extends StateNotifier<AsyncValue<BusinessModel?>> {
  final Ref ref;

  CreateBusinessNotifier(this.ref) : super(const AsyncValue.data(null));

 Future<BusinessModel?> createBusinessWithImage({
  required String businessName,
  required String email,
  required double latitude,
  required double longitude,
  required File imageFile,
  String? category, // Added category parameter
}) async {
  state = const AsyncValue.loading();

  try {
    // Get current user
    final authState = ref.read(authProvider);
    if (authState.user == null) {
      throw Exception('User must be authenticated');
    }

    // Upload image
    final businessService = ref.read(businessServiceProvider);
    final imageBytes = await imageFile.readAsBytes();
    final imageUrl = await businessService.uploadBusinessProfileImage(
      imageBytes, 
      imageFile.path
    );

    // Create business model without ID
    final business = BusinessModel.create(
      businessName: businessName,
      email: email,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      userEmail: authState.user!.email!,
      category: category, // Added category parameter
    );

    // Create business in database
    final createdBusiness = await businessService.createBusiness(business);

    state = AsyncValue.data(createdBusiness);
    return createdBusiness;
  } catch (e, stackTrace) {
    state = AsyncValue.error(e, stackTrace);
    return null;
  }
}
}