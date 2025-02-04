// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentModelImpl _$$CommentModelImplFromJson(Map<String, dynamic> json) =>
    _$CommentModelImpl(
      id: (json['id'] as num?)?.toInt(),
      userEmail: json['userEmail'] as String,
      userName: json['userName'] as String,
      userProfileImage: json['userProfileImage'] as String,
      commentText: json['commentText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      postId: (json['postId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$CommentModelImplToJson(_$CommentModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userEmail': instance.userEmail,
      'userName': instance.userName,
      'userProfileImage': instance.userProfileImage,
      'commentText': instance.commentText,
      'createdAt': instance.createdAt.toIso8601String(),
      'postId': instance.postId,
    };
