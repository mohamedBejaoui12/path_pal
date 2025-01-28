import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_details_model.dart';

class UserDetailsService {
  final _supabase = Supabase.instance.client;

  Future<int> saveUserDetails(UserDetailsModel userDetails) async {
  try {
    // Check if a user with this email already exists
    final existingUserResponse = await _supabase
        .from('user')
        .select('id')
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
      
      // Return the existing user's ID
      return existingUserResponse['id'];
    } else {
      // Insert new user and return the new ID
      final response = await _supabase
          .from('user')
          .insert(userMap)
          .select('id')
          .single();
      
      return response['id'];
    }
  } catch (e) {
    debugPrint('Error saving user details: $e');
    rethrow;
  }
}}