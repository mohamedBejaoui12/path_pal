import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/business_model.dart';
import 'business_profile_service.dart';
import '../../authentication/providers/auth_provider.dart';

final businessProfileServiceProvider = Provider<BusinessProfileService>((ref) {
  return BusinessProfileService();
});

final currentUserBusinessProvider = FutureProvider<BusinessModel?>((ref) async {
  final authState = ref.watch(authProvider);
  final userEmail = authState.user?.email;
  
  if (userEmail == null) {
    return null;
  }
  
  final service = ref.read(businessProfileServiceProvider);
  return await service.getBusinessByUserEmail(userEmail);
});

final businessDetailsProvider = StateNotifierProvider.family<
  BusinessDetailsNotifier, 
  AsyncValue<BusinessModel?>, 
  int
>((ref, businessId) {
  return BusinessDetailsNotifier(ref, businessId);
});

class BusinessDetailsNotifier extends StateNotifier<AsyncValue<BusinessModel?>> {
  final Ref ref;
  final int businessId;

  BusinessDetailsNotifier(this.ref, this.businessId) : super(const AsyncValue.loading()) {
    fetchBusinessDetails();
  }

  Future<void> fetchBusinessDetails() async {
    try {
      final service = ref.read(businessProfileServiceProvider);
      final business = await service.getBusinessDetails(businessId);
      state = AsyncValue.data(business);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final businessProfileProvider = Provider<BusinessProfileProvider>((ref) {
  return BusinessProfileProvider(ref);
});

class BusinessProfileProvider {
  final Ref ref;

  BusinessProfileProvider(this.ref);

  Future<List<BusinessModel>> getUserBusinesses(String userEmail) async {
    try {
      final service = ref.read(businessProfileServiceProvider);
      
      // Fetch businesses for the user
      final response = await service.getBusinessesByUserEmail(userEmail);
      
      return response;
    } catch (e) {
      debugPrint('Error getting user businesses: $e');
      return [];
    }
  }

  Future<bool> canCreateBusiness(String userEmail) async {
    try {
      final service = ref.read(businessProfileServiceProvider);
      final businessCount = await service.countBusinessesByUserEmail(userEmail);
      
      // Allow only one business per user
      return businessCount == 0;
    } catch (e) {
      debugPrint('Error checking business creation: $e');
      return false;
    }
  }

  Future<BusinessModel?> getFirstUserBusiness(String userEmail) async {
    try {
      final businesses = await getUserBusinesses(userEmail);
      return businesses.isNotEmpty ? businesses.first : null;
    } catch (e) {
      debugPrint('Error getting first user business: $e');
      return null;
    }
  }
}