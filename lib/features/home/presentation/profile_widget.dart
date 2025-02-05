import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pfe1/features/authentication/domain/user_details_model.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/home/domain/post_model.dart';
import 'package:pfe1/features/home/data/post_provider.dart';
import 'package:pfe1/features/home/presentation/post_list_widget.dart';

String _generateDefaultProfileImage(String name) {
  return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff&size=200';
}

final userProfileProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userEmail) async {
  final supabase = Supabase.instance.client;

  // Fetch user details
  final userResponse = await supabase
      .from('user')
      .select('*')
      .eq('email', userEmail)
      .single();

  // Fetch user posts with full user details
  final postsResponse = await supabase
      .from('user_post')
      .select('''
        *,
        user:user_email(name, family_name, profile_image_url)
      ''')
      .eq('user_email', userEmail)
      .order('created_at', ascending: false);

  // Convert posts to PostModel
  final posts = (postsResponse as List).map<PostModel>((json) {
    // Safely extract user data
    final userData = (json['user'] is List && json['user'].isNotEmpty) 
      ? json['user'][0] 
      : {};

    // Extract name safely
    final name = userData['name'] ?? userResponse['name'] ?? '';
    final familyName = userData['family_name'] ?? userResponse['family_name'] ?? '';
    final fullName = '$name $familyName'.trim();

    // Get profile image URL with fallback
    final profileImageUrl = userData['profile_image_url'] ?? 
      userResponse['profile_image_url'] ?? 
      _generateDefaultProfileImage(fullName);

    // Fetch post likes
    final postLikes = json['post_likes'] as List? ?? [];
    final isLikedByCurrentUser = postLikes.any(
      (like) => like['user_email'] == userEmail
    );

    return PostModel(
      id: json['id'],
      userEmail: json['user_email'] ?? userEmail,
      userName: fullName.isNotEmpty ? fullName : 'Anonymous',
      userProfileImage: profileImageUrl,
      title: json['title'] ?? 'Untitled Post',
      description: json['description'],
      imageUrl: json['image_link'] ?? json['image_url'],
      interests: List<String>.from(json['interests'] ?? []),
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      likesCount: postLikes.length,
      commentsCount: json['comments_count'] ?? 0,
      isLikedByCurrentUser: isLikedByCurrentUser,
    );
  }).toList();

  return {
    'user_details': UserDetailsModel(
      name: userResponse['name'] ?? '',
      familyName: userResponse['family_name'] ?? '',
      email: userEmail,
      dateOfBirth: userResponse['date_of_birth'] != null 
        ? DateTime.parse(userResponse['date_of_birth']) 
        : DateTime.now(),
      phoneNumber: userResponse['phone_number'] ?? '',
      cityOfBirth: userResponse['city_of_birth'] ?? '',
      gender: userResponse['gender'] == 'female' ? Gender.female : Gender.male,
      profileImageUrl: userResponse['profile_image_url'],
      description: userResponse['description'],
    ),
    'user_posts': posts,
  };
});

class ProfileWidget extends ConsumerStatefulWidget {
  const ProfileWidget({Key? key}) : super(key: key);

  @override
  _ProfileWidgetState createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends ConsumerState<ProfileWidget> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.read(authProvider);
    final userEmail = authState.user?.email;

    if (userEmail == null) {
      return const Center(
        child: Text('User not authenticated'),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final userProfileAsyncValue = ref.watch(userProfileProvider(userEmail));

        return userProfileAsyncValue.when(
          data: (data) {
            final userDetails = data['user_details'] as UserDetailsModel;
            final userPosts = data['user_posts'] as List<PostModel>;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(userDetails),
                  _buildUserDetails(userDetails),
                  _buildUserPosts(userPosts),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error loading profile: $e'),
          ),
        );
      },
    );
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

  Widget _buildUserDetails(UserDetailsModel user) {
    final dateFormatter = DateFormat('dd MMMM yyyy');
    
    return Padding(
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                user.description!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          if (user.phoneNumber.isNotEmpty)
            _buildDetailRow(
              icon: Icons.phone,
              text: user.phoneNumber,
            ),
          _buildDetailRow(
            icon: Icons.cake,
            text: 'Born ${dateFormatter.format(user.dateOfBirth)}',
          ),
          if (user.cityOfBirth.isNotEmpty)
            _buildDetailRow(
              icon: Icons.location_city,
              text: 'From ${user.cityOfBirth}',
            ),
          _buildDetailRow(
            icon: user.gender == Gender.female ? Icons.female : Icons.male,
            text: '${user.gender.toString().split('.').last}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPosts(List<PostModel> posts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Your Posts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        posts.isEmpty
          ? const Center(child: Text('No posts yet'))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostListWidget(
                  post: posts[index],
                  isProfileView: true,
                );
              },
            ),
      ],
    );
  }
}