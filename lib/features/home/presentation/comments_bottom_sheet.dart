import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pfe1/features/authentication/data/comment_provider.dart';
import 'package:pfe1/features/business/data/business_comment_provider.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import '../domain/comment_model.dart';

enum CommentType {
  userPost,
  businessPost,
}

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final int postId;
  final CommentType commentType;

  const CommentsBottomSheet(
      {Key? key, required this.postId, this.commentType = CommentType.userPost})
      : super(key: key);

  @override
  _CommentsBottomSheetState createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch comments when the bottom sheet is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchComments();
    });
  }

  void _fetchComments() {
    switch (widget.commentType) {
      case CommentType.userPost:
        ref
            .read(commentProvider(widget.postId).notifier)
            .fetchComments(widget.postId);
        break;
      case CommentType.businessPost:
        ref
            .read(businessPostCommentProvider(widget.postId).notifier)
            .fetchComments(widget.postId);
        break;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;

      if (userEmail != null) {
        try {
          switch (widget.commentType) {
            case CommentType.userPost:
              ref.read(commentProvider(widget.postId).notifier).addComment(
                    postId: widget.postId,
                    commentText: commentText,
                    userEmail: userEmail,
                  );
              break;
            case CommentType.businessPost:
              ref
                  .read(businessPostCommentProvider(widget.postId).notifier)
                  .addComment(
                    businessPostId: widget.postId,
                    commentText: commentText,
                  );
              break;
          }
          _commentController.clear();
          _scrollToBottom();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add comment: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to comment'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Create a dynamic state object based on comment type
    dynamic commentState;
    List<CommentModel> comments = [];
    bool isLoading = false;

    switch (widget.commentType) {
      case CommentType.userPost:
        commentState = ref.watch(commentProvider(widget.postId));
        comments = commentState.comments;
        isLoading = commentState.isLoading;
        break;
      case CommentType.businessPost:
        commentState = ref.watch(businessPostCommentProvider(widget.postId));
        comments = commentState.comments;
        isLoading = commentState.isLoading;
        break;
    }

    final isDarkMode = ref.watch(themeProvider);
    return DraggableScrollableSheet(
      initialChildSize: 1.0, // Take full available space in the container
      minChildSize: 1.0, // Don't allow shrinking
      maxChildSize: 1.0, // Don't allow expanding
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Comments Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${comments.length}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
              height: 1,
              thickness: 1,
            ),

            // Comments List
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDarkMode
                            ? Colors.white70
                            : AppColors.primaryColor,
                      ),
                    )
                  : comments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 50,
                                color: isDarkMode
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to comment!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: comments.length,
                          separatorBuilder: (context, index) => Divider(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            height: 1,
                            indent: 70,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return _CommentTile(
                              comment: comment,
                              isDarkMode: isDarkMode,
                            );
                          },
                        ),
            ),

            // Comment Input
            _CommentInputField(
              controller: _commentController,
              onSubmit: _submitComment,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isDarkMode;

  const _CommentTile({
    Key? key,
    required this.comment,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, HH:mm').format(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              backgroundImage: comment.userProfileImage.isNotEmpty
                  ? NetworkImage(comment.userProfileImage)
                  : null,
              child: comment.userProfileImage.isEmpty
                  ? Text(
                      comment.userName.isNotEmpty
                          ? comment.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName.isNotEmpty
                          ? comment.userName
                          : 'Anonymous',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    comment.commentText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isDarkMode;

  const _CommentInputField({
    Key? key,
    required this.controller,
    required this.onSubmit,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 24,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
              ),
              onPressed: onSubmit,
            ),
          ), // Added closing bracket here
        ],
      ),
    );
  }
}

// Function to show comments bottom sheet
void showCommentsBottomSheet(BuildContext context, int postId,
    {CommentType commentType = CommentType.userPost}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => CommentsBottomSheet(
      postId: postId,
      commentType: commentType,
    ),
  );
}
