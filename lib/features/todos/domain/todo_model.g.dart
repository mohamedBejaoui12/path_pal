// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoImpl _$$TodoImplFromJson(Map<String, dynamic> json) => _$TodoImpl(
      id: json['id'] as String?,
      userEmail: json['user_email'] as String,
      text: json['text'] as String,
      emoji: json['emoji'] as String?,
      category: $enumDecode(_$TodoCategoryEnumMap, json['category']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
    );

Map<String, dynamic> _$$TodoImplToJson(_$TodoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_email': instance.userEmail,
      'text': instance.text,
      'emoji': instance.emoji,
      'category': _$TodoCategoryEnumMap[instance.category]!,
      'created_at': instance.createdAt?.toIso8601String(),
      'is_completed': instance.isCompleted,
    };

const _$TodoCategoryEnumMap = {
  TodoCategory.Food: 'Food',
  TodoCategory.Places: 'Places',
  TodoCategory.Standard: 'Standard',
};
