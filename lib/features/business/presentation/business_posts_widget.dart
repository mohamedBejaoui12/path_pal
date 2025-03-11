import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/business/data/business_post_provider.dart';
import 'package:pfe1/features/business/domain/business_post_model.dart';
import 'package:pfe1/features/business/presentation/business_profile_screen.dart';
import 'package:pfe1/features/business/presentation/user_business_profile_screen.dart';
import 'package:pfe1/features/home/presentation/business_post_details_widget.dart';
import 'package:pfe1/features/home/presentation/comments_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../authentication/providers/auth_provider.dart';
import 'package:pfe1/features/business/presentation/create_business_post_screen.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';
import 'package:pfe1/shared/theme/app_colors.dart';

// Provider for business post interactions
final businessPostInteractionProvider =
    StateNotifierProvider.family<BusinessPostInteractionNotifier, bool, int>(
        (ref, postId) {
  return BusinessPostInteractionNotifier(ref, postId);
});

// Provider for home business posts
final homeBusinessPostsProvider =
    FutureProvider<List<BusinessPostModel>>((ref) async {
  final businessPostService = ref.read(businessPostServiceProvider);
  return businessPostService.fetchAllBusinessPosts();
});

class BusinessPostInteractionNotifier extends StateNotifier<bool> {
  final Ref ref;
  final int postId;
  final _supabase = Supabase.instance.client;

  BusinessPostInteractionNotifier(this.ref, this.postId) : super(false) {
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

      // Invalidate both home and business profile posts providers
      ref.invalidate(homeBusinessPostsProvider);
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }
}

class BusinessPostsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current theme mode
    final isDarkMode = ref.watch(themeProvider);
    
    // Fetch all business posts using the provider
    final businessPostsAsync = ref.watch(homeBusinessPostsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate provider to force a refresh
        ref.invalidate(homeBusinessPostsProvider);
      },
      child: businessPostsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return ListView(
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No posts available'),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildBusinessPostCard(context, ref, post, isDarkMode);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading posts: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessPostCard(BuildContext context, WidgetRef ref, BusinessPostModel post, bool isDarkMode) {
    final authState = ref.read(authProvider);
    final currentUserEmail = authState.user?.email;
    final isCurrentUser = post.userEmail == currentUserEmail;

    // Provider for individual post interaction
    final postInteractionProvider = businessPostInteractionProvider(post.id ?? 0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: !isDarkMode 
        ? BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          )
        : null,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: isDarkMode ? 1 : 0,
        child: Ink(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Header
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: post.businessProfileImage != null
                          ? NetworkImage(post.businessProfileImage!)
                          : null,
                  child: post.businessProfileImage == null
                      ? const Icon(Icons.business, size: 30)
                      : null,
                ),
                title: GestureDetector(
                  onTap: () {
                    if (authState.user?.email == post.userEmail) {
                      // Navigate to own business profile
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BusinessProfileScreen(
                            businessId: post.businessId ?? 0,
                          ),
                        ),
                      );
                    } else {
                      // Navigate to other user's business profile
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserBusinessProfileScreen(
                            businessId: post.businessId ?? 0,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    post.businessName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                subtitle: Text(
                  post.createdAt != null 
                    ? DateFormat('dd MMM yyyy').format(post.createdAt!) 
                    : 'Unknown Date',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                trailing: post.userEmail == currentUserEmail
                    ? PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onSelected: (value) async {
                          switch (value) {
                            case 'update':
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CreateBusinessPostScreen(
                                    businessId: post.businessId ?? 0,
                                    existingPost: post,
                                  ),
                                ),
                              );

                              if (result == true) {
                                ref.invalidate(homeBusinessPostsProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Business post updated successfully!'),
                                  ),
                                );
                              }
                              break;
                            case 'delete':
                              final confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Post'),
                                  content: const Text(
                                    'Are you sure you want to delete this post?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmDelete == true && post.id != null) {
                                try {
                                  await ref.read(businessPostServiceProvider)
                                      .deleteBusinessPost(
                                        postId: post.id!,
                                        userEmail: authState.user!.email!,
                                      );

                                  ref.invalidate(homeBusinessPostsProvider);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Business post deleted successfully!'),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to delete post: $e'),
                                    ),
                                  );
                                }
                              }
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'update',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Update',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: const [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
              
              // Post Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    if (post.description != null && post.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          post.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[300] : Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Post Image
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) {
                      debugPrint('Image load error: $error');
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50, color: Colors.red),
                        ),
                      );
                    },
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),

              // Interests
              if (post.interests.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: post.interests.map((interest) {
                      return Chip(
                        label: Text(
                          interest,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      );
                    }).toList(),
                  ),
                ),

              // Comments and Likes Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Like Button
                    Consumer(
                      builder: (context, ref, child) {
                        final isLiked = ref.watch(postInteractionProvider) || 
                                        post.isLikedByCurrentUser;
                        
                        return Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked 
                                  ? Colors.red 
                                  : (isDarkMode ? Colors.white : Colors.black),
                              ),
                              onPressed: () {
                                if (post.id != null) {
                                  ref.read(postInteractionProvider.notifier).toggleLike();
                                }
                              },
                            ),
                            Text(
                              '${post.likesCount ?? 0}',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    // Comments Button
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.comment_outlined,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => CommentsBottomSheet(
                                postId: post.id ?? 0,
                                commentType: CommentType.businessPost,
                              ),
                            );
                          },
                        ),
                        Text(
                          '${post.commentsCount ?? 0}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}