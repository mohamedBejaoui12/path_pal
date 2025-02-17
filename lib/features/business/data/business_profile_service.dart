import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/business_model.dart';

class BusinessProfileService {
  final _supabase = Supabase.instance.client;

  Future<BusinessModel?> getBusinessByUserEmail(String userEmail) async {
    try {
      final response = await _supabase
          .from('business')
          .select()
          .eq('user_email', userEmail)
          .single();
      
      return BusinessModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching business details: $e');
      return null; // Return null if no business found
    }
  }

  Future<BusinessModel> getBusinessDetails(int businessId) async {
    try {
      final response = await _supabase
          .from('business')
          .select()
          .eq('id', businessId)
          .single();
      
      return BusinessModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching business details: $e');
      rethrow;
    }
  }

  Future<List<BusinessModel>> getBusinessesByUserEmail(String userEmail) async {
    try {
      final response = await _supabase
          .from('business')
          .select()
          .eq('user_email', userEmail);
      
      // Convert each row to BusinessModel
      return response.map<BusinessModel>((json) => BusinessModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching businesses for user: $e');
      return []; // Return empty list if no businesses found or error occurs
    }
  }

  Future<int> countBusinessesByUserEmail(String userEmail) async {
    try {
      final response = await _supabase
          .from('business')
          .select('id')
          .eq('user_email', userEmail)
          .count();
      
      return response.count;
    } catch (e) {
      print('Error counting businesses for user: $e');
      return 0;
    }
  }
}