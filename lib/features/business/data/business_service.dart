import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../domain/business_model.dart';

class BusinessService {
  final _supabase = Supabase.instance.client;

  Future<BusinessModel> createBusiness(BusinessModel business) async {
    try {
      // Remove the 'id' from toJson since it's auto-generated
      final businessMap = business.toJson();
      businessMap.remove('id'); // Remove ID for auto-increment
      businessMap.remove('created_at'); // Remove created_at for auto-generation

      final response = await _supabase
          .from('business')
          .insert(businessMap)
          .select()
          .single();
      
      // Return the full business model with the newly generated ID
      return BusinessModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating business: $e');
      rethrow;
    }
  }

  Future<String> uploadBusinessProfileImage(Uint8List imageBytes, String fileName) async {
    try {
      // Validate image size
      if (imageBytes.length > 5 * 1024 * 1024) {
        throw Exception('Image size exceeds 5MB limit');
      }

      // Ensure user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to upload image');
      }

      // Generate a unique filename
      final uniqueFileName = 'business_${user.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(fileName)}';

      // Upload to public bucket
      final uploadResponse = await _supabase
          .storage
          .from('buisness_profile_image')
          .uploadBinary(
            uniqueFileName, 
            imageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getContentType(fileName),
            )
          );

      // Get public URL
      final publicUrl = _supabase
          .storage
          .from('buisness_profile_image')
          .getPublicUrl(uniqueFileName);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading business profile image: $e');
      rethrow;
    }
  }

  // Helper method to get content type
  String _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
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