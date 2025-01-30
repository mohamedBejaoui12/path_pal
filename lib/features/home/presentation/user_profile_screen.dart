import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:pfe1/features/authentication/data/user_details_provider.dart';
import 'package:pfe1/features/authentication/domain/user_details_model.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:pfe1/shared/widgets/custom_text_form_field.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _familyNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late DateTime _dateOfBirth;
  late Gender _selectedGender;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController();
    _familyNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    
    // Set default values
    _dateOfBirth = DateTime.now();
    _selectedGender = Gender.male;

    // Fetch user details after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserDetails();
    });
  }

  void _fetchUserDetails() {
    final authState = ref.read(authProvider);
    
    if (authState.user?.email != null) {
      ref.read(userDetailsProvider.notifier).fetchUserDetails(authState.user!.email);
    }
  }

  void _uploadProfileImage() async {
    final userDetailsNotifier = ref.read(userDetailsProvider.notifier);
    final authState = ref.read(authProvider);

    if (authState.user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to upload image: No user email found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final imageUrl = await userDetailsNotifier.uploadProfileImage(authState.user!.email!);
      
      if (imageUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile image updated successfully'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        
        // Refresh user details to show new image
        await userDetailsNotifier.fetchUserDetails(authState.user!.email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload profile image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authState = ref.read(authProvider);
      
      if (authState.user?.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save profile: No user email found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userDetails = UserDetailsModel(
        name: _nameController.text,
        familyName: _familyNameController.text,
        dateOfBirth: _dateOfBirth,
        phoneNumber: _phoneController.text,
        cityOfBirth: _cityController.text,
        gender: _selectedGender,
        email: authState.user!.email!,
      );

      try {
        await ref.read(userDetailsProvider.notifier).updateUserDetails(userDetails);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _familyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDetailsState = ref.watch(userDetailsProvider);
    final authState = ref.watch(authProvider);

    // Update controllers when user details are loaded
    if (userDetailsState.userDetails != null) {
      final userDetails = userDetailsState.userDetails!;
      _nameController.text = userDetails.name;
      _familyNameController.text = userDetails.familyName;
      _emailController.text = userDetails.email;
      _phoneController.text = userDetails.phoneNumber;
      _cityController.text = userDetails.cityOfBirth;
      _dateOfBirth = userDetails.dateOfBirth;
      _selectedGender = userDetails.gender;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: userDetailsState.isLoading 
        ? Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image Section
                  GestureDetector(
                    onTap: _uploadProfileImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                          child: userDetailsState.userDetails?.profileImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: userDetailsState.userDetails!.profileImageUrl!,
                                imageBuilder: (context, imageProvider) => Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) => 
                                    CircularProgressIndicator(color: AppColors.primaryColor),
                                errorWidget: (context, url, error) => 
                                    Icon(Icons.person, size: 100, color: AppColors.primaryColor),
                              )
                            : Icon(
                                Icons.person, 
                                size: 100, 
                                color: AppColors.primaryColor
                              ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.edit, color: Colors.white, size: 20),
                              onPressed: _uploadProfileImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // First Name
                  CustomTextFormField(
                    controller: _nameController,
                    labelText: 'First Name',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Family Name
                  CustomTextFormField(
                    controller: _familyNameController,
                    labelText: 'Family Name',
                    prefixIcon: Icons.family_restroom,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your family name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Email (Read-only)
                  CustomTextFormField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone Number
                  CustomTextFormField(
                    controller: _phoneController,
                    labelText: 'Phone Number',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$');
                        if (!phoneRegex.hasMatch(value)) {
                          return 'Please enter a valid phone number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // City of Birth
                  CustomTextFormField(
                    controller: _cityController,
                    labelText: 'City of Birth',
                    prefixIcon: Icons.location_city,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your city of birth';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Date of Birth
                  Row(
                    children: [
                      const Text('Date of Birth: ', style: TextStyle(fontSize: 16)),
                      TextButton(
                        onPressed: _selectDate,
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_dateOfBirth),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Gender Selection
                  Row(
                    children: [
                      const Text('Gender: ', style: TextStyle(fontSize: 16)),
                      DropdownButton<Gender>(
                        value: _selectedGender,
                        onChanged: (Gender? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          }
                        },
                        items: Gender.values
                            .map<DropdownMenuItem<Gender>>((Gender gender) {
                          return DropdownMenuItem<Gender>(
                            value: gender,
                            child: Text(gender.name.capitalize()),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Save Profile Button
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Save Profile'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// Extension for capitalizing first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}