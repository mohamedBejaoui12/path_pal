import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

 // lib/features/authentication/presentation/user_details_screen.dart
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
       
       // Navigate to interests selection screen with user ID
       context.push('/select-interests', extra: userId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Complete Your Profile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'First Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                ),
                TextFormField(
                  controller: _familyNameController,
                  decoration: InputDecoration(labelText: 'Family Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter your family name' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(labelText: 'City of Birth'),
                  validator: (value) => value!.isEmpty ? 'Please enter your city of birth' : null,
                ),
                Row(
                  children: [
                    Text('Date of Birth: ${_selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : 'Not selected'}'),
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      child: Text('Select Date'),
                    ),
                  ],
                ),
                DropdownButtonFormField<Gender>(
                  decoration: InputDecoration(labelText: 'Gender'),
                  value: _selectedGender,
                  onChanged: (Gender? newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  items: Gender.values
                      .map<DropdownMenuItem<Gender>>((Gender gender) {
                    return DropdownMenuItem<Gender>(
                      value: gender,
                      child: Text(gender.name.toUpperCase()),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Please select your gender' : null,
                ),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Save Details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}