import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/custom_text_form_field.dart';
import '../../../shared/widgets/loading_overlay.dart';

import '../data/user_details_service.dart';
import '../domain/user_details_model.dart';

class UserDetailsScreen extends StatefulWidget {
  final String email;

  const UserDetailsScreen({Key? key, required this.email}) : super(key: key);

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  DateTime? _selectedDate;
  Gender? _selectedGender;

  final UserDetailsService _userDetailsService = UserDetailsService();

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userDetails = UserDetailsModel(
          name: _nameController.text.trim(),
          familyName: _familyNameController.text.trim(),
          dateOfBirth: _selectedDate!,
          phoneNumber: _phoneController.text.trim(),
          cityOfBirth: _cityController.text.trim(),
          gender: _selectedGender!,
          email: widget.email,
        );

        // Save user details and get the inserted user's ID
        final userId = await _userDetailsService.saveUserDetails(userDetails);

        // Navigate to interests selection screen with user ID using context.go()
        context.go('/select-interests', extra: userId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving user details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildHeader(Color primaryColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      child: Column(
        children: [
          Text(
            'Ahlan wa Sahlan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'PlayfairDisplay',
              shadows: [
                const Shadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete Your Profile',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 2,
            width: 100,
            color: accentColor,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: false, // Add a loading state if needed
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryColor, AppColors.backgroundColor],
              stops: const [0.3, 0.3],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(AppColors.primaryColor, AppColors.secondaryColor),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextFormField(
                            controller: _nameController,
                            labelText: 'First Name',
                            prefixIcon: Icons.person_outline,
                            validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _familyNameController,
                            labelText: 'Family Name',
                            prefixIcon: Icons.family_restroom_outlined,
                            validator: (value) => value!.isEmpty ? 'Please enter your family name' : null,
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _phoneController,
                            labelText: 'Phone Number',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
                          ),
                          const SizedBox(height: 20),
                          CustomTextFormField(
                            controller: _cityController,
                            labelText: 'City of Birth',
                            prefixIcon: Icons.location_city_outlined,
                            validator: (value) => value!.isEmpty ? 'Please enter your city of birth' : null,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Date of Birth: ${_selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : 'Not selected'}',
                                  style: TextStyle(color: AppColors.primaryColor),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _selectDate(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                ),
                                child: const Text('Select Date'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<Gender>(
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              labelStyle: TextStyle(color: AppColors.primaryColor),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                              ),
                            ),
                            value: _selectedGender,
                            dropdownColor: Colors.white,
                            iconEnabledColor: AppColors.primaryColor,
                            onChanged: (Gender? newValue) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            },
                            items: Gender.values
                                .map<DropdownMenuItem<Gender>>((Gender gender) {
                              return DropdownMenuItem<Gender>(
                                value: gender,
                                child: Text(
                                  gender.name.toUpperCase(),
                                  style: TextStyle(color: AppColors.primaryColor),
                                ),
                              );
                            }).toList(),
                            validator: (value) => value == null ? 'Please select your gender' : null,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                                shadowColor: AppColors.primaryColor.withOpacity(0.3),
                              ),
                              child: const Text(
                                'Save Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}