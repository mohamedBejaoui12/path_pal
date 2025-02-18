// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BusinessPostModelImpl _$$BusinessPostModelImplFromJson(
        Map<String, dynamic> json) =>
    _$BusinessPostModelImpl(
      id: (json['id'] as num?)?.toInt(),
      businessId: (json['business_id'] as num).toInt(),
      userEmail: json['user_email'] as String,
      businessName: json['business_name'] as String,
      businessProfileImage: json['business_profile_image'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
    );

Map<String, dynamic> _$$BusinessPostModelImplToJson(
        _$BusinessPostModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'business_id': instance.businessId,
      'user_email': instance.userEmail,
      'business_name': instance.businessName,
      'business_profile_image': instance.businessProfileImage,
      'title': instance.title,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'interests': instance.interests,
      'created_at': instance.createdAt?.toIso8601String(),
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'isLikedByCurrentUser': instance.isLikedByCurrentUser,
    };
