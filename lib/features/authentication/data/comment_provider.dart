import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/home/domain/comment_model.dart';
import './comment_service.dart';

class CommentState {
  final List<CommentModel> comments;
  final bool isLoading;
  final String? error;

  CommentState({
    this.comments = const [],
    this.isLoading = false,
    this.error,
  });

  CommentState copyWith({
    List<CommentModel>? comments,
    bool? isLoading,
    String? error,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CommentNotifier extends StateNotifier<CommentState> {
  final Ref ref;
  final CommentService _commentService;
  
  // Cache to store comments for different posts
  final Map<int, List<CommentModel>> _commentCache = {};

  CommentNotifier(this.ref, this._commentService) : super(CommentState());

  Future<void> fetchComments(int postId) async {
    try {
      // Check cache first
      if (_commentCache.containsKey(postId) && _commentCache[postId]!.isNotEmpty) {
        state = state.copyWith(
          comments: _commentCache[postId]!,
          isLoading: false,
        );
        return;
      }

      state = state.copyWith(isLoading: true);
      final comments = await _commentService.fetchComments(postId);
      
      // Update cache
      _commentCache[postId] = comments;

      state = state.copyWith(
        comments: comments, 
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> addComment({
    required int postId, 
    required String commentText,
    required String userEmail,
  }) async {
    try {
      final newComment = await _commentService.addComment(
        postId: postId, 
        commentText: commentText, 
        userEmail: userEmail,
      );
      
      // Update cache
      if (!_commentCache.containsKey(postId)) {
        _commentCache[postId] = [];
      }
      _commentCache[postId]!.insert(0, newComment);

      // Update state
      state = state.copyWith(
        comments: _commentCache[postId]!,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  // Method to clear comments when bottom sheet is closed
  void clearComments() {
    state = CommentState();
  }
}

final commentProvider = StateNotifierProvider.family<CommentNotifier, CommentState, int>((ref, postId) {
  final commentService = ref.read(commentServiceProvider);
  return CommentNotifier(ref, commentService);
});