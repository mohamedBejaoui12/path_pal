import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pfe1/features/authentication/data/comment_provider.dart';
import 'package:pfe1/features/business/data/business_comment_provider.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import '../domain/comment_model.dart';

enum CommentType {
  userPost,
  businessPost,
}

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final int postId;
  final CommentType commentType;

  const CommentsBottomSheet({
    Key? key, 
    required this.postId, 
    this.commentType = CommentType.userPost
  }) : super(key: key);

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
        ref.read(commentProvider(widget.postId).notifier).fetchComments(widget.postId);
        break;
      case CommentType.businessPost:
        ref.read(businessPostCommentProvider(widget.postId).notifier).fetchComments(widget.postId);
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
              ref.read(businessPostCommentProvider(widget.postId).notifier).addComment(
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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Comments Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Comments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${comments.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
              height: 1,
            ),

            // Comments List
            Expanded(
              child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  )
                : comments.isEmpty
                  ? Center(
                      child: Text(
                        'No comments yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return _CommentTile(comment: comment);
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

  const _CommentTile({Key? key, required this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formattedDate = DateFormat('MMM d, HH:mm').format(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture
          CircleAvatar(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.userName.isNotEmpty ? comment.userName : 'Anonymous',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.commentText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 10,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              Icons.send,
              color: AppColors.primaryColor,
            ),
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

// Function to show comments bottom sheet
void showCommentsBottomSheet(
  BuildContext context, 
  int postId, 
  {CommentType commentType = CommentType.userPost}
) {
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