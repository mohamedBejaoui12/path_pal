import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/home/domain/post_model.dart';
import 'package:pfe1/features/home/presentation/profile_widget.dart'; // Import the userProfileProvider
import 'package:pfe1/features/home/presentation/post_list_widget.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userEmail; // Required email for the profile to view
  final bool isOtherUserProfile; // Flag to distinguish between current and other user profiles

  const UserProfileScreen({
    Key? key, 
    required this.userEmail, 
    this.isOtherUserProfile = true, // Default to true for other user profiles
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final currentUserEmail = ref.read(authProvider).user?.email;

    // Prevent viewing own profile
    if (widget.userEmail == currentUserEmail) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Text('You cannot view your own profile here'),
        ),
      );
    }

    // Use the existing userProfileProvider to fetch user details and posts
    final userProfileAsyncValue = ref.watch(userProfileProvider(widget.userEmail));

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor,
      ),
      body: userProfileAsyncValue.when(
        data: (data) {
          final userDetails = data['user_details'];
          final userPosts = data['user_posts'] as List<PostModel>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(userDetails),
                
                // User Details Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${userDetails.name} ${userDetails.familyName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (userDetails.description != null)
                        Text(
                          userDetails.description!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Additional User Details
                      _buildUserDetailRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: userDetails.email,
                      ),
                      _buildUserDetailRow(
                        icon: Icons.cake,
                        label: 'Date of Birth',
                        value: DateFormat('dd MMMM yyyy').format(userDetails.dateOfBirth),
                      ),
                      _buildUserDetailRow(
                        icon: Icons.location_city,
                        label: 'City',
                        value: userDetails.cityOfBirth,
                      ),
                    ],
                  ),
                ),

                // User Posts Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Posts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                
                // Display User's Posts
                if (userPosts.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: userPosts.length,
                    itemBuilder: (context, index) {
                      return PostListWidget(
                        post: userPosts[index],
                        isProfileView: true, // Maintain the isProfileView parameter
                      );
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No posts yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading profile: $error'),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic userDetails) {
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
              backgroundImage: userDetails.profileImageUrl != null
                  ? NetworkImage(userDetails.profileImageUrl!)
                  : null,
              child: userDetails.profileImageUrl == null
                  ? const Icon(Icons.person, size: 56, color: Colors.grey)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value.isNotEmpty ? value : 'Not specified',
                style: TextStyle(
                  color: value.isNotEmpty ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}