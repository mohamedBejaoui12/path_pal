import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pfe1/features/authentication/data/user_details_provider.dart';
import 'package:pfe1/features/authentication/domain/user_details_model.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/home/presentation/home_screen.dart';
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
  late TextEditingController _descriptionController;
  late DateTime _dateOfBirth;
  late Gender _selectedGender;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setDefaultValues();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserDetails());
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
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null, // Optional description
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
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final userDetailsState = ref.watch(userDetailsProvider);
    final authState = ref.watch(authProvider);

    if (userDetailsState.userDetails != null) {
      _updateControllers(userDetailsState.userDetails!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor,
        elevation: 1,
      ),
      body: userDetailsState.isLoading
          ? _buildLoadingIndicator()
          : _buildProfileContent(),
    );
  }

  Widget _buildLoadingIndicator() {
    final isDarkMode = ref.watch(themeProvider);
    return Center(
      child: CircularProgressIndicator(
        color: isDarkMode ? AppColors.secondaryColor : AppColors.primaryColor,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProfileImageSection(),
            const SizedBox(height: 32),
            _buildFormSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    final userDetails = ref.watch(userDetailsProvider).userDetails;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _uploadProfileImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 72,
                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                child: userDetails?.profileImageUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: userDetails!.profileImageUrl!,
                          width: 144,
                          height: 144,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              CircularProgressIndicator(
                            color: AppColors.primaryColor,
                            strokeWidth: 2,
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.person_outline_rounded,
                                  size: 64,
                                  color: AppColors.primaryColor.withOpacity(0.6)),
                        ),
                      )
                    : Icon(Icons.person_outline_rounded,
                        size: 64, color: AppColors.primaryColor),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 24,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        _buildNameFields(),
        const SizedBox(height: 20),
        _buildEmailField(),
        const SizedBox(height: 20),
        _buildPhoneAndCityFields(),
        const SizedBox(height: 20),
        _buildDateAndGenderFields(),
        const SizedBox(height: 20),
        _buildDescriptionField(),
      ],
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(child: _buildFormField(_nameController, 'First Name', Icons.person_outline_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _buildFormField(_familyNameController, 'Last Name', Icons.family_restroom_outlined)),
      ],
    );
  }

  Widget _buildEmailField() {
    return _buildFormField(
      _emailController,
      'Email Address',
      Icons.email_outlined,
      enabled: false,
    );
  }

  Widget _buildPhoneAndCityFields() {
    return Row(
      children: [
        Expanded(child: _buildFormField(_phoneController, 'Phone Number', Icons.phone_iphone_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _buildFormField(_cityController, 'City of Birth', Icons.location_city_outlined)),
      ],
    );
  }

  Widget _buildDateAndGenderFields() {
    return Row(
      children: [
        Expanded(child: _buildDatePicker()),
        const SizedBox(width: 16),
        Expanded(child: _buildGenderPicker()),
      ],
    );
  }

  Widget _buildFormField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool enabled = true,
  }) {
    final isDarkMode = ref.watch(themeProvider);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: _getValidator(label),
      style: TextStyle(
        color: isDarkMode ? Colors.white : AppColors.primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : AppColors.primaryColor.withOpacity(0.7),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, 
          size: 22, 
          color: isDarkMode ? Colors.white70 : AppColors.primaryColor.withOpacity(0.7)
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white24 : AppColors.primaryColor.withOpacity(0.15),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white : AppColors.primaryColor,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      ),
    );
  }

  String? Function(String?)? _getValidator(String label) {
    return (value) {
      if (value == null || value.isEmpty) {
        return '${label.split(' ').first} is required';
      }
      if (label == 'Phone Number' && value.isNotEmpty) {
        final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$');
        if (!phoneRegex.hasMatch(value)) return 'Invalid phone format';
      }
      return null;
    };
  }

  Widget _buildDatePicker() {
    final isDarkMode = ref.watch(themeProvider);
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : AppColors.primaryColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode ? Colors.white24 : AppColors.primaryColor.withOpacity(0.15),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 22, 
                color: isDarkMode ? Colors.white70 : AppColors.primaryColor.withOpacity(0.7)),
            const SizedBox(width: 14),
            Text(
              DateFormat('MMM dd, yyyy').format(_dateOfBirth),
              style: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderPicker() {
    final isDarkMode = ref.watch(themeProvider);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : AppColors.primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : AppColors.primaryColor.withOpacity(0.15),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Gender>(
          value: _selectedGender,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded,
              size: 28, 
              color: isDarkMode ? Colors.white : AppColors.primaryColor),
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: Gender.values.map((gender) {
            return DropdownMenuItem<Gender>(
              value: gender,
              child: Text(gender.name.capitalize()),
            );
          }).toList(),
          onChanged: (Gender? newValue) {
            if (newValue != null) setState(() => _selectedGender = newValue);
          },
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    final isDarkMode = ref.watch(themeProvider);
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      style: TextStyle(
        color: isDarkMode ? Colors.white : AppColors.primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'About You (Optional)',
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : AppColors.primaryColor.withOpacity(0.7),
          fontSize: 13,
        ),
        hintText: 'Share something interesting about yourself...',
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.white38 : AppColors.primaryColor.withOpacity(0.4),
          fontSize: 13,
        ),
        prefixIcon: Icon(Icons.description_outlined,
            size: 22, 
            color: isDarkMode ? Colors.white70 : AppColors.primaryColor.withOpacity(0.7)),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white24 : AppColors.primaryColor.withOpacity(0.15),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white : AppColors.primaryColor,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(18),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isDarkMode = ref.watch(themeProvider);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.grey[700] : AppColors.primaryColor,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'SAVE PROFILE',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  void _updateControllers(UserDetailsModel userDetails) {
    _nameController.text = userDetails.name;
    _familyNameController.text = userDetails.familyName;
    _emailController.text = userDetails.email;
    _phoneController.text = userDetails.phoneNumber;
    _cityController.text = userDetails.cityOfBirth;
    _descriptionController.text = userDetails.description ?? '';
    _dateOfBirth = userDetails.dateOfBirth;
    _selectedGender = userDetails.gender;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}