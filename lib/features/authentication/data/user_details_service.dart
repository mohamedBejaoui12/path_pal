import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_details_model.dart';

class UserDetailsService {
  final _supabase = Supabase.instance.client;

  Future<void> saveUserDetails(UserDetailsModel userDetails) async {
    try {
      // Check if a user with this email already exists
      final existingUserResponse = await _supabase
          .from('user')
          .select()
          .eq('email', userDetails.email)
          .maybeSingle();

      final userMap = {
        'name': userDetails.name,
        'family_name': userDetails.familyName,
        'date_of_birth': userDetails.dateOfBirth.toIso8601String(),
        'phone_number': userDetails.phoneNumber,
        'city_of_birth': userDetails.cityOfBirth,
        'gender': userDetails.gender.name,
        'email': userDetails.email,
      };

      if (existingUserResponse != null) {
        // Update existing user
        await _supabase
            .from('user')
            .update(userMap)
            .eq('email', userDetails.email);
      } else {
        // Insert new user
        await _supabase.from('user').insert(userMap);
      }
    } catch (e) {
      debugPrint('Error saving user details: $e');
      rethrow;
    }
  }
}