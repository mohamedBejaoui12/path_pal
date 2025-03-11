import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/search/data/search_service.dart';

// Provider for the search service
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

// Provider for search results
final searchResultsProvider = StateNotifierProvider<SearchResultsNotifier, AsyncValue<Map<String, List<Map<String, dynamic>>>>>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return SearchResultsNotifier(searchService);
});

class SearchResultsNotifier extends StateNotifier<AsyncValue<Map<String, List<Map<String, dynamic>>>>> {
  final SearchService _searchService;
  
  SearchResultsNotifier(this._searchService) : super(const AsyncValue.data({
    'users': [],
    'businesses': [],
  }));

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data({
        'users': [],
        'businesses': [],
      });
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final results = await _searchService.searchAll(query);
      state = AsyncValue.data(results);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void clearResults() {
    state = const AsyncValue.data({
      'users': [],
      'businesses': [],
    });
  }
}

// Provider for the current search query
final searchQueryProvider = StateProvider<String>((ref) => '');