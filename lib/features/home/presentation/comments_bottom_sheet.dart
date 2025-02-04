import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pfe1/features/authentication/data/comment_provider.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import '../domain/comment_model.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final int postId;

  const CommentsBottomSheet({Key? key, required this.postId}) : super(key: key);

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
      ref.read(commentProvider(widget.postId).notifier).fetchComments(widget.postId);
    });
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
        ref.read(commentProvider(widget.postId).notifier).addComment(
          postId: widget.postId,
          commentText: commentText,
          userEmail: userEmail,
        );

        // Clear the text field and scroll to bottom
        _commentController.clear();
        _scrollToBottom();
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
    final commentState = ref.watch(commentProvider(widget.postId));
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
                  '(${commentState.comments.length})',
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
            child: commentState.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
              : commentState.comments.isEmpty
                ? Center(
                    child: Text(
                      'No comments yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: commentState.comments.length,
                    itemBuilder: (context, index) {
                      final comment = commentState.comments[index];
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
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;

  const _CommentTile({Key? key, required this.comment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
              ? Icon(
                  Icons.person, 
                  size: 20, 
                  color: isDarkMode ? Colors.white : Colors.black45,
                )
              : null,
          ),
          const SizedBox(width: 12),
          
          // Comment Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Name
                  Text(
                    comment.userName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Comment Text
                  Text(
                    comment.commentText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                  ),
                  
                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('MMM d, HH:mm').format(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey.withOpacity(0.2),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
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
void showCommentsBottomSheet(BuildContext context, int postId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => CommentsBottomSheet(
        postId: postId,
      ),
    ),
  );
}