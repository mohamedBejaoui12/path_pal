import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/vocabulary_model.dart';

class VocabularyService {
  final _supabase = Supabase.instance.client;
  final String _tableName = 'vocabulary';

  // Add a new vocabulary word
  Future<VocabularyModel?> addVocabulary({
    required String userEmail,
    required String originalWord,
    required String translation,
    String? notes,
    String languageFrom = 'en',
    String languageTo = 'fr',
  }) async {
    try {
      final response = await _supabase.from(_tableName).insert({
        'user_email': userEmail,
        'original_word': originalWord,
        'translation': translation,
        'notes': notes,
        'language_from': languageFrom,
        'language_to': languageTo,
      }).select().single();

      return VocabularyModel.fromJson(response);
    } catch (e) {
      debugPrint('Error adding vocabulary: $e');
      return null;
    }
  }

  // Update an existing vocabulary word
  Future<VocabularyModel?> updateVocabulary(VocabularyModel vocabulary) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update(vocabulary.toJson())
          .eq('id', vocabulary.id.toString())
          .select()
          .single();

      return VocabularyModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating vocabulary: $e');
      return null;
    }
  }

  // Delete a vocabulary word
  Future<bool> deleteVocabulary(int id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id.toString());
      return true;
    } catch (e) {
      debugPrint('Error deleting vocabulary: $e');
      return false;
    }
  }

  // Get all vocabulary words for a user
  Future<List<VocabularyModel>> getVocabularyByUser(String userEmail) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_email', userEmail)
          .order('created_at', ascending: false);

      return response
          .map<VocabularyModel>((json) => VocabularyModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting vocabulary: $e');
      return [];
    }
  }

  // Search vocabulary by original word
  Future<List<VocabularyModel>> searchByOriginalWord(
      String userEmail, String query) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_email', userEmail)
          .ilike('original_word', '%$query%')
          .order('original_word');

      return response
          .map<VocabularyModel>((json) => VocabularyModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching vocabulary by original word: $e');
      return [];
    }
  }

  // Search vocabulary by translation
  Future<List<VocabularyModel>> searchByTranslation(
      String userEmail, String query) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_email', userEmail)
          .ilike('translation', '%$query%')
          .order('translation');

      return response
          .map<VocabularyModel>((json) => VocabularyModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching vocabulary by translation: $e');
      return [];
    }
  }

  // Search vocabulary by either original word or translation
  Future<List<VocabularyModel>> searchVocabulary(
      String userEmail, String query) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_email', userEmail)
          .or('original_word.ilike.%$query%,translation.ilike.%$query%')
          .order('created_at', ascending: false);

      return response
          .map<VocabularyModel>((json) => VocabularyModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching vocabulary: $e');
      return [];
    }
  }
}