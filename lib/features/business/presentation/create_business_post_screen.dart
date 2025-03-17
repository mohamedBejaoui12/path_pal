import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pfe1/features/business/data/business_profile_provider.dart';
import 'package:pfe1/features/business/domain/business_post_model.dart';
import 'dart:io';

import '../presentation/business_profile_screen.dart'; // Import the business profile screen

import '../../interests/domain/interest_model.dart';
import '../data/business_post_provider.dart';


class CreateBusinessPostScreen extends ConsumerStatefulWidget {
  final int? businessId; // Optional business ID parameter
  final BusinessPostModel? existingPost; // Optional existing post for editing

  const CreateBusinessPostScreen({Key? key, this.businessId, this.existingPost})
      : super(key: key);

  @override
  _CreateBusinessPostScreenState createState() =>
      _CreateBusinessPostScreenState();
}

class _CreateBusinessPostScreenState
    extends ConsumerState<CreateBusinessPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _imageFile;
  List<InterestModel> _selectedInterests = [];
  bool _isLoading = false;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();

    // If editing an existing post, pre-fill the form
    if (widget.existingPost != null) {
      _titleController.text = widget.existingPost!.title;
      _descriptionController.text = widget.existingPost!.description ?? '';
      _existingImageUrl = widget.existingPost!.imageUrl;

      // Fetch interests to pre-select existing interests
      ref.read(interestProvider.future).then((allInterests) {
        // Convert existing interests to InterestModel
        final existingInterestNames = widget.existingPost!.interests;
        final matchedInterests = allInterests
            .where((interest) => existingInterestNames.contains(interest.name))
            .toList();

        setState(() {
          _selectedInterests = matchedInterests;
        });
      });
    }
  }

  void _fetchInterests() {
    ref.watch(interestProvider.future).then((interests) {
      debugPrint('Fetched ${interests.length} interests');
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching interests: $error')),
      );
    });
  }

  void _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      BusinessPostModel? businessPost;

      // Check if we're creating a new post or updating an existing one
      if (widget.existingPost == null) {
        // Create new post
        businessPost = await ref
            .read(createBusinessPostProvider.notifier)
            .createBusinessPost(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              imageFile: _imageFile,
              interests: _selectedInterests,
            );
      } else {
        // Update existing post
        businessPost = await ref
            .read(createBusinessPostProvider.notifier)
            .updateBusinessPost(
              postId: widget.existingPost!.id!,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              imageFile: _imageFile,
              interests: _selectedInterests,
            );
      }

      if (businessPost != null) {
        // Navigate back to BusinessProfileScreen
        final businessId = widget.businessId ??
            (await ref.read(currentUserBusinessProvider).value)?.id;

        if (businessId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  BusinessProfileScreen(businessId: businessId),
            ),
          );
        } else {
          // Fallback navigation if no business ID is available
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to ${widget.existingPost == null ? 'create' : 'update'} business post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final interestsAsync = ref.watch(interestProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPost == null
            ? 'Create Business Post'
            : 'Update Business Post'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Post Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text(_imageFile == null
                        ? 'Pick Image (Optional)'
                        : 'Change Image'),
                  ),
                  if (_imageFile != null)
                    Image.file(_imageFile!, height: 200, fit: BoxFit.cover)
                  else if (_existingImageUrl != null)
                    Image.network(_existingImageUrl!,
                        height: 200, fit: BoxFit.cover),
                  const SizedBox(height: 16),
                  const Text('Select Interests:'),
                  interestsAsync.when(
                    data: (interests) => Wrap(
                      spacing: 8,
                      children: interests.map((interest) {
                        final isSelected =
                            _selectedInterests.contains(interest);
                        return ChoiceChip(
                          label: Text(interest.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedInterests.add(interest);
                              } else {
                                _selectedInterests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) =>
                        Text('Error loading interests: $error'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitPost,
                    child: Text(widget.existingPost == null
                        ? 'Create Post'
                        : 'Update Post'),
                  ),
                ],
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
}
