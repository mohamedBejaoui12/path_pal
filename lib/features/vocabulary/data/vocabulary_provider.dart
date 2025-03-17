import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vocabulary_model.dart';
import 'vocabulary_service.dart';
import '../../authentication/providers/auth_provider.dart';

// Provider for the vocabulary service
final vocabularyServiceProvider = Provider<VocabularyService>((ref) {
  return VocabularyService();
});

// Provider for all vocabulary words of the current user
final userVocabularyProvider = FutureProvider<List<VocabularyModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final vocabularyService = ref.read(vocabularyServiceProvider);
  
  if (authState.user?.email == null) {
    return [];
  }
  
  return vocabularyService.getVocabularyByUser(authState.user!.email!);
});

// Provider for searching vocabulary
final vocabularySearchProvider = FutureProvider.family<List<VocabularyModel>, String>((ref, query) async {
  final authState = ref.watch(authProvider);
  final vocabularyService = ref.read(vocabularyServiceProvider);
  
  if (authState.user?.email == null || query.isEmpty) {
    return ref.read(userVocabularyProvider).value ?? [];
  }
  
  return vocabularyService.searchVocabulary(authState.user!.email!, query);
});

// State notifier for managing vocabulary operations
class VocabularyNotifier extends StateNotifier<AsyncValue<List<VocabularyModel>>> {
  final VocabularyService _service;
  final String _userEmail;
  
  VocabularyNotifier(this._service, this._userEmail) : super(const AsyncValue.loading()) {
    loadVocabulary();
  }
  
  Future<void> loadVocabulary() async {
    state = const AsyncValue.loading();
    try {
      final vocabulary = await _service.getVocabularyByUser(_userEmail);
      state = AsyncValue.data(vocabulary);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> addVocabulary({
    required String originalWord,
    required String translation,
    String? notes,
    String languageFrom = 'en',
    String languageTo = 'fr',
  }) async {
    try {
      final newVocabulary = await _service.addVocabulary(
        userEmail: _userEmail,
        originalWord: originalWord,
        translation: translation,
        notes: notes,
        languageFrom: languageFrom,
        languageTo: languageTo,
      );
      
      if (newVocabulary != null) {
        state.whenData((vocabulary) {
          state = AsyncValue.data([newVocabulary, ...vocabulary]);
        });
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> updateVocabulary(VocabularyModel vocabulary) async {
    try {
      final updatedVocabulary = await _service.updateVocabulary(vocabulary);
      
      if (updatedVocabulary != null) {
        state.whenData((vocabularyList) {
          state = AsyncValue.data(
            vocabularyList.map((item) => 
              item.id == updatedVocabulary.id ? updatedVocabulary : item
            ).toList(),
          );
        });
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> deleteVocabulary(int id) async {
    try {
      final success = await _service.deleteVocabulary(id);
      
      if (success) {
        state.whenData((vocabularyList) {
          state = AsyncValue.data(
            vocabularyList.where((item) => item.id != id).toList(),
          );
        });
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  Future<void> searchVocabulary(String query) async {
    state = const AsyncValue.loading();
    try {
      final results = await _service.searchVocabulary(_userEmail, query);
      state = AsyncValue.data(results);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Provider for the vocabulary notifier
final vocabularyNotifierProvider = StateNotifierProvider<VocabularyNotifier, AsyncValue<List<VocabularyModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final service = ref.read(vocabularyServiceProvider);
  
  if (authState.user?.email == null) {
    throw Exception('User must be logged in to access vocabulary');
  }
  
  return VocabularyNotifier(service, authState.user!.email!);
});