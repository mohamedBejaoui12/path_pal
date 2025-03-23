import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../data/business_provider.dart';
import '../../../shared/theme/app_colors.dart';

enum LocationInputMethod { manual, automatic }

class AddBusinessScreen extends ConsumerStatefulWidget {
  const AddBusinessScreen({Key? key}) : super(key: key);

  @override
  _AddBusinessScreenState createState() => _AddBusinessScreenState();
}

class _AddBusinessScreenState extends ConsumerState<AddBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _customCategoryController =
      TextEditingController(); // Added for custom category

  File? _imageFile;
  LocationInputMethod _locationMethod = LocationInputMethod.manual;
  bool _isLoadingLocation = false;
  bool _isCustomCategory = false; // Flag for custom category
  String? _selectedCategory; // For dropdown selection

  // Predefined categories
  final List<String> _predefinedCategories = [
    'Restaurant',
    'Cafe',
    'Cafe-Restaurant',
    'Bar',
    'Clothing Shop',
    'Grocery Store',
    'Bakery',
    'Electronics',
    'Pharmacy',
    'Other'
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _customCategoryController.dispose(); // Dispose custom category controller
    super.dispose();
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
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a business image'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    // Determine the category to use
    String? categoryToUse;
    if (_isCustomCategory && _customCategoryController.text.isNotEmpty) {
      categoryToUse = _customCategoryController.text.trim();
    } else {
      categoryToUse = _selectedCategory;
    }

    try {
      final business = await ref
          .read(createBusinessProvider.notifier)
          .createBusinessWithImage(
            businessName: _businessNameController.text.trim(),
            email: _emailController.text.trim(),
            latitude: double.parse(_latitudeController.text.trim()),
            longitude: double.parse(_longitudeController.text.trim()),
            imageFile: _imageFile!,
            category: categoryToUse, // Pass the category
          );

      if (business != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${business.businessName} created!'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Business'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors
            .primaryColor, // Set AppBar background to primary color (reddish)
        foregroundColor: Colors.white, // Set AppBar text and icons to white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker (existing implementation)
              _buildBusinessImagePicker(),
              const SizedBox(height: 20),

              // Business Name and Email Fields (existing implementation)
              _buildTextField(
                controller: _businessNameController,
                label: 'Business Name',
                icon: Icons.business,
                validator: (value) =>
                    value!.isEmpty ? 'Enter business name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Business Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),

              // Category Dropdown - New Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business Category:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    hint: const Text('Select a category'),
                    value: _selectedCategory,
                    items: _predefinedCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _isCustomCategory = value == 'Other';
                      });
                    },
                    validator: (value) {
                      if (value == null && !_isCustomCategory) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),

                  // Custom Category Field (shown only when "Other" is selected)
                  if (_isCustomCategory) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _customCategoryController,
                      label: 'Custom Category',
                      icon: Icons.edit,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter custom category' : null,
                    ),
                  ],
                ],
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

              // Latitude and Longitude Fields
              _locationMethod == LocationInputMethod.manual
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _latitudeController,
                            label: 'Latitude',
                            icon: Icons.location_on,
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? 'Enter latitude' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _longitudeController,
                            label: 'Longitude',
                            icon: Icons.location_on,
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value!.isEmpty ? 'Enter longitude' : null,
                          ),
                        ),
                      ],
                    )
                  : _isLoadingLocation
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _latitudeController,
                                decoration: const InputDecoration(
                                  labelText: 'Latitude',
                                  border: OutlineInputBorder(),
                                ),
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _longitudeController,
                                decoration: const InputDecoration(
                                  labelText: 'Longitude',
                                  border: OutlineInputBorder(),
                                ),
                                readOnly: true,
                              ),
                            ),
                          ],
                        ),
              const SizedBox(height: 24),

              // Submit Button (existing implementation)
              ElevatedButton(
                onPressed: _submitBusiness,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors
                      .primaryColor, // Set button background to primary color (reddish)
                  foregroundColor: Colors.white, // Set button text to white
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Create Business',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
            image: _imageFile != null
                ? DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _imageFile == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: Colors.grey[600],
                      size: 50,
                    ),
                    Text(
                      'Add Business Image',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }
}
