import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/interest_model.dart';

class InterestService {
  final _supabase = Supabase.instance.client;

  Future<List<InterestModel>> fetchAllInterests() async {
    try {
      final response = await _supabase
          .from('interests')
          .select('id, name, emoji')
          .order('name');

      return response
          .map<InterestModel>((json) => InterestModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching interests: $e');
      rethrow;
    }
  }

  Future<void> saveUserInterests({
    required int userId, 
    required List<int> interestIds
  }) async {
    try {
      // Delete existing user interests
      await _supabase
          .from('user_interests')
          .delete()
          .eq('user_id', userId);

      // Insert new user interests
      final userInterests = interestIds.map((interestId) => {
        'user_id': userId,
        'interest_id': interestId,
      }).toList();

      await _supabase.from('user_interests').insert(userInterests);
    } catch (e) {
      debugPrint('Error saving user interests: $e');
      rethrow;
    }
  }
}