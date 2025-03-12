import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/business_rate_model.dart';
import 'business_rate_service.dart';

// Provider for business ratings
final businessRatingsProvider = FutureProvider.family<List<BusinessRateModel>, int>((ref, businessId) async {
  final rateService = ref.read(businessRateServiceProvider);
  return rateService.fetchBusinessRatings(businessId);
});

// Provider for business average rating
final businessAverageRatingProvider = FutureProvider.family<double, int>((ref, businessId) async {
  final rateService = ref.read(businessRateServiceProvider);
  return rateService.calculateAverageRating(businessId);
});

// Provider for rating a business
final businessRatingControllerProvider = StateNotifierProvider<BusinessRatingController, AsyncValue<void>>((ref) {
  return BusinessRatingController(ref);
});

class BusinessRatingController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final BusinessRateService _rateService;

  BusinessRatingController(this.ref) 
      : _rateService = ref.read(businessRateServiceProvider),
        super(const AsyncValue.data(null));

  Future<void> rateBusiness({
    required int businessId,
    required String userEmail,
    required int rating,
    String? comment,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _rateService.rateBusinesss(
        businessId: businessId,
        userEmail: userEmail,
        rating: rating,
        comment: comment,
      );
      
      // Invalidate the providers to refresh the data
      ref.invalidate(businessRatingsProvider(businessId));
      ref.invalidate(businessAverageRatingProvider(businessId));
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteRating({
    required int ratingId,
    required String userEmail,
    required int businessId,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _rateService.deleteRating(
        ratingId: ratingId,
        userEmail: userEmail,
      );
      
      // Invalidate the providers to refresh the data
      ref.invalidate(businessRatingsProvider(businessId));
      ref.invalidate(businessAverageRatingProvider(businessId));
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}