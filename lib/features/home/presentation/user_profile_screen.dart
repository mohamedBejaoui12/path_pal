import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    
    // Initialize controllers with default empty values
    _nameController = TextEditingController();
    _familyNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    
    // Set default values
    _dateOfBirth = DateTime.now();
    _selectedGender = Gender.male;

    // Use post frame callback to fetch user details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserDetails();
    });
  }

  void _fetchUserDetails() {
    final authState = ref.read(authProvider);
    
    // Test database connection first
    ref.read(userDetailsProvider.notifier).testDatabaseConnection();
    
    // Fetch user details with comprehensive logging
    if (authState.user?.email != null) {
      print('🔍 Initiating user details fetch for: ${authState.user!.email}');
      ref.read(userDetailsProvider.notifier).fetchUserDetails(authState.user!.email);
    } else {
      print('❌ No user email found during initState');
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
    // Watch the user details provider
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
        : userDetailsState.error != null
          ? Center(child: Text('Error: ${userDetailsState.error}'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                    CustomTextFormField(
                      controller: _emailController,
                      labelText: 'Email',
                      prefixIcon: Icons.email,
                     
                    ),
                    const SizedBox(height: 16),
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}