import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

@freezed
class CommentModel with _$CommentModel {
  const factory CommentModel({
    int? id,
    required String userEmail,
    required String userName,
    required String userProfileImage,
    required String commentText,
    required DateTime createdAt,
    int? postId,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) => 
    _$CommentModelFromJson(json);
}