import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_model.freezed.dart';

@freezed
class PostModel with _$PostModel {
  const factory PostModel({
    int? id,
    required String userEmail,
    required String userName,
    String? userProfileImage,
    required String title,
    String? description,
    String? imageUrl,
    @Default([]) List<String> interests,
    DateTime? createdAt,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    @Default(false) bool isLikedByCurrentUser,
  }) = _PostModel;

 factory PostModel.fromJson(Map<String, dynamic> json) {
  // Safely extract user data
  final userData = json['user'] is Map ? json['user'] : {};

  // Combine name and family name
  final name = userData['name'] ?? '';
  final familyName = userData['family_name'] ?? '';
  final fullName = '$name $familyName'.trim();

  return PostModel(
    id: json['id'] as int?,
    userEmail: (json['user_email'] ?? '').toString(),
    userName: fullName.isNotEmpty ? fullName : 'Anonymous',
    userProfileImage: userData['profile_image_url'] ?? 
      _generateDefaultProfileImage(fullName),
    title: (json['title'] ?? '').toString(),
    description: json['description'] as String?,
    imageUrl: json['image_link'] as String?,
    interests: (json['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
    createdAt: json['created_at'] != null 
      ? DateTime.tryParse(json['created_at'].toString()) 
      : null,
    likesCount: json['likes_count'] as int? ?? 0,
    commentsCount: json['comments_count'] as int? ?? 0,
    isLikedByCurrentUser: json['is_liked_by_current_user'] as bool? ?? false,
  );
}

// Helper method for default avatar
static String _generateDefaultProfileImage(String name) {
  return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff&size=200';
}
  
}