import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/home/data/post_service.dart';
import 'package:pfe1/features/home/presentation/home_screen.dart';
import 'package:pfe1/features/interests/domain/interest_model.dart';

// Color Constants
const Color _primaryColor = Color(0xFF862C24);
const Color _accentColor = Color(0xFFBE9B7B);
const Color _lightBackground = Colors.white;  // Changed from _lightBackground to pure white
const Color _darkBackground = Color(0xFF1A1A1A);

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;
  List<InterestModel> _allInterests = [];
  List<InterestModel> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _fetchInterests();
  }

  void _fetchInterests() async {
    try {
      setState(() => _isLoading = true);
      final postService = ref.read(postServiceProvider);
      final interests = await postService.fetchInterests();
      setState(() {
        _allInterests = interests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load interests: $e');
    }
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final postService = ref.read(postServiceProvider);
        final uploadedImageUrl = await postService.uploadPostImage(pickedFile.path);
        setState(() {
          _imageUrl = uploadedImageUrl;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Image upload failed: $e');
      }
    }
  }

  void _createPost() async {
    if (_formKey.currentState!.validate() && _selectedInterests.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final authState = ref.read(authProvider);
        final postService = ref.read(postServiceProvider);
        final userEmail = authState.user?.email ?? '';

        await postService.createPost(
          userEmail: userEmail,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim()
              : null,
          imageUrl: _imageUrl,
          interests: _selectedInterests,
        );

        if (mounted) {
          context.pop(true);
          _showSuccessSnackBar('Post created successfully!');
        }
      } catch (e) {
        _showErrorSnackBar('Post creation failed: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _showErrorSnackBar('Please select at least one interest');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final backgroundColor = isDarkMode ? _darkBackground : _lightBackground;
    final textColor = isDarkMode ? Colors.white : _primaryColor;
    final borderColor = isDarkMode ? const Color.fromARGB(255, 184, 184, 184) : _primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Share Tunisian Moments',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: _lightBackground,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? _darkBackground : _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.send, size: 28),
            onPressed: _createPost,
          ),
        ],
      ),
      body: Container(
        color: backgroundColor,
        child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: _primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Picker Section
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: borderColor,
                              width: 2,
                            ),
                            image: _imageUrl != null 
                                ? DecorationImage(
                                    image: NetworkImage(_imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _imageUrl == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, 
                                          color: borderColor, size: 40),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Add Tunisian Inspiration',
                                        style: TextStyle(
                                          color: borderColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontFamily: 'PlayfairDisplay',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Post Title',
                          labelStyle: TextStyle(color: borderColor),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor, 
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                        ),
                        validator: (value) => value!.isEmpty 
                            ? 'Please enter a title' 
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Story (Optional)',
                          labelStyle: TextStyle(color: borderColor),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor, 
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Interests Section
                      Text(
                        'Tunisian Traditions',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Select up to 4 interests',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _allInterests.map((interest) {
                          final isSelected = _selectedInterests.contains(interest);
                          return ChoiceChip(
                            label: Text(
                              '${interest.emoji} ${interest.name}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: _primaryColor,
                            backgroundColor: isDarkMode 
                                ? Colors.grey[800] 
                                : _lightBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? _primaryColor : borderColor,
                                width: 1,
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (_selectedInterests.length < 4) {
                                    _selectedInterests.add(interest);
                                  } else {
                                    _showErrorSnackBar('Maximum 4 interests allowed');
                                  }
                                } else {
                                  _selectedInterests.remove(interest);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),

                      // Post Button
                      ElevatedButton(
                        onPressed: _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: borderColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: _primaryColor.withOpacity(0.3),
                        ),
                        child: const Text(
                          'Share with Community',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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