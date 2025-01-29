import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pfe1/features/authentication/domain/user_details_model.dart';

class UserDetailsState {
  final UserDetailsModel? userDetails;
  final bool isLoading;
  final String? error;

  UserDetailsState({
    this.userDetails,
    this.isLoading = false,
    this.error,
  });
}

class UserDetailsNotifier extends StateNotifier<UserDetailsState> {
  final _supabase = Supabase.instance.client;

  UserDetailsNotifier() : super(UserDetailsState());

  // Comprehensive method to test database connection and data retrieval
  Future<void> testDatabaseConnection() async {
    try {
      // Test 1: Check Supabase connection
      print('Testing Supabase connection...');
      final supabaseStatus = _supabase.auth.currentUser != null;
      print('Supabase connection status: $supabaseStatus');

      // Print current user info
      await printSupabaseUserInfo();
    } catch (e, stackTrace) {
      print('Database connection test failed: $e');
      print('Stacktrace: $stackTrace');
    }
  }

  // Method to print Supabase user information
  Future<void> printSupabaseUserInfo() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        print('🔐 Current Supabase User:');
        print('   - ID: ${currentUser.id}');
        print('   - Email: ${currentUser.email}');
        print('   - Created At: ${currentUser.createdAt}');
      } else {
        print('❌ No current Supabase user');
      }
    } catch (e) {
      print('❌ Error retrieving Supabase user info: $e');
    }
  }

  // Enhanced method to fetch and log user details
  Future<void> fetchUserDetails(String? email) async {
    // Reset state before starting
    state = UserDetailsState(isLoading: true);

    if (email == null) {
      print('❌ Error: Email is null');
      state = UserDetailsState(error: 'No email provided');
      return;
    }

    try {
      print('🔍 Attempting to fetch user details for email: $email');
      
      // Comprehensive query with detailed logging
      final response = await _supabase
          .from('user')
          .select('*')
          .eq('email', email)
          .maybeSingle();

      print('🌐 Supabase raw response: $response');

      if (response != null) {
        // Log all keys in the response
        print('📋 Response keys: ${response.keys}');

        // Flexible mapping with extensive null checks and logging
        final userDetails = UserDetailsModel(
          name: _extractValue(response, ['name', 'first_name'], ''),
          familyName: _extractValue(response, ['family_name', 'last_name'], ''),
          dateOfBirth: _parseDate(response['date_of_birth']),
          phoneNumber: _extractValue(response, ['phone_number', 'phone'], ''),
          cityOfBirth: _extractValue(response, ['city_of_birth', 'city'], ''),
          gender: _parseGender(response['gender']),
          email: email,
        );

        print('✅ Parsed user details: $userDetails');

        state = UserDetailsState(userDetails: userDetails);
      } else {
        print('❓ No user details found for email: $email');
        state = UserDetailsState(error: 'User details not found');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching user details: $e');
      print('🔍 Stacktrace: $stackTrace');
      state = UserDetailsState(error: e.toString());
    }
  }

  // Helper method to extract values with multiple possible keys
  String _extractValue(Map<String, dynamic> map, List<String> keys, String defaultValue) {
    for (var key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        print('🔑 Found value for key: $key');
        return map[key].toString();
      }
    }
    print('❓ No value found for keys: $keys');
    return defaultValue;
  }

  // Helper method to parse date with robust error handling
  DateTime _parseDate(dynamic dateValue) {
    try {
      if (dateValue == null) return DateTime.now();
      
      // Try multiple parsing strategies
      if (dateValue is String) {
        return DateTime.tryParse(dateValue) ?? DateTime.now();
      }
      if (dateValue is DateTime) {
        return dateValue;
      }
      
      return DateTime.now();
    } catch (e) {
      print('❌ Date parsing error: $e');
      return DateTime.now();
    }
  }

  // Helper method to parse gender with more flexibility
  Gender _parseGender(dynamic genderValue) {
    if (genderValue == null) return Gender.male;
    
    final genderString = genderValue.toString().toLowerCase();
    switch (genderString) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        print('❓ Unknown gender: $genderValue. Defaulting to male.');
        return Gender.male;
    }
  }

  Future<void> updateUserDetails(UserDetailsModel userDetails) async {
    state = UserDetailsState(isLoading: true);
    try {
      final userMap = {
        'name': userDetails.name,
        'family_name': userDetails.familyName,
        'date_of_birth': userDetails.dateOfBirth.toIso8601String(),
        'phone_number': userDetails.phoneNumber,
        'city_of_birth': userDetails.cityOfBirth,
        'gender': userDetails.gender.name,
      };

      print('🔄 Updating user details: $userMap');

      await _supabase
          .from('user')
          .update(userMap)
          .eq('email', userDetails.email);

      state = UserDetailsState(userDetails: userDetails);
      
      print('✅ User details updated successfully');
    } catch (e) {
      print('❌ Error updating user details: $e');
      state = UserDetailsState(error: e.toString());
    }
  }
}

final userDetailsProvider = StateNotifierProvider<UserDetailsNotifier, UserDetailsState>((ref) {
  return UserDetailsNotifier();
});