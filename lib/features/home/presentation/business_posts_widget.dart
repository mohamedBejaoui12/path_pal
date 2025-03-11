import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pfe1/features/business/data/business_post_provider.dart';
import 'package:pfe1/features/business/domain/business_post_model.dart';
import 'package:pfe1/features/business/presentation/business_profile_screen.dart';
import 'package:pfe1/features/business/presentation/user_business_profile_screen.dart';
import 'package:pfe1/features/home/presentation/comments_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../authentication/providers/auth_provider.dart';
import 'package:pfe1/features/business/presentation/create_business_post_screen.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';

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
    final isDarkMode = ref.watch(themeProvider);

    // Fetch all business posts using the provider
    final businessPostsAsync = ref.watch(homeBusinessPostsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate provider to force a refresh
        ref.invalidate(homeBusinessPostsProvider);
      },
      color: AppColors.primaryColor,
      backgroundColor: Colors.white,
      displacement: 40,
      strokeWidth: 2.0,
      child: businessPostsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return ListView(
              physics: const BouncingScrollPhysics(),
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No business posts available'),
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
            'Error loading business posts: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessPostCard(BuildContext context, WidgetRef ref,
      BusinessPostModel post, bool isDarkMode) {
    final authState = ref.read(authProvider);
    final currentUserEmail = authState.user?.email;
    final isCurrentUser = post.userEmail == currentUserEmail;

    // Provider for individual post interaction
    final postInteractionProvider =
        businessPostInteractionProvider(post.id ?? 0);
    final isLiked =
        ref.watch(postInteractionProvider) || post.isLikedByCurrentUser;

    // Debug print to check business profile image
    debugPrint('Business profile image URL: ${post.businessProfileImage}');

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
                leading: GestureDetector(
                  onTap: () {
                    if (isCurrentUser) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BusinessProfileScreen(
                            businessId: post.businessId,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserBusinessProfileScreen(
                            businessId: post.businessId,
                          ),
                        ),
                      );
                    }
                  },
                  // Inside the _buildBusinessPostCard method, update the CircleAvatar part:
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    child: post.businessProfileImage != null && post.businessProfileImage!.isNotEmpty
                        ? Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(post.businessProfileImage!),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  debugPrint('Error loading business image: $exception');
                                },
                              ),
                            ),
                          )
                        : Icon(Icons.business, color: isDarkMode ? Colors.white70 : Colors.grey[700]),
                  ),
                ),
                title: GestureDetector(
                  onTap: () {
                    if (isCurrentUser) {
                      // Navigate to own business profile
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BusinessProfileScreen(
                            businessId: post.businessId,
                          ),
                        ),
                      );
                    } else {
                      // Navigate to other user's business profile
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserBusinessProfileScreen(
                            businessId: post.businessId,
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
                trailing: isCurrentUser
                    ? IconButton(
                        icon: Icon(Icons.more_vert,
                            color: isDarkMode ? Colors.white : Colors.black),
                        onPressed: () =>
                            _showPostOptionsMenu(context, ref, post),
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
                    if (post.description != null &&
                        post.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          post.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDarkMode ? Colors.grey[300] : Colors.black87,
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
                      print('Image load error: $error');
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              size: 50, color: Colors.red),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        backgroundColor:
                            isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      );
                    }).toList(),
                  ),
                ),

              // Comments and Likes Section
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Like Button
                    Row(
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
                              ref
                                  .read(postInteractionProvider.notifier)
                                  .toggleLike();
                            }
                          },
                        ),
                        Text('${post.likesCount} Likes'),
                      ],
                    ),
                    // Comments Button
                    TextButton.icon(
                      icon: const Icon(Icons.comment_outlined),
                      label: Text('${post.commentsCount} Comments'),
                      onPressed: () {
                        if (post.id != null) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (context) {
                              // Calculate half of the screen height
                              final screenHeight =
                                  MediaQuery.of(context).size.height;
                              final halfScreenHeight = screenHeight * 0.6;

                              return Container(
                                height: halfScreenHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                  child: CommentsBottomSheet(
                                    postId: post.id!,
                                    commentType: CommentType.businessPost,
                                  ),
                                ),
                              );
                            },
                          ).then((_) {
                            // Refresh the posts when the comments sheet is closed
                            ref.invalidate(homeBusinessPostsProvider);
                          });
                        }
                      },
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

  void _showPostOptionsMenu(
      BuildContext context, WidgetRef ref, BusinessPostModel post) {
    final isDarkMode = ref.watch(themeProvider);
    final authState = ref.read(authProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                title: Text(
                  'Edit Post',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreateBusinessPostScreen(
                        businessId: post.businessId,
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
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePost(context, ref, post);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeletePost(
      BuildContext context, WidgetRef ref, BusinessPostModel post) {
    final authState = ref.read(authProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.orange[700],
            ),
            const SizedBox(width: 10),
            const Text(
              'Confirm Deletion',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to permanently delete this post?',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[300],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (post.id != null) {
                try {
                  await ref
                      .read(businessPostServiceProvider)
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete Post'),
          ),
        ],
      ),
    );
  }
}
