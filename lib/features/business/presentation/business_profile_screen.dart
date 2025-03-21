import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pfe1/features/business/presentation/update_business_profile_screen.dart';
import 'package:pfe1/features/business/presentation/create_business_post_screen.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pfe1/features/home/presentation/comments_bottom_sheet.dart';

import '../data/business_profile_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../domain/business_post_model.dart';


import '../data/business_post_provider.dart';
import '../../authentication/providers/auth_provider.dart';

// Provider for business post interactions
final businessPostInteractionProvider = StateNotifierProvider.family<BusinessPostInteractionNotifier, bool, int>((ref, postId) {
  return BusinessPostInteractionNotifier(ref, postId);
});

class BusinessPostInteractionNotifier extends StateNotifier<bool> {
  final Ref ref;
  final int postId;
  final _supabase = Supabase.instance.client;

  BusinessPostInteractionNotifier(this.ref, this.postId) : super(false);

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
        await _supabase
            .from('business_post_likes')
            .insert({
          'post_id': postId,
          'user_email': userEmail,
        });
      } else {
        // Remove like
        await _supabase
            .from('business_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_email', userEmail);
      }

      // Invalidate the posts provider to refresh the data
      ref.invalidate(businessPostsProvider);
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }
}

// New provider to fetch business posts
final businessPostsProvider = FutureProvider.family<List<BusinessPostModel>, int>((ref, businessId) async {
  final supabase = Supabase.instance.client;
  final authState = ref.read(authProvider);
  final userEmail = authState.user?.email;

  try {
    // First, fetch the business posts
    final postsResponse = await supabase
        .from('business_posts')
        .select('*')
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    
    // Convert to BusinessPostModel and enrich with likes information
    final enrichedPosts = await Future.wait(
      postsResponse.map<Future<BusinessPostModel>>((json) async {
        // Fetch likes count for this post
        final likesResponse = await supabase
            .from('business_post_likes')
            .select('*')
            .eq('post_id', json['id']);
        
        // Check if current user has liked the post
        final userLikeResponse = userEmail != null
          ? await supabase
              .from('business_post_likes')
              .select()
              .eq('post_id', json['id'])
              .eq('user_email', userEmail)
              .maybeSingle()
          : null;

        // Create the business post model
        final businessPost = BusinessPostModel.fromJson(json);
        
        return businessPost.copyWith(
          likesCount: likesResponse.length,
          isLikedByCurrentUser: userLikeResponse != null,
        );
      }).toList()
    );

    return enrichedPosts;
  } catch (e) {
    debugPrint('Error fetching business posts: $e');
    return [];
  }
});

class BusinessProfileScreen extends ConsumerStatefulWidget {
  final int businessId;

  const BusinessProfileScreen({
    Key? key, 
    required this.businessId
  }) : super(key: key);

  @override
  _BusinessProfileScreenState createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> with AutomaticKeepAliveClientMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = 
      GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshPosts() async {
    // Invalidate both business details and posts
    ref.invalidate(businessDetailsProvider(widget.businessId));
    ref.invalidate(businessPostsProvider(widget.businessId));
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final businessDetailsAsync = ref.watch(businessDetailsProvider(widget.businessId));
    final businessPostsAsync = ref.watch(businessPostsProvider(widget.businessId));
    final authState = ref.watch(authProvider);
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
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add, color: Colors.white),
            tooltip: 'Create Business Post',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateBusinessPostScreen(businessId: widget.businessId),
                ),
              );

              // If post was created successfully, refresh the posts
              if (result == true) {
                ref.invalidate(businessPostsProvider(widget.businessId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Business post created successfully!')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UpdateBusinessProfileScreen(businessId: widget.businessId),
                ),
              );

              // If update was successful, refresh the business details
              if (result == true) {
                ref.read(businessDetailsProvider(widget.businessId).notifier)
                  .refreshBusinessDetails();
              }
            },
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
                      errorBuilder: (context, error, stackTrace) => 
                        Container(
                          height: 250,
                          color: AppColors.primaryColor,
                          child: const Icon(
                            Icons.business, 
                            size: 100, 
                            color: Colors.white
                          ),
                        ),
                    )
                  : Container(
                      height: 250,
                      color: AppColors.primaryColor,
                      child: const Icon(
                        Icons.business, 
                        size: 100, 
                        color: Colors.white
                      ),
                    ),

                // Business Details
                // In the business details section, update the business name display to include verification icon
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              business?.businessName ?? 'Business Name',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          if (business?.isVerified == true)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Icon(
                                Icons.verified,
                                size: 24,
                                color: Colors.blue,
                              ),
                            ),
                        ],
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
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Created At',
                        value: business?.createdAt?.toString() ?? 'N/A',
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    post.title,
                                                    style: Theme.of(context).textTheme.titleMedium,
                                                  ),
                                                ),
                                                // Three-dot menu for post owned by current user
                                                if (authState.user?.email == post.userEmail)
                                                  PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert),
                                                    onSelected: (value) async {
                                                      switch (value) {
                                                        case 'update':
                                                          // Navigate to update post screen
                                                          final result = await Navigator.of(context).push(
                                                            MaterialPageRoute(
                                                              builder: (context) => CreateBusinessPostScreen(
                                                                businessId: widget.businessId,
                                                                existingPost: post,  // Pass the current post
                                                              ),
                                                            ),
                                                          );

                                                          // If post was updated successfully, refresh the posts
                                                          if (result == true) {
                                                            ref.invalidate(businessPostsProvider(widget.businessId));
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Business post updated successfully!')),
                                                            );
                                                          }
                                                          break;
                                                        case 'delete':
                                                          // Show confirmation dialog
                                                          final confirmDelete = await showDialog<bool>(
                                                            context: context,
                                                            builder: (context) => AlertDialog(
                                                              title: const Text('Delete Post'),
                                                              content: const Text('Are you sure you want to delete this post?'),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.of(context).pop(false),
                                                                  child: const Text('Cancel'),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () => Navigator.of(context).pop(true),
                                                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                                ),
                                                              ],
                                                            ),
                                                          );

                                                          // Perform deletion if confirmed
                                                          if (confirmDelete == true && post.id != null) {
                                                            try {
                                                              await ref.read(createBusinessPostProvider.notifier)
                                                                .deleteBusinessPost(postId: post.id!);
                                                              
                                                              // Refresh posts
                                                              ref.invalidate(businessPostsProvider(widget.businessId));
                                                              
                                                              // Show success message
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(content: Text('Business post deleted successfully!')),
                                                              );
                                                            } catch (e) {
                                                              // Show error message
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text('Failed to delete post: $e')),
                                                              );
                                                            }
                                                          }
                                                          break;
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'update',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit),
                                                            SizedBox(width: 8),
                                                            Text('Update'),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete, color: Colors.red),
                                                            SizedBox(width: 8),
                                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                            if (post.description != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  post.description!,
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today, size: 16),
                                                const SizedBox(width: 8),
                                                Text(
                                                  post.createdAt?.toString().split(' ')[0] ?? 'Unknown Date',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Likes and Comments Row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                // Like Button
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        post.isLikedByCurrentUser 
                                                          ? Icons.favorite 
                                                          : Icons.favorite_border,
                                                        color: post.isLikedByCurrentUser 
                                                          ? Colors.red 
                                                          : null,
                                                      ),
                                                      onPressed: authState.user != null
                                                        ? () {
                                                            ref.read(businessPostInteractionProvider(post.id!).notifier)
                                                              .toggleLike();
                                                          }
                                                        : null,
                                                    ),
                                                    Text('${post.likesCount}'),
                                                  ],
                                                ),
                                                // Comments Button
                                                IconButton(
                                                  icon: const Icon(Icons.comment_outlined),
                                                  onPressed: () {
                                                    if (post.id != null) {
                                                      _showCommentsBottomSheet(post.id!);
                                                    }
                                                  },
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
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => Center(child: Text('Error loading posts: $error')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }
}