import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pfe1/features/authentication/domain/user_details_model.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/home/domain/post_model.dart';
import 'package:pfe1/features/home/presentation/post_list_widget.dart';

String _generateDefaultProfileImage(String name) {
  return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff&size=200';
}

// New State class for user profile posts
class UserProfilePostsState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;

  UserProfilePostsState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });

  UserProfilePostsState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    String? error,
  }) {
    return UserProfilePostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// New Notifier for user profile posts
class UserProfilePostsNotifier extends StateNotifier<UserProfilePostsState> {
  final Ref ref;
  final String userEmail;
  final _supabase = Supabase.instance.client;

  UserProfilePostsNotifier(this.ref, this.userEmail) : super(UserProfilePostsState()) {
    fetchUserPosts();
  }

  Future<void> fetchUserPosts() async {
    try {
      state = state.copyWith(isLoading: true);

      // Get the current authenticated user's email
      final authState = ref.read(authProvider);
      final currentUserEmail = authState.user?.email;

      // Fetch user details
      final userResponse = await _supabase
          .from('user')
          .select('*')
          .eq('email', userEmail)
          .single();

      // Fetch user posts with full user details and likes
      final postsResponse = await _supabase
          .from('user_post')
          .select('''
            *,
            user:user_email(name, family_name, profile_image_url),
            post_likes(*)
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
          (like) => like['user_email'] == currentUserEmail
        );

        // Add current user's email to the JSON for PostModel parsing
        json['current_user_email'] = currentUserEmail;

        return PostModel.fromJson(json);
      }).toList();

      state = state.copyWith(
        posts: posts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      debugPrint('Error fetching user posts: $e');
    }
  }

  // Add a method to toggle like for a specific post
  Future<void> toggleLike(int postId) async {
    try {
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;

      if (userEmail == null) {
        throw Exception('User not authenticated');
      }

      // Create a copy of current posts to modify
      final currentPosts = [...state.posts];

      // Find the index of the post to update
      final postIndex = currentPosts.indexWhere((post) => post.id == postId);

      if (postIndex == -1) {
        throw Exception('Post not found');
      }

      final currentPost = currentPosts[postIndex];

      // Determine if the post is currently liked
      final isCurrentlyLiked = currentPost.isLikedByCurrentUser;

      // Perform like/unlike operation
      try {
        // Try to find existing like
        final existingLikeResponse = await _supabase
            .from('post_likes')
            .select('id')
            .eq('post_id', postId)
            .eq('user_email', userEmail)
            .maybeSingle();

        if (existingLikeResponse != null) {
          // Unlike: remove the like
          await _supabase
              .from('post_likes')
              .delete()
              .eq('post_id', postId)
              .eq('user_email', userEmail);
        } else {
          // Like: add a new like
          await _supabase
              .from('post_likes')
              .insert({
                'post_id': postId,
                'user_email': userEmail,
              });
        }
      } on PostgrestException catch (postgrestError) {
        debugPrint('Supabase Error during like toggle: ${postgrestError.message}');
        throw Exception('Failed to update like status: ${postgrestError.message}');
      }

      // Update the post locally with optimistic update
      currentPosts[postIndex] = currentPost.copyWith(
        isLikedByCurrentUser: !isCurrentlyLiked,
        likesCount: isCurrentlyLiked 
          ? currentPost.likesCount - 1 
          : currentPost.likesCount + 1,
      );

      // Update the state with the modified posts
      state = state.copyWith(posts: currentPosts);
    } catch (e) {
      debugPrint('Comprehensive Error toggling like: $e');
      rethrow;
    }
  }
}

// Provider for user profile posts
final userProfilePostsProvider = StateNotifierProvider.family<
  UserProfilePostsNotifier, 
  UserProfilePostsState, 
  String
>((ref, userEmail) {
  return UserProfilePostsNotifier(ref, userEmail);
});

// Update the existing userProfileProvider to use the new posts provider
final userProfileProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userEmail) async {
  final supabase = Supabase.instance.client;
  
  // Get the current authenticated user's email
  final authState = ref.read(authProvider);
  final currentUserEmail = authState.user?.email;

  // Fetch user details
  final userResponse = await supabase
      .from('user')
      .select('*')
      .eq('email', userEmail)
      .single();

  // Fetch user posts with full user details and likes
  final postsResponse = await supabase
      .from('user_post')
      .select('''
        *,
        user:user_email(name, family_name, profile_image_url),
        post_likes(*)
      ''')
      .eq('user_email', userEmail)
      .order('created_at', ascending: false);

  // Convert posts to PostModel with accurate like status
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

    // Fetch post likes and determine if liked by current user
    final postLikes = json['post_likes'] as List? ?? [];
    final isLikedByCurrentUser = postLikes.any(
      (like) => like['user_email'] == currentUserEmail
    );

    // Add current user's email to the JSON for PostModel parsing
    json['current_user_email'] = currentUserEmail;
    json['is_liked_by_current_user'] = isLikedByCurrentUser;
    json['likes_count'] = postLikes.length;

    return PostModel.fromJson(json);
  }).toList();

  return {
    'user_details': UserDetailsModel(
      name: userResponse['name'],
      email: userResponse['email'],
      familyName: userResponse['family_name'],
      profileImageUrl: userResponse['profile_image_url'],
      description: userResponse['description'],
      dateOfBirth: userResponse['date_of_birth'] != null 
        ? DateTime.tryParse(userResponse['date_of_birth']) ?? DateTime.now()
        : DateTime.now(),
      cityOfBirth: userResponse['city_of_birth'] ?? '',
      phoneNumber: userResponse['phone_number'] ?? '',
      gender: userResponse['gender'] == 'female' ? Gender.female : Gender.male,
    ),
    'user_posts': posts,
  };
});

class ProfileWidget extends ConsumerStatefulWidget {
  final String userEmail;

  const ProfileWidget({Key? key, required this.userEmail}) : super(key: key);

  @override
  _ProfileWidgetState createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends ConsumerState<ProfileWidget> {
  late String userEmail;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    userEmail = widget.userEmail;
  }

  // Comprehensive like toggle method
  Future<void> _toggleLikeInProfile(int postId) async {
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final currentUserEmail = authState.user?.email;

      if (currentUserEmail == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check for existing like
      final existingLikeResponse = await supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_email', currentUserEmail)
          .maybeSingle();

      if (existingLikeResponse != null) {
        // Unlike: remove the like
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_email', currentUserEmail);
      } else {
        // Like: add a new like
        await supabase
            .from('post_likes')
            .insert({
              'post_id': postId,
              'user_email': currentUserEmail,
            });
      }

      // Force a complete refresh of the user profile
      ref.invalidate(userProfileProvider(userEmail));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle like: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Comprehensive refresh method
  Future<void> _refreshProfile() async {
    try {
      // Force a refresh of the user profile provider
      ref.invalidate(userProfileProvider(userEmail));
      
      // Wait for the provider to reload
      await ref.read(userProfileProvider(userEmail).future);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                  key: ValueKey(posts[index].id),
                  post: posts[index],
                  isProfileView: true,
                  onLikeToggle: () {
                    // Implement like toggle for profile view
                    _toggleLikeInProfile(posts[index].id!);
                  },
                );
              },
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshProfile,
        child: CustomScrollView(
          slivers: [
            Consumer(
              builder: (context, ref, child) {
                final userProfileAsync = ref.watch(userProfileProvider(userEmail));

                return userProfileAsync.when(
                  data: (profileData) {
                    final userDetails = profileData['user_details'] as UserDetailsModel;
                    final userPosts = profileData['user_posts'] as List<PostModel>;

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        _buildProfileHeader(userDetails),
                        _buildUserDetails(userDetails),
                        _buildUserPosts(userPosts),
                      ]),
                    );
                  },
                  loading: () => SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => SliverToBoxAdapter(
                    child: Center(child: Text('Error: $error')),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}