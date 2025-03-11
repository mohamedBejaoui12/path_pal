import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pfe1/features/home/domain/comment_model.dart';
import 'package:pfe1/features/business/data/business_post_comment_service.dart';
import 'package:pfe1/features/authentication/providers/auth_provider.dart';

class BusinessPostCommentState {
  final List<CommentModel> comments;
  final bool isLoading;
  final String? error;

  BusinessPostCommentState({
    this.comments = const [],
    this.isLoading = false,
    this.error,
  });

  BusinessPostCommentState copyWith({
    List<CommentModel>? comments,
    bool? isLoading,
    String? error,
  }) {
    return BusinessPostCommentState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BusinessPostCommentNotifier
    extends StateNotifier<BusinessPostCommentState> {
  final Ref ref;
  final BusinessPostCommentService _commentService;

  // Cache to store comments for different business posts
  final Map<int, List<CommentModel>> _commentCache = {};

  BusinessPostCommentNotifier(this.ref, this._commentService)
      : super(BusinessPostCommentState());

  Future<void> fetchComments(int businessPostId) async {
    try {
      state = state.copyWith(isLoading: true);

      // Check cache first
      if (_commentCache.containsKey(businessPostId) &&
          _commentCache[businessPostId]!.isNotEmpty) {
        state = state.copyWith(
          comments: _commentCache[businessPostId]!,
          isLoading: false,
        );
        return;
      }

      final comments = await _commentService.fetchComments(businessPostId);

      // Update cache
      _commentCache[businessPostId] = comments;

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
    required int businessPostId,
    required String commentText,
  }) async {
    try {
      final authState = ref.read(authProvider);
      final userEmail = authState.user?.email;

      if (userEmail == null) {
        throw Exception('User must be authenticated');
      }

      state = state.copyWith(isLoading: true);

      final newComment = await _commentService.addComment(
        businessPostId: businessPostId,
        commentText: commentText,
        userEmail: userEmail,
      );

      // Update cache
      if (!_commentCache.containsKey(businessPostId)) {
        _commentCache[businessPostId] = [];
      }
      _commentCache[businessPostId]!.insert(0, newComment);

      // Update state
      state = state.copyWith(
        comments: _commentCache[businessPostId]!,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  // Method to clear comments when bottom sheet is closed
  void clearComments() {
    state = BusinessPostCommentState();
  }
}

final businessPostCommentProvider = StateNotifierProvider.family<
    BusinessPostCommentNotifier,
    BusinessPostCommentState,
    int>((ref, businessPostId) {
  final commentService = ref.read(businessPostCommentServiceProvider);
  return BusinessPostCommentNotifier(ref, commentService);
});
