import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/business_model.dart';

final businessListProvider = StateNotifierProvider<BusinessListNotifier, AsyncValue<List<BusinessModel>>>((ref) {
  return BusinessListNotifier();
});

final businessSearchProvider = StateNotifierProvider<BusinessSearchNotifier, AsyncValue<List<BusinessModel>>>((ref) {
  return BusinessSearchNotifier();
});

class BusinessListNotifier extends StateNotifier<AsyncValue<List<BusinessModel>>> {
  BusinessListNotifier() : super(const AsyncValue.loading()) {
    fetchAllBusinesses();
  }

  final _supabase = Supabase.instance.client;

  Future<void> fetchAllBusinesses() async {
    try {
      final response = await _supabase
          .from('business')
          .select()
          .order('created_at', ascending: false);
      
      final businesses = response.map((data) => BusinessModel.fromJson(data)).toList();
      state = AsyncValue.data(businesses.cast<BusinessModel>());
    } catch (e, stackTrace) {
      debugPrint('Error fetching businesses: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

class BusinessSearchNotifier extends StateNotifier<AsyncValue<List<BusinessModel>>> {
  BusinessSearchNotifier() : super(const AsyncValue.data([]));

  final _supabase = Supabase.instance.client;

  Future<void> searchBusinesses(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final response = await _supabase
          .from('business')
          .select()
          .ilike('business_name', '%$query%')
          .order('created_at', ascending: false);
      
      final businesses = response.map((data) => BusinessModel.fromJson(data)).toList();
      state = AsyncValue.data(businesses.cast<BusinessModel>());
    } catch (e, stackTrace) {
      debugPrint('Error searching businesses: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }
}