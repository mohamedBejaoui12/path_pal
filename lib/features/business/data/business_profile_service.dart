import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

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

  Future<BusinessModel?> updateBusinessProfile({
    required int businessId, 
    String? businessName, 
    String? email, 
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _supabase
          .from('business')
          .update({
            if (businessName != null) 'business_name': businessName,
            if (email != null) 'email': email,
            if (imageUrl != null) 'image_url': imageUrl,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          })
          .eq('id', businessId)
          .select()
          .single();
      
      return BusinessModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating business profile: $e');
      return null;
    }
  }

  Future<String?> uploadBusinessImage(File imageFile, int businessId) async {
    try {
      // Validate file
      if (!imageFile.existsSync()) {
        debugPrint('Error: Image file does not exist');
        return null;
      }

      // Check file size
      final fileSize = imageFile.lengthSync();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        debugPrint('Error: Image file too large (>10MB)');
        return null;
      }

      // Generate a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'business_${businessId}_$timestamp${path.extension(imageFile.path)}';
      final filePath = 'buisness_profile_image/$fileName';

      debugPrint('Uploading image: $filePath');
      debugPrint('File size: $fileSize bytes');

      // Upload the file
      final uploadResponse = await _supabase.storage
          .from('buisness_profile_image')
          .upload(
            filePath, 
            imageFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/*',
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('buisness_profile_image')
          .getPublicUrl(filePath);

      debugPrint('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('Detailed error uploading business image: $e');
      debugPrint('Stacktrace: $stackTrace');
      return null;
    }
  }

  bool _validateImage(File imageFile) {
    const maxSizeBytes = 10 * 1024 * 1024; // 10MB
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

    // Check file exists
    if (!imageFile.existsSync()) return false;

    // Check file size
    final fileSize = imageFile.lengthSync();
    if (fileSize > maxSizeBytes) return false;

    // Check file extension
    final extension = path.extension(imageFile.path).toLowerCase();
    return allowedExtensions.contains(extension);
  }
}
