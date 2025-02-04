import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:pfe1/features/home/presentation/home_screen.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';

import '../../../shared/theme/app_colors.dart';
import '../data/post_provider.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import 'package:pfe1/features/authentication/data/comment_provider.dart';

class PostListWidget extends ConsumerStatefulWidget {
  const PostListWidget({Key? key}) : super(key: key);

  @override
  _PostListWidgetState createState() => _PostListWidgetState();
}

class _PostListWidgetState extends ConsumerState<PostListWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(postListProvider.notifier).fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final postListState = ref.watch(postListProvider);

    if (postListState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor,));
    }

    if (postListState.error != null) {
      return Center(
        child: Text(
          'Error loading posts: ${postListState.error}',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    void _showCommentsBottomSheet(int postId) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _CommentsBottomSheet(postId: postId),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: postListState.posts.length,
      itemBuilder: (context, index) {
        final post = postListState.posts[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
           decoration: !isDarkMode 
    ? BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2), // changes position of shadow
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
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: post.userProfileImage != null
                                ? NetworkImage(post.userProfileImage!)
                                : null,
                            child: post.userProfileImage == null
                                ? const Icon(Icons.person, size: 24)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                              Text(
                                post.createdAt != null
                                    ? DateFormat('MMM d, yyyy · h:mm a')
                                        .format(post.createdAt!)
                                    : 'Unknown Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
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
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Image
                  if (post.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrl!,
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 280,
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 280,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),

                  // Interests
                  if (post.interests.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: post.interests.map((interest) {
                          return Chip(
                            label: Text(
                              interest,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            backgroundColor: isDarkMode
                                ? AppColors.primaryColor.withOpacity(0.1)
                                : AppColors.primaryColor.withOpacity(0.15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            post.isLikedByCurrentUser
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            color: post.isLikedByCurrentUser
                                ? Colors.red
                                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            size: 28,
                          ),
                          onPressed: () {
                            ref.read(postListProvider.notifier).toggleLike(post.id!);
                          },
                        ),
                        Text(
                          '${post.likesCount}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            Icons.mode_comment_outlined,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            size: 24,
                          ),
                          onPressed: () => _showCommentsBottomSheet(post.id!),
                        ),
                        Text(
                          post.commentsCount > 0 ? '${post.commentsCount} comments' : 'No comments',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.share_outlined,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            size: 24,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CommentsBottomSheet extends ConsumerStatefulWidget {
  final int postId;

  const _CommentsBottomSheet({Key? key, required this.postId}) : super(key: key);

  @override
  CommentsBottomSheetState createState() => CommentsBottomSheetState();
}

class CommentsBottomSheetState extends ConsumerState<_CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch comments when bottom sheet is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentProvider(widget.postId).notifier).fetchComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    // Clear comments when bottom sheet is closed
    ref.read(commentProvider(widget.postId).notifier).clearComments();
    super.dispose();
  }

  void _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final authState = ref.read(authProvider);
    final userEmail = authState.user?.email;

    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment')),
      );
      return;
    }

    try {
      await ref.read(commentProvider(widget.postId).notifier).addComment(
        postId: widget.postId,
        commentText: commentText,
        userEmail: userEmail,
      );
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final commentState = ref.watch(commentProvider(widget.postId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header with Back Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close bottom sheet
                },
              ),
              Text(
                'Comments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 48), // Placeholder for symmetry
            ],
          ),

          const SizedBox(height: 16),

          // Comments List
          Expanded(
            child: commentState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : commentState.comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: commentState.comments.length,
                        itemBuilder: (context, index) {
                          final comment = commentState.comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: comment.userProfileImage.isNotEmpty
                                  ? NetworkImage(comment.userProfileImage)
                                  : null,
                              child: comment.userProfileImage.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              comment.userName,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              comment.commentText,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            trailing: Text(
                              DateFormat('MMM d, HH:mm').format(comment.createdAt),
                              style: TextStyle(
                                color: isDarkMode ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Comment Input
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}