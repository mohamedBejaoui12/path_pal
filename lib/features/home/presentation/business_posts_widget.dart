import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/business/data/business_post_provider.dart';
import 'package:pfe1/features/business/domain/business_post_model.dart';
import 'package:pfe1/features/business/presentation/business_profile_screen.dart';
import 'package:pfe1/features/business/presentation/user_business_profile_screen.dart';
import 'package:pfe1/features/home/presentation/business_post_details_widget.dart';
import 'package:pfe1/features/home/presentation/comments_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../authentication/providers/auth_provider.dart';
import 'package:pfe1/features/business/presentation/create_business_post_screen.dart';

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
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              // Provider for individual post interaction
              final postInteractionProvider =
                  businessPostInteractionProvider(post.id ?? 0);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Profile Image, Name and Options Menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Profile image and name
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: post.businessProfileImage != null
                                        ? NetworkImage(post.businessProfileImage!)
                                        : null,
                                child: post.businessProfileImage == null
                                    ? const Icon(Icons.business, size: 30)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  final authState = ref.read(authProvider);
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Options menu (only for post owner)
                          Consumer(
                            builder: (context, ref, _) {
                              final authState = ref.watch(authProvider);
                              if (authState.user?.email == post.userEmail) {
                                return PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'update':
                                        final result =
                                            await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CreateBusinessPostScreen(
                                              businessId: post.businessId ?? 0,
                                              existingPost: post,
                                            ),
                                          ),
                                        );

                                        if (result == true) {
                                          ref.invalidate(
                                              homeBusinessPostsProvider);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Business post updated successfully!'),
                                            ),
                                          );
                                        }
                                        break;
                                      case 'delete':
                                        final confirmDelete =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Post'),
                                            content: const Text(
                                              'Are you sure you want to delete this post?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmDelete == true &&
                                            post.id != null) {
                                          try {
                                            await ref
                                                .read(
                                                    businessPostServiceProvider)
                                                .deleteBusinessPost(
                                                  postId: post.id!,
                                                  userEmail:
                                                      authState.user!.email!,
                                                );

                                            ref.invalidate(
                                                homeBusinessPostsProvider);

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Business post deleted successfully!'),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Failed to delete post: $e'),
                                              ),
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
                                          Text('Delete',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Post Image
                      if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Image.network(
                            post.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading image: $error');
                              return const Center(
                                child: Icon(Icons.error_outline,
                                    size: 40, color: Colors.red),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Post Title and Description
                      Text(
                        post.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (post.description != null &&
                          post.description!.isNotEmpty)
                        Text(post.description!,
                            style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),

                      // Add Interests display here
                      if (post.interests.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: post.interests.map((interest) {
                              return Chip(
                                label: Text(
                                  interest,
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: Colors.grey[200],
                              );
                            }).toList(),
                          ),
                        ),

                      // Date
                      Text(
                        DateFormat('yyyy-MM-dd')
                            .format(post.createdAt ?? DateTime.now()),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),

                      // Likes and Comments with Interaction
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Like Button
                          Consumer(
                            builder: (context, ref, child) {
                              final isLiked =
                                  ref.watch(postInteractionProvider) ||
                                      post.isLikedByCurrentUser;

                              return _LikeButton(
                                post: post,
                                isLiked: isLiked,
                                toggleLike: () {
                                  if (post.id != null) {
                                    ref
                                        .read(postInteractionProvider.notifier)
                                        .toggleLike();
                                  }
                                },
                              );
                            },
                          ),

                          // Comments Button
                          InkWell(
                            onTap: () {
                              if (post.id != null) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                  ),
                                  builder: (context) => CommentsBottomSheet(
                                    postId: post.id!,
                                    commentType: CommentType.businessPost,
                                  ),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.comment,
                                      size: 16, color: Colors.grey),
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
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final BusinessPostModel post;
  final bool isLiked;
  final VoidCallback toggleLike;

  const _LikeButton(
      {required this.post, required this.isLiked, required this.toggleLike});

  @override
  Widget build(BuildContext context) {
    // Prioritize current interaction state, fall back to post's like status
    final shouldShowLiked = isLiked || post.isLikedByCurrentUser;

    return InkWell(
      onTap: toggleLike,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(shouldShowLiked ? Icons.favorite : Icons.favorite_border,
                size: 20, color: shouldShowLiked ? Colors.red : Colors.grey),
            const SizedBox(width: 6),
            Text('${post.likesCount}'),
          ],
        ),
      ),
    );
  }
}
