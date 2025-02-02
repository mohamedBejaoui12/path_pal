import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_model.freezed.dart';

@freezed
class PostModel with _$PostModel {
  const factory PostModel({
    int? id,
    @JsonKey(name: 'user_email') required String userEmail,
    required String title,
    String? description,
    @JsonKey(name: 'image_link') String? imageUrl,
    @Default([]) List<String> interests,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _PostModel;

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int?,
      userEmail: (json['user_email'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      imageUrl: json['image_link'] as String?,
      interests: (json['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null 
        ? DateTime.tryParse(json['created_at'].toString()) 
        : null,
    );
  }


}