import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vocabulary_model.dart';
import '../data/vocabulary_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';

class VocabularyDetailScreen extends ConsumerStatefulWidget {
  final VocabularyModel vocabulary;

  const VocabularyDetailScreen({
    Key? key,
    required this.vocabulary,
  }) : super(key: key);

  @override
  _VocabularyDetailScreenState createState() => _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState
    extends ConsumerState<VocabularyDetailScreen> {
  late TextEditingController _originalWordController;
  late TextEditingController _translationController;
  late TextEditingController _notesController;
  late String _languageFrom;
  late String _languageTo;
  bool _isEditing = false;
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
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _originalWordController =
        TextEditingController(text: widget.vocabulary.originalWord);
    _translationController =
        TextEditingController(text: widget.vocabulary.translation);
    _notesController =
        TextEditingController(text: widget.vocabulary.notes ?? '');
    _languageFrom = widget.vocabulary.languageFrom;
    _languageTo = widget.vocabulary.languageTo;
  }

  @override
  void dispose() {
    _originalWordController.dispose();
    _translationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: _buildAppBar(isDarkMode),
      body: _buildBody(isDarkMode),
    );
  }

  AppBar _buildAppBar(bool isDarkMode) {
    return AppBar(
      title: Text(
        _isEditing ? 'Edit Word' : 'Word Details',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: isDarkMode ? Colors.grey[850] : AppColors.primaryColor,
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => setState(() => _isEditing = true),
          ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: _deleteVocabulary,
        ),
      ],
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [const Color(0xFFF5F7FF), Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLanguageSelectionRow(isDarkMode),
            const SizedBox(height: 24),
            _buildWordFields(isDarkMode),
            const SizedBox(height: 16),
            _buildDateInfo(isDarkMode),
            if (_isEditing) _buildActionButtons(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectionRow(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _isEditing
              ? _buildLanguageDropdown(
                  isDarkMode,
                  'From Language',
                  _languageFrom,
                  (value) => setState(() => _languageFrom = value!),
                )
              : _buildLanguageCard(
                  isDarkMode,
                  'From Language',
                  _languages.firstWhere(
                      (lang) => lang['code'] == _languageFrom)['name']!,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _isEditing
              ? _buildLanguageDropdown(
                  isDarkMode,
                  'To Language',
                  _languageTo,
                  (value) => setState(() => _languageTo = value!),
                )
              : _buildLanguageCard(
                  isDarkMode,
                  'To Language',
                  _languages.firstWhere(
                      (lang) => lang['code'] == _languageTo)['name']!,
                ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown(
    bool isDarkMode,
    String label,
    String value,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
        ),
      ),
      value: value,
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
      onChanged: onChanged,
      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
    );
  }

  Widget _buildLanguageCard(bool isDarkMode, String label, String value) {
    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordFields(bool isDarkMode) {
    return Column(
      children: [
        // Original word
        _isEditing
            ? _buildTextField(
                isDarkMode,
                'Original Word',
                _originalWordController,
              )
            : _buildInfoCard(
                isDarkMode,
                'Original Word',
                widget.vocabulary.originalWord,
                true,
              ),
        const SizedBox(height: 16),

        // Translation
        _isEditing
            ? _buildTextField(
                isDarkMode,
                'Translation',
                _translationController,
              )
            : _buildInfoCard(
                isDarkMode,
                'Translation',
                widget.vocabulary.translation,
                true,
              ),
        const SizedBox(height: 16),

        // Notes
        _isEditing
            ? _buildTextField(
                isDarkMode,
                'Notes (Optional)',
                _notesController,
                maxLines: 3,
              )
            : widget.vocabulary.notes != null &&
                    widget.vocabulary.notes!.isNotEmpty
                ? _buildInfoCard(
                    isDarkMode,
                    'Notes',
                    widget.vocabulary.notes!,
                    false,
                  )
                : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildTextField(
    bool isDarkMode,
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
        ),
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildInfoCard(
    bool isDarkMode,
    String label,
    String value,
    bool isBold,
  ) {
    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 20 : 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(bool isDarkMode) {
    if (_isEditing || widget.vocabulary.createdAt == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Added on',
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(widget.vocabulary.createdAt!),
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelEditing,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : AppColors.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _updateVocabulary,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDarkMode ? Colors.white24 : AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      // Reset controllers to original values
      _originalWordController.text = widget.vocabulary.originalWord;
      _translationController.text = widget.vocabulary.translation;
      _notesController.text = widget.vocabulary.notes ?? '';
      _languageFrom = widget.vocabulary.languageFrom;
      _languageTo = widget.vocabulary.languageTo;
    });
  }

  Future<void> _updateVocabulary() async {
    if (_originalWordController.text.trim().isEmpty ||
        _translationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word and translation cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedVocabulary = widget.vocabulary.copyWith(
        originalWord: _originalWordController.text.trim(),
        translation: _translationController.text.trim(),
        notes: _notesController.text.trim(),
        languageFrom: _languageFrom,
        languageTo: _languageTo,
      );

      final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
      await vocabularyNotifier.updateVocabulary(updatedVocabulary);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word updated successfully!')),
        );
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating word: $e')),
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

  Future<void> _deleteVocabulary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word'),
        content: const Text('Are you sure you want to delete this word?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final vocabularyNotifier = ref.read(vocabularyNotifierProvider.notifier);
      await vocabularyNotifier.deleteVocabulary(widget.vocabulary.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word deleted successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting word: $e')),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
