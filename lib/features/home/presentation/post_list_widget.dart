import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:pfe1/features/home/domain/post_model.dart';
import 'package:pfe1/features/home/presentation/comments_bottom_sheet.dart';
import 'package:pfe1/features/home/presentation/profile_widget.dart';
import 'package:pfe1/features/home/presentation/user_profile_screen.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';
import 'package:pfe1/shared/theme/app_colors.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/home/data/post_provider.dart';
import 'package:pfe1/features/authentication/data/comment_provider.dart';
import 'package:image_picker/image_picker.dart';

class PostListWidget extends ConsumerStatefulWidget {
  final PostModel? post;
  final bool isProfileView;
  final VoidCallback? onLikeToggle;

  const PostListWidget({
    Key? key,
    this.post,
    this.isProfileView = false,
    this.onLikeToggle,
  }) : super(key: key);

  @override
  _PostListWidgetState createState() => _PostListWidgetState();
}

class _PostListWidgetState extends ConsumerState<PostListWidget> {
  @override
  void initState() {
    super.initState();
    // Only fetch posts if not in profile view
    if (!widget.isProfileView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(postListProvider.notifier).fetchPosts();
      });
    }
  }

  void _showCommentsBottomSheet(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentsBottomSheet(postId: postId),
    );
  }

  void _showPostOptionsMenu(BuildContext context, PostModel post) {
    final isDarkMode = ref.watch(themeProvider);
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
                onTap: () {
                  Navigator.pop(context);
                  _showEditPostDialog(post);
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
                  _confirmDeletePost(post);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeletePost(PostModel post) {
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
            onPressed: () {
              Navigator.pop(context);

              // Check if this is from a profile view
              if (widget.isProfileView) {
                ref.read(postListProvider.notifier).deletePost(post.id!,
                    onPostDeleted: () {
                  // Trigger a refresh of the profile view
                  ref.invalidate(userProfileProvider);
                });
              } else {
                ref.read(postListProvider.notifier).deletePost(post.id!);
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

  void _showEditPostDialog(PostModel post) {
    final titleController = TextEditingController(text: post.title);
    final descriptionController = TextEditingController(text: post.description);
    final interestsController =
        TextEditingController(text: post.interests.join(', '));

    // Image picker variables
    XFile? pickedImage;
    String? existingImageUrl = post.imageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit_rounded,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 10),
              const Text(
                'Edit Post',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                // Image selection section
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pickedImage != null
                            ? 'Image Selected: ${pickedImage!.name}'
                            : existingImageUrl != null
                                ? 'Current Image Exists'
                                : 'No Image Selected',
                        style: TextStyle(
                          color: pickedImage != null || existingImageUrl != null
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.image_outlined),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1000,
                          maxHeight: 1000,
                          imageQuality: 80,
                        );

                        setState(() {
                          if (image != null) {
                            pickedImage = image;
                            existingImageUrl = null; // Clear existing URL
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: interestsController,
                  decoration: InputDecoration(
                    labelText: 'Interests (comma-separated)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
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
              onPressed: () {
                Navigator.pop(context);

                // Check if this is from a profile view
                if (widget.isProfileView) {
                  ref.read(postListProvider.notifier).updatePost(
                      postId: post.id!,
                      title: titleController.text,
                      description: descriptionController.text,
                      imageUrl: pickedImage != null
                          ? pickedImage!.path
                          : existingImageUrl,
                      interests: interestsController.text.isNotEmpty
                          ? interestsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .toList()
                          : null,
                      onPostUpdated: () {
                        // Trigger a refresh of the profile view
                        ref.invalidate(userProfileProvider);
                      });
                } else {
                  ref.read(postListProvider.notifier).updatePost(
                        postId: post.id!,
                        title: titleController.text,
                        description: descriptionController.text,
                        imageUrl: pickedImage != null
                            ? pickedImage!.path
                            : existingImageUrl,
                        interests: interestsController.text.isNotEmpty
                            ? interestsController.text
                                .split(',')
                                .map((e) => e.trim())
                                .toList()
                            : null,
                      );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUserProfile(String userEmail) {
    final authState = ref.read(authProvider);
    final currentUserEmail = authState.user?.email;

    if (userEmail != currentUserEmail) {
      // Only navigate for other users
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userEmail: userEmail,
            isOtherUserProfile: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    // If in profile view, use the passed post
    if (widget.isProfileView && widget.post != null) {
      return _buildPostCard(widget.post!, isDarkMode);
    }

    // If not in profile view, use postListProvider
    final postListState = ref.watch(postListProvider);

    if (postListState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (postListState.error != null) {
      return Center(
        child: Text(
          'Error loading posts: ${postListState.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: postListState.posts.length,
      itemBuilder: (context, index) {
        final post = postListState.posts[index];
        return _buildPostCard(post, isDarkMode);
      },
    );
  }

  Widget _buildPostCard(PostModel post, bool isDarkMode) {
    final authState = ref.read(authProvider);
    final currentUserEmail = authState.user?.email;
    final isCurrentUser = post.userEmail == currentUserEmail;

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
              // User Header
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: post.userProfileImage != null
                      ? NetworkImage(post.userProfileImage!)
                      : null,
                  child: post.userProfileImage == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                // In the _buildPostCard method, update the ListTile title section
                title: isCurrentUser
                    ? Row(
                        children: [
                          Text(
                            post.userName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          if (post.isUserVerified)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      )
                    : GestureDetector(
                        onTap: () => _navigateToUserProfile(post.userEmail),
                        child: Row(
                          children: [
                            Text(
                              post.userName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            if (post.isUserVerified)
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ),
                          ],
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
                    ? IconButton(
                        icon: Icon(Icons.more_vert,
                            color: isDarkMode ? Colors.white : Colors.black),
                        onPressed: () => _showPostOptionsMenu(context, post),
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
                    if (post.description != null)
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
                            post.isLikedByCurrentUser
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: post.isLikedByCurrentUser
                                ? Colors.red
                                : (isDarkMode ? Colors.white : Colors.black),
                          ),
                          onPressed: () {
                            // If onLikeToggle is provided, use it first
                            if (widget.onLikeToggle != null) {
                              widget.onLikeToggle!();
                            } else {
                              // Fallback to the default provider method
                              ref
                                  .read(postListProvider.notifier)
                                  .toggleLike(post.id!);
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
                        _showCommentsBottomSheet(post.id!);
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
}
