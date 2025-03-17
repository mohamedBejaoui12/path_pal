import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/vocabulary/presentation/add_vocabulary_screen.dart';
import 'package:pfe1/features/vocabulary/presentation/vocabulary_detail_screen.dart';
import '../data/vocabulary_provider.dart';
import '../domain/vocabulary_model.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';

class VocabularyListScreen extends ConsumerStatefulWidget {
  const VocabularyListScreen({Key? key}) : super(key: key);

  @override
  _VocabularyListScreenState createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends ConsumerState<VocabularyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    // Reset to show all vocabulary
    ref.invalidate(userVocabularyProvider);
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final vocabularyAsync = _searchQuery.isEmpty
        ? ref.watch(userVocabularyProvider)
        : ref.watch(vocabularySearchProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search words or translations...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _performSearch,
              )
            : const Text(
                'My Vocabulary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        backgroundColor: isDarkMode ? Colors.grey[850] : AppColors.primaryColor,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _stopSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _startSearch,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
                ? [Colors.grey[900]!, Colors.grey[850]!]
                : [const Color(0xFFF5F7FF), Colors.white],
          ),
        ),
        child: vocabularyAsync.when(
          data: (vocabularyList) {
            if (vocabularyList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book,
                      size: 80,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No vocabulary words yet'
                          : 'No results found for "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_searchQuery.isEmpty)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Word'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.white24 : AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => _navigateToAddVocabulary(context),
                      ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userVocabularyProvider);
              },
              color: isDarkMode ? Colors.white : AppColors.primaryColor,
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
              child: ListView.builder(
                itemCount: vocabularyList.length,
                itemBuilder: (context, index) {
                  final vocabulary = vocabularyList[index];
                  return _buildVocabularyCard(context, vocabulary, isDarkMode);
                },
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(
              color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
            ),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error: $error',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddVocabulary(context),
        backgroundColor: isDarkMode ? Colors.white24 : AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildVocabularyCard(BuildContext context, VocabularyModel vocabulary, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToVocabularyDetail(context, vocabulary),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      vocabulary.originalWord,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? Colors.white10 : AppColors.primaryColor.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vocabulary.languageFrom.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: isDarkMode ? Colors.white24 : Colors.grey[300]),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      vocabulary.translation,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? Colors.white10 : AppColors.primaryColor.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vocabulary.languageTo.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (vocabulary.notes != null && vocabulary.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    vocabulary.notes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(vocabulary.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToAddVocabulary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddVocabularyScreen(),
      ),
    ).then((_) {
      // Refresh the list when returning from add screen
      ref.invalidate(userVocabularyProvider);
    });
  }

  void _navigateToVocabularyDetail(
      BuildContext context, VocabularyModel vocabulary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VocabularyDetailScreen(vocabulary: vocabulary),
      ),
    ).then((_) {
      // Refresh the list when returning from detail screen
      ref.invalidate(userVocabularyProvider);
    });
  }
}