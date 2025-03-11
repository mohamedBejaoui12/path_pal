import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/home/presentation/business_posts_widget.dart';
import 'package:pfe1/features/home/presentation/comments_bottom_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/business_profile_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../domain/business_post_model.dart';
import '../data/business_post_provider.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../shared/theme/theme_provider.dart';

// Provider for business post interactions in user view
final userBusinessPostInteractionProvider = StateNotifierProvider.family<
    UserBusinessPostInteractionNotifier, bool, int>((ref, postId) {
  return UserBusinessPostInteractionNotifier(ref, postId);
});

class UserBusinessPostInteractionNotifier extends StateNotifier<bool> {
  final Ref ref;
  final int postId;
  final _supabase = Supabase.instance.client;

  UserBusinessPostInteractionNotifier(this.ref, this.postId) : super(false) {
    _initializeLikeState();
  }

  Future<void> _initializeLikeState() async {
    final authState = ref.read(authProvider);
    final userEmail = authState.user?.email;

    if (userEmail == null) return;

    try {
      final likeResponse = await _supabase
          .from('business_post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_email', userEmail)
          .maybeSingle();

      state = likeResponse != null;
    } catch (e) {
      debugPrint('Error initializing like state: $e');
    }
  }

  Future<void> toggleLike() async {
    final authState = ref.read(authProvider);
    final userEmail = authState.user?.email;

    if (userEmail == null) return;

    try {
      // Check if user has already liked the post
      final likeResponse = await _supabase
          .from('business_post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_email', userEmail)
          .maybeSingle();

      if (likeResponse == null) {
        // Add like
        await _supabase.from('business_post_likes').insert({
          'post_id': postId,
          'user_email': userEmail,
        });
        state = true; // Update state to liked
      } else {
        // Remove like
        await _supabase
            .from('business_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_email', userEmail);
        state = false; // Update state to unliked
      }

      // Invalidate the posts provider to refresh the data
      ref.invalidate(userBusinessPostsProvider(postId));
      ref.invalidate(businessPostsProvider);
      ref.invalidate(homeBusinessPostsProvider);
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }
}

// Provider to fetch business posts for a specific business
final userBusinessPostsProvider =
    FutureProvider.family<List<BusinessPostModel>, int>(
        (ref, businessId) async {
  final businessPostService = ref.read(businessPostServiceProvider);
  return businessPostService.fetchBusinessPostsByBusinessId(businessId);
});

class UserBusinessProfileScreen extends ConsumerStatefulWidget {
  final int businessId;

  const UserBusinessProfileScreen({Key? key, required this.businessId})
      : super(key: key);

  @override
  _UserBusinessProfileScreenState createState() =>
      _UserBusinessProfileScreenState();
}

class _UserBusinessProfileScreenState
    extends ConsumerState<UserBusinessProfileScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshPosts() async {
    // Invalidate both business details and posts
    ref.invalidate(businessDetailsProvider(widget.businessId));
    ref.invalidate(userBusinessPostsProvider(widget.businessId));
  }

  void _showCommentsBottomSheet(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentsBottomSheet(
        postId: postId,
        commentType: CommentType.businessPost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessDetailsAsync =
        ref.watch(businessDetailsProvider(widget.businessId));
    final businessPostsAsync =
        ref.watch(userBusinessPostsProvider(widget.businessId));
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Business Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor,
        actions: [
          // Add directions button
          businessDetailsAsync.when(
            data: (business) => IconButton(
              icon: const Icon(Icons.directions, color: Colors.white),
              onPressed: () =>
                  _getDirections(business?.latitude, business?.longitude),
              tooltip: 'Get Directions',
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshPosts,
        child: businessDetailsAsync.when(
          data: (business) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Business Profile Image
                business?.imageUrl != null
                    ? Image.network(
                        business!.imageUrl!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          color: AppColors.primaryColor,
                          child: const Icon(Icons.business,
                              size: 100, color: Colors.white),
                        ),
                      )
                    : Container(
                        height: 250,
                        color: AppColors.primaryColor,
                        child: const Icon(Icons.business,
                            size: 100, color: Colors.white),
                      ),

                // Business Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business?.businessName ?? 'Business Name',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: business?.email ?? 'N/A',
                      ),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: '${business?.latitude}, ${business?.longitude}',
                      ),
                    ],
                  ),
                ),

                // Business Posts Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Posts',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      businessPostsAsync.when(
                        data: (posts) => posts.isEmpty
                            ? const Center(child: Text('No posts yet'))
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: posts.length,
                                itemBuilder: (context, index) {
                                  final post = posts[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (post.imageUrl != null)
                                          Image.network(
                                            post.imageUrl!,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              const SizedBox(height: 8),
                                              if (post.description != null &&
                                                  post.description!.isNotEmpty)
                                                Text(post.description!),
                                              const SizedBox(height: 8),

                                              // Display interests
                                              if (post.interests.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8),
                                                  child: Wrap(
                                                    spacing: 8,
                                                    runSpacing: 4,
                                                    children: post.interests
                                                        .map((interest) {
                                                      return Chip(
                                                        label: Text(
                                                          interest,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        backgroundColor:
                                                            Colors.grey[200],
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),

                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // Like button
                                                  Consumer(
                                                    builder: (context, ref, _) {
                                                      final isLiked = ref.watch(
                                                          userBusinessPostInteractionProvider(
                                                              post.id ?? 0));

                                                      return InkWell(
                                                        onTap: () {
                                                          if (post.id != null) {
                                                            ref
                                                                .read(userBusinessPostInteractionProvider(
                                                                        post.id!)
                                                                    .notifier)
                                                                .toggleLike();
                                                          }
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                isLiked
                                                                    ? Icons
                                                                        .favorite
                                                                    : Icons
                                                                        .favorite_border,
                                                                size: 20,
                                                                color: isLiked
                                                                    ? Colors.red
                                                                    : Colors
                                                                        .grey,
                                                              ),
                                                              const SizedBox(
                                                                  width: 6),
                                                              Text(
                                                                  '${post.likesCount}'),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),

                                                  // Comments button
                                                  InkWell(
                                                    onTap: () {
                                                      if (post.id != null) {
                                                        _showCommentsBottomSheet(
                                                            post.id!);
                                                      }
                                                    },
                                                    child: const Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.comment,
                                                              size: 16,
                                                              color:
                                                                  Colors.grey),
                                                          SizedBox(width: 4),
                                                          Text('Comments'),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }

  // Move the method inside the class
  void _getDirections(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location information not available for this business'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current location
    Position? currentPosition;
    try {
      currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get your current location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Launch Google Maps with directions
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=$latitude,$longitude&travelmode=driving';

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch maps application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
