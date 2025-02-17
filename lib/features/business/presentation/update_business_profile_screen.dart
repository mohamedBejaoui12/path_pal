import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../data/business_profile_provider.dart';
import '../domain/business_model.dart';
import '../../../shared/theme/app_colors.dart';

enum LocationInputMethod {
  manual,
  automatic
}

class UpdateBusinessProfileScreen extends ConsumerStatefulWidget {
  final int businessId;

  const UpdateBusinessProfileScreen({
    Key? key, 
    required this.businessId
  }) : super(key: key);

  @override
  _UpdateBusinessProfileScreenState createState() => _UpdateBusinessProfileScreenState();
}

class _UpdateBusinessProfileScreenState extends ConsumerState<UpdateBusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  
  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = true;
  LocationInputMethod _locationMethod = LocationInputMethod.manual;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _loadBusinessDetails();
  }

  void _loadBusinessDetails() {
    ref.read(businessDetailsProvider(widget.businessId).notifier).fetchBusinessDetails();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Request location permissions
      var status = await Permission.location.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are required')),
        );
        setState(() {
          _isLoadingLocation = false;
          _locationMethod = LocationInputMethod.manual;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update text controllers
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _isLoadingLocation = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      setState(() {
        _isLoadingLocation = false;
        _locationMethod = LocationInputMethod.manual;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress image (0-100)
        maxWidth: 1024,   // Resize image
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        // Convert to File and validate
        final imageFile = File(pickedFile.path);
        
        // Optional: Add image validation if needed
        // bool isValid = ref.read(businessProfileServiceProvider)._validateImage(imageFile);
        // if (!isValid) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(content: Text('Invalid image. Please choose a different file.')),
        //   );
        //   return;
        // }

        setState(() {
          _imageFile = imageFile;
          _imageUrl = null; // Clear network image when local image is selected
        });

        // Optional: Show preview of selected image
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${pickedFile.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        String? uploadedImageUrl;
        if (_imageFile != null) {
          // Upload image
          uploadedImageUrl = await ref.read(businessProfileServiceProvider)
            .uploadBusinessImage(_imageFile!, widget.businessId);

          // Check if upload was successful
          if (uploadedImageUrl == null) {
            // Close loading dialog
            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        final updatedBusiness = await ref.read(businessProfileProvider).updateBusinessProfile(
          businessId: widget.businessId,
          businessName: _nameController.text,
          email: _emailController.text,
          imageUrl: uploadedImageUrl ?? _imageUrl,
          latitude: double.parse(_latitudeController.text),
          longitude: double.parse(_longitudeController.text),
        );

        // Close loading dialog
        Navigator.of(context).pop();

        if (updatedBusiness != null) {
          // Refresh the business details
          await ref.read(businessDetailsProvider(widget.businessId).notifier)
            .refreshBusinessDetails();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile Updated Successfully')),
          );
          Navigator.of(context).pop(true); // Return true to indicate successful update
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile')),
          );
        }
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get real-time updates
    final businessDetailsState = ref.watch(businessDetailsProvider(widget.businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Business Profile'),
      ),
      body: businessDetailsState.when(
        data: (business) {
          // Populate controllers only when data is first loaded
          if (_isLoading && business != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _nameController.text = business.businessName;
                _emailController.text = business.email;
                _imageUrl = business.imageUrl;
                _latitudeController.text = business.latitude.toString();
                _longitudeController.text = business.longitude.toString();
                _isLoading = false;
              });
            });
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Upload
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_imageUrl != null 
                            ? NetworkImage(_imageUrl!) 
                            : null),
                        child: (_imageFile == null && _imageUrl == null)
                          ? const Icon(Icons.camera_alt, size: 50) 
                          : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Business Name TextField
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter business name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email TextField
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        // Add email validation if needed
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location Input Method Selector
                    Row(
                      children: [
                        const Text('Location Input Method:'),
                        const SizedBox(width: 10),
                        DropdownButton<LocationInputMethod>(
                          value: _locationMethod,
                          items: LocationInputMethod.values.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(method == LocationInputMethod.manual 
                                ? 'Manual' 
                                : 'Automatic'),
                            );
                          }).toList(),
                          onChanged: (method) {
                            setState(() {
                              _locationMethod = method!;
                              if (method == LocationInputMethod.automatic) {
                                _getCurrentLocation();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Latitude TextField
                    TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter latitude';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Longitude TextField
                    TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter longitude';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Update Button
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading business details: $error'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }
}