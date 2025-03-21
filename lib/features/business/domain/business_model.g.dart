// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BusinessModelImpl _$$BusinessModelImplFromJson(Map<String, dynamic> json) =>
    _$BusinessModelImpl(
      id: (json['id'] as num).toInt(),
      businessName: json['business_name'] as String,
      email: json['email'] as String,
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      userEmail: json['user_email'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
    );

Map<String, dynamic> _$$BusinessModelImplToJson(_$BusinessModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'business_name': instance.businessName,
      'email': instance.email,
      'image_url': instance.imageUrl,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'user_email': instance.userEmail,
      'created_at': instance.createdAt?.toIso8601String(),
      'isVerified': instance.isVerified,
    };
