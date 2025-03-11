import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Search for users by name, email, etc.
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _supabase
          .from('user') // Changed from 'user_details' to 'user'
          .select('*')
          .or('name.ilike.%$query%,family_name.ilike.%$query%,email.ilike.%$query%')
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Search for businesses by name, email, etc.
  Future<List<Map<String, dynamic>>> searchBusinesses(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _supabase
          .from('business')
          .select('*')
          .or('business_name.ilike.%$query%,email.ilike.%$query%')
          // Removed description from the query since it doesn't exist
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching businesses: $e');
      return [];
    }
  }

  // Combined search for both users and businesses
  Future<Map<String, List<Map<String, dynamic>>>> searchAll(
      String query) async {
    if (query.isEmpty) {
      return {
        'users': [],
        'businesses': [],
      };
    }

    try {
      final users = await searchUsers(query);
      final businesses = await searchBusinesses(query);

      return {
        'users': users,
        'businesses': businesses,
      };
    } catch (e) {
      debugPrint('Error in combined search: $e');
      return {
        'users': [],
        'businesses': [],
      };
    }
  }
}
