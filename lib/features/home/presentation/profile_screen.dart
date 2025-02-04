import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pfe1/features/authentication/domain/user_details_model.dart';
import 'package:pfe1/shared/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserDetailsModel?> _userDetailsFuture;

  @override
  void initState() {
    super.initState();
    _userDetailsFuture = _fetchUserDetails();
  }

  Future<UserDetailsModel?> _fetchUserDetails() async {
    try {
      // Get the current user's email
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Redirect to login if no user is authenticated
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
        return null;
      }

      // Fetch user details from the 'user' table
      final response = await Supabase.instance.client
          .from('user')
          .select('*')
          .eq('email', user.email as Object)
          .single();

      // Convert the response to UserDetailsModel
      return UserDetailsModel(
        name: response['name'] ?? '',
        familyName: response['family_name'] ?? '',
        email: user.email!,
        dateOfBirth: response['date_of_birth'] != null 
          ? DateTime.parse(response['date_of_birth']) 
          : DateTime.now(),
        phoneNumber: response['phone_number'] ?? '',
        cityOfBirth: response['city_of_birth'] ?? '',
        gender: response['gender'] == 'female' ? Gender.female : Gender.male,
        profileImageUrl: response['profile_image_url'],
        description: response['description'],
      );
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  Widget _buildProfileHeader(UserDetailsModel user) {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.8),
            image: const DecorationImage(
              image: NetworkImage('https://picsum.photos/600/200'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(60),
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey[200],
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? const Icon(Icons.person, size: 56, color: Colors.grey)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content,
        const Divider(height: 40),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'), // Navigate to home screen
        ),
        title: const Text('Profile'),
      ),
      body: FutureBuilder<UserDetailsModel?>(
        future: _userDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Error loading profile',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.name} ${user.familyName}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (user.description != null)
                        Text(
                          user.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      const Divider(height: 40),
                      _buildProfileSection(
                        'About',
                        Column(
                          children: [
                            _buildDetailItem(
                              Icons.cake_outlined,
                              'Date of Birth',
                              DateFormat('MMMM dd, yyyy').format(user.dateOfBirth),
                            ),
                            _buildDetailItem(
                              Icons.location_city_outlined,
                              'City of Birth',
                              user.cityOfBirth,
                            ),
                            _buildDetailItem(
                              Icons.transgender_outlined,
                              'Gender',
                              user.gender.name.toUpperCase(),
                            ),
                          ],
                        ),
                      ),
                      _buildProfileSection(
                        'Contact Info',
                        _buildDetailItem(
                          Icons.phone_outlined,
                          'Phone Number',
                          user.phoneNumber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}