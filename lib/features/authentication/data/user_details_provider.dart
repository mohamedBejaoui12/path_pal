import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
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

  UserDetailsState copyWith({
    UserDetailsModel? userDetails,
    bool? isLoading,
    String? error,
  }) {
    return UserDetailsState(
      userDetails: userDetails ?? this.userDetails,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserDetailsNotifier extends StateNotifier<UserDetailsState> {
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  UserDetailsNotifier() : super(UserDetailsState());

  Future<void> fetchUserDetails(String? email) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    if (email == null) throw Exception('No email provided');

    final response = await _supabase
        .from('user')
        .select()
        .eq('email', email)
        .single();

    if (response == null) throw Exception('User not found');

    final userDetails = _validateAndParseUserDetails(response, email);

    state = state.copyWith(
      userDetails: userDetails,
      isLoading: false,
      error: null,
    );
  } catch (e) {
    print('Error fetching user details: $e');
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}

  Future<void> updateUserDetails(UserDetailsModel userDetails) async {
    try {
      await _supabase
          .from('user')
          .update({
        'name': userDetails.name,
        'family_name': userDetails.familyName,
        'date_of_birth': userDetails.dateOfBirth.toIso8601String(),
        'phone_number': userDetails.phoneNumber,
        'city_of_birth': userDetails.cityOfBirth,
        'gender': userDetails.gender.name,
        'description': userDetails.description,
      })
          .eq('email', userDetails.email);

      state = state.copyWith(userDetails: userDetails);
    } catch (e) {
      print('Error updating user details: $e');
      rethrow;
    }
  }

  Future<String?> uploadProfileImage(String email) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image size exceeds 5MB limit');
      }
      final fileName = '${email}_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';

      await _supabase.storage
          .from('user_profile_images')
          .upload(
            fileName, 
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getContentType(pickedFile.path),
            ),
          );

      final imageUrl = _supabase.storage
          .from('user_profile_images')
          .getPublicUrl(fileName);

      await _updateProfileImageUrl(email, imageUrl);

      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> _updateProfileImageUrl(String email, String imageUrl) async {
    try {
      await _supabase
          .from('user')
          .update({'profile_image_url': imageUrl})
          .eq('email', email);

      if (state.userDetails != null) {
        final updatedUserDetails = state.userDetails!.copyWith(profileImageUrl: imageUrl);
        state = state.copyWith(userDetails: updatedUserDetails);
      }
    } catch (e) {
      print('Error updating profile image URL: $e');
      rethrow;
    }
  }

  UserDetailsModel _validateAndParseUserDetails(Map<String, dynamic> response, String email) {
    return UserDetailsModel(
      name: _parseStringValue(response['name']),
      familyName: _parseStringValue(response['family_name']),
      dateOfBirth: _parseDateOfBirth(response['date_of_birth']),
      phoneNumber: _parseStringValue(response['phone_number']),
      cityOfBirth: _parseStringValue(response['city_of_birth']),
      gender: _parseGender(response['gender']),
      email: email,
      profileImageUrl: response['profile_image_url'],
      description: _parseStringValue(response['description']),
    );
  }

  String _parseStringValue(dynamic value, {String defaultValue = ''}) {
    return value?.toString() ?? defaultValue;
  }

  DateTime _parseDateOfBirth(dynamic dobValue) {
    try {
      return dobValue != null ? DateTime.parse(dobValue.toString()) : DateTime.now();
    } catch (e) {
      print('Invalid date of birth: $dobValue');
      return DateTime.now();
    }
  }

  Gender _parseGender(dynamic genderValue) {
    final genderString = genderValue?.toString().toLowerCase();
    return genderString == 'female' ? Gender.female : Gender.male;
  }

  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

final userDetailsProvider = StateNotifierProvider<UserDetailsNotifier, UserDetailsState>((ref) {
  return UserDetailsNotifier();
});