import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pfe1/features/authentication/domain/user_details_model.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/shared/theme/app_colors.dart';

class UserDataUpdateService {
  final Ref ref;
  final BuildContext context;
  final _supabase = Supabase.instance.client;

  UserDataUpdateService({
    required this.ref, 
    required this.context
  });

  Future<void> uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 80,
    );

    if (image == null) return;

    final authState = ref.read(authProvider);
    final userEmail = authState.user?.email;

    if (userEmail == null) {
      _showSnackBar('Unable to upload image: No user email found', isError: true);
      return;
    }

    try {
      final File file = File(image.path);
      final fileExt = file.path.split('.').last;
      final fileName = '$userEmail/profile_image.$fileExt';
      final filePath = fileName;

      // Upload image to Supabase storage
      await _supabase.storage.from('profile_images').upload(
        filePath,
        file,
        fileOptions: FileOptions(upsert: true),
      );

      // Get public URL
      final imageUrl = _supabase.storage.from('profile_images').getPublicUrl(filePath);

      // Update user profile in database
      await _supabase
          .from('user')
          .update({'profile_image_url': imageUrl})
          .eq('email', userEmail);

      _showSnackBar('Profile image updated successfully');
    } catch (e) {
      _showSnackBar('Failed to upload profile image: ${e.toString()}', isError: true);
    }
  }

  Future<void> updateUserProfile(UserDetailsModel userDetails) async {
    try {
      await _supabase
          .from('user')
          .update({
            'name': userDetails.name,
            'family_name': userDetails.familyName,
            'date_of_birth': userDetails.dateOfBirth.toIso8601String(),
            'phone_number': userDetails.phoneNumber,
            'city_of_birth': userDetails.cityOfBirth,
            'gender': userDetails.gender == Gender.male ? 'male' : 'female',
            'description': userDetails.description,
          })
          .eq('email', userDetails.email);

      _showSnackBar('Profile updated successfully');
    } catch (e) {
      _showSnackBar('Failed to update profile: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
          ? Colors.red 
          : AppColors.primaryColor,
      ),
    );
  }

  // Validation methods
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (value != null && value.isNotEmpty) {
      final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Invalid phone number format';
      }
    }
    return null;
  }
}

// Provider for easy access
final userDataUpdateServiceProvider = Provider.family<UserDataUpdateService, BuildContext>((ref, context) {
  return UserDataUpdateService(ref: ref, context: context);
});