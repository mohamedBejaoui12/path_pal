import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pfe1/features/authentication/domain/user_details_model.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/home/domain/post_model.dart';
import 'package:pfe1/features/home/data/post_provider.dart';
import 'package:pfe1/features/home/presentation/post_list_widget.dart';

class ProfileWidget extends ConsumerStatefulWidget {
  const ProfileWidget({Key? key}) : super(key: key);

  @override
  _ProfileWidgetState createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends ConsumerState<ProfileWidget> {
  late Future<UserDetailsModel?> _userDetailsFuture;
  late Future<List<PostModel>> _userPostsFuture;

  @override
  void initState() {
    super.initState();
    _userDetailsFuture = _fetchUserDetails();
    _userPostsFuture = _fetchUserPosts();
  }

  Future<UserDetailsModel?> _fetchUserDetails() async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      
      if (user == null) {
        return null;
      }

      final response = await Supabase.instance.client
          .from('user')
          .select('*')
          .eq('email', user.email as Object)
          .single();

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

  Future<List<PostModel>> _fetchUserPosts() async {
  try {
    final authState = ref.read(authProvider);
    final user = authState.user;
    
    if (user == null) {
      return [];
    }

    // Fetch user details to get profile image
    final userDetailsResponse = await Supabase.instance.client
        .from('user')
        .select('profile_image_url')
        .eq('email', user.email as Object)
        .single();

    final userProfileImage = userDetailsResponse['profile_image_url'];
  
    try {
      final response = await Supabase.instance.client
          .from('user_post')
          .select('*')
          .eq('user_email', user.email as Object)
          .order('created_at', ascending: false);
      
      return response.map<PostModel>((post) {
        // Correct image link formatting
        String? correctImageLink = post['image_link'];
        if (correctImageLink != null && !correctImageLink.contains('.')) {
          // Add the missing dot before jpg
          correctImageLink = correctImageLink.replaceAll('jpg', '.jpg');
        }

        print('Corrected Image Link: $correctImageLink'); // Debug print

        return PostModel(
          id: post['id'],
          userEmail: post['user_email'] ?? user.email,
          userName: post['user_name'] ?? user.email!.split('@').first,
          userProfileImage: userProfileImage ?? 
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.email!.split('@').first)}&background=random&color=fff&size=200',
          title: post['title'] ?? 'Untitled Post',
          description: post['description'],
          imageUrl: correctImageLink, // Use corrected image link
          interests: List<String>.from(post['interests'] ?? []),
          createdAt: post['created_at'] != null 
            ? DateTime.parse(post['created_at']) 
            : DateTime.now(),
          likesCount: post['likes_count'] ?? 0,
          commentsCount: post['comments_count'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print('Detailed error fetching user posts: $e');
      return [];
    }
  } catch (e) {
    print('Error in user post fetch process: $e');
    return [];
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_userDetailsFuture, _userPostsFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('Error loading profile'),
          );
        }

        final userDetails = snapshot.data![0] as UserDetailsModel?;
        final userPosts = snapshot.data![1] as List<PostModel>;

        if (userDetails == null) {
          return const Center(
            child: Text('User not found'),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(userDetails),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${userDetails.name} ${userDetails.familyName}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (userDetails.description != null)
                      Text(
                        userDetails.description!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              _buildUserPosts(userPosts),
            ],
          ),
        );
      },
    );
  }
}