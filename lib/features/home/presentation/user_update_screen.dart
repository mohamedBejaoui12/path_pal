import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:pfe1/features/authentication/domain/user_details_model.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/authentication/data/user_details_provider.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';

class UserUpdateScreen extends ConsumerStatefulWidget {
  const UserUpdateScreen({Key? key}) : super(key: key);

  @override
  _UserUpdateScreenState createState() => _UserUpdateScreenState();
}

class _UserUpdateScreenState extends ConsumerState<UserUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _familyNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _descriptionController;
  
  late DateTime _dateOfBirth;
  late Gender _selectedGender;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setDefaultValues();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndPopulateUserDetails();
    });
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _familyNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  void _setDefaultValues() {
    _dateOfBirth = DateTime.now();
    _selectedGender = Gender.male;
  }

  void _fetchAndPopulateUserDetails() {
    final authState = ref.read(authProvider);
    
    if (authState.user?.email != null) {
      ref.read(userDetailsProvider.notifier)
        .fetchUserDetails(authState.user!.email)
        .then((_) {
          final userDetailsState = ref.read(userDetailsProvider);
          if (userDetailsState.userDetails != null) {
            _updateControllersWithUserDetails(userDetailsState.userDetails!);
          }
        });
    }
  }

  void _updateControllersWithUserDetails(UserDetailsModel userDetails) {
    setState(() {
      _nameController.text = userDetails.name;
      _familyNameController.text = userDetails.familyName;
      _emailController.text = userDetails.email;
      _phoneController.text = userDetails.phoneNumber;
      _cityController.text = userDetails.cityOfBirth;
      _descriptionController.text = userDetails.description ?? '';
      _dateOfBirth = userDetails.dateOfBirth;
      _selectedGender = userDetails.gender;
    });
  }

  void _uploadProfileImage() async {
    final userDetailsNotifier = ref.read(userDetailsProvider.notifier);
    final authState = ref.read(authProvider);

    if (authState.user?.email == null) {
      _showSnackBar('Unable to upload image: No user email found', isError: true);
      return;
    }

    try {
      final imageUrl = await userDetailsNotifier.uploadProfileImage(authState.user!.email!);
      
      if (imageUrl != null) {
        _showSnackBar('Profile image updated successfully');
        
        // Refresh user details to show new image
        await userDetailsNotifier.fetchUserDetails(authState.user!.email);
      } else {
        _showSnackBar('Failed to upload image', isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to upload profile image: $e', isError: true);
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final authState = ref.read(authProvider);
      
      if (authState.user?.email == null) {
        _showSnackBar('Unable to save profile: No user email found', isError: true);
        return;
      }

      final userDetails = UserDetailsModel(
        name: _nameController.text.trim(),
        familyName: _familyNameController.text.trim(),
        email: authState.user!.email!,
        dateOfBirth: _dateOfBirth,
        phoneNumber: _phoneController.text.trim(),
        cityOfBirth: _cityController.text.trim(),
        gender: _selectedGender,
        description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      );

      ref.read(userDetailsProvider.notifier)
        .updateUserDetails(userDetails)
        .then((_) {
          _showSnackBar('Profile updated successfully');
          context.pop(); // Return to previous screen
        })
        .catchError((error) {
          _showSnackBar('Failed to update profile: $error', isError: true);
        });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primaryColor,
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

  @override
  void dispose() {
    _nameController.dispose();
    _familyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final userDetailsState = ref.watch(userDetailsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildProfileHeader(userDetailsState.userDetails, isDarkMode),
          SliverToBoxAdapter(
            child: _buildProfileContent(userDetailsState, isDarkMode),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildProfileHeader(UserDetailsModel? userDetails, bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              'https://picsum.photos/600/200',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),
            
            // Profile Image with Upload Button
            Positioned(
              bottom: 16,
              left: 20,
              child: GestureDetector(
                onTap: _uploadProfileImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.grey[200],
                    child: userDetails?.profileImageUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: userDetails!.profileImageUrl!,
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => 
                                const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => 
                                const Icon(Icons.person, size: 56),
                            ),
                          )
                        : const Icon(Icons.person, size: 56, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(UserDetailsState userDetailsState, bool isDarkMode) {
    return userDetailsState.isLoading
      ? const Center(child: CircularProgressIndicator())
      : _buildProfileForm(isDarkMode);
  }

  Widget _buildProfileForm(bool isDarkMode) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name Fields
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _nameController,
                    label: 'First Name',
                    icon: Icons.person_outline,
                    validator: (value) => 
                      value == null || value.trim().isEmpty 
                        ? 'First name is required' 
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextFormField(
                    controller: _familyNameController,
                    label: 'Last Name',
                    icon: Icons.family_restroom_outlined,
                    validator: (value) => 
                      value == null || value.trim().isEmpty 
                        ? 'Last name is required' 
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email Field (Read-only)
            _buildTextFormField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              enabled: false,
            ),
            const SizedBox(height: 16),

            // Phone and City
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_iphone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhoneNumber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextFormField(
                    controller: _cityController,
                    label: 'City of Birth',
                    icon: Icons.location_city_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date of Birth and Gender
            Row(
              children: [
                Expanded(child: _buildDatePicker()),
                const SizedBox(width: 16),
                Expanded(child: _buildGenderPicker()),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            _buildDescriptionField(),
            const SizedBox(height: 24),

            // Save Button
            _buildSaveButton(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = ref.watch(themeProvider);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDarkMode ? Colors.white : AppColors.primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: Icon(Icons.calendar_today, color: AppColors.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          DateFormat('yyyy-MM-dd').format(_dateOfBirth),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildGenderPicker() {
    return DropdownButtonFormField<Gender>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: Gender.values.map((Gender gender) {
        return DropdownMenuItem<Gender>(
          value: gender,
          child: Text(gender == Gender.male ? 'Male' : 'Female'),
        );
      }).toList(),
      onChanged: (Gender? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedGender = newValue;
          });
        }
      },
    );
  }

  Widget _buildDescriptionField() {
    final isDarkMode = ref.watch(themeProvider);
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'About You (Optional)',
        hintText: 'Share something about yourself...',
        prefixIcon: Icon(Icons.description_outlined, color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDarkMode) {
    return ElevatedButton(
      onPressed: _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? Colors.grey[700] : AppColors.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Save Profile',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (value != null && value.isNotEmpty) {
      final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Invalid phone number format';
      }
    }
    return null;
  }
}