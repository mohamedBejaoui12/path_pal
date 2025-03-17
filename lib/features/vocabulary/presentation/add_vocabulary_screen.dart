import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/vocabulary_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';

class AddVocabularyScreen extends ConsumerStatefulWidget {
  const AddVocabularyScreen({Key? key}) : super(key: key);

  @override
  _AddVocabularyScreenState createState() => _AddVocabularyScreenState();
}

class _AddVocabularyScreenState extends ConsumerState<AddVocabularyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originalWordController = TextEditingController();
  final _translationController = TextEditingController();
  final _notesController = TextEditingController();
  String _languageFrom = 'en';
  String _languageTo = 'fr';
  bool _isLoading = false;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'de', 'name': 'German'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'ar', 'name': 'Arabic'},
  ];

  @override
  void dispose() {
    _originalWordController.dispose();
    _translationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveVocabulary() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
      await vocabularyNotifier.addVocabulary(
        originalWord: _originalWordController.text.trim(),
        translation: _translationController.text.trim(),
        notes: _notesController.text.trim(),
        languageFrom: _languageFrom,
        languageTo: _languageTo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word added successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding word: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Word',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[850] : AppColors.primaryColor,
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language selection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'From Language',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
                          ),
                        ),
                        value: _languageFrom,
                        items: _languages.map((language) {
                          return DropdownMenuItem(
                            value: language['code'],
                            child: Text(
                              language['name']!,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _languageFrom = value!;
                          });
                        },
                        dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'To Language',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
                          ),
                        ),
                        value: _languageTo,
                        items: _languages.map((language) {
                          return DropdownMenuItem(
                            value: language['code'],
                            child: Text(
                              language['name']!,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _languageTo = value!;
                          });
                        },
                        dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Original word
                TextFormField(
                  controller: _originalWordController,
                  decoration: InputDecoration(
                    labelText: 'Original Word',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a word';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Translation
                TextFormField(
                  controller: _translationController,
                  decoration: InputDecoration(
                    labelText: 'Translation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a translation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Notes (optional)
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveVocabulary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white24 : AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: isDarkMode ? Colors.white70 : Colors.white,
                          )
                        : const Text(
                            'Save Word',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}