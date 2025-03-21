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
    @Default(false) bool isUserVerified,
  }) = _PostModel;

  // Helper method for default avatar
  static String _generateDefaultProfileImage(String name) {
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff&size=200';
  }

  // Modify fromJson to handle more complex data structures
  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Handle user data extraction
    dynamic userData;
    if (json['user'] is List && json['user'].isNotEmpty) {
      userData = json['user'][0];
    } else if (json['user'] is Map) {
      userData = json['user'];
    } else {
      userData = {};
    }

    // Extract name safely
    final name = userData['name'] ?? '';
    final familyName = userData['family_name'] ?? '';
    final fullName = '$name $familyName'.trim();

    // Handle likes count
    int likesCount = 0;
    bool isLikedByCurrentUser = false;

    // Check if post_likes exists and is a list
    if (json['post_likes'] is List) {
      final postLikes = json['post_likes'] as List;
      likesCount = postLikes.length;

      // Determine if liked by current user
      final currentUserEmail = json['current_user_email'];
      if (currentUserEmail != null) {
        isLikedByCurrentUser =
            postLikes.any((like) => like['user_email'] == currentUserEmail);
      } else {
        isLikedByCurrentUser = json['is_liked_by_current_user'] ?? false;
      }
    } else {
      likesCount = json['likes_count'] ?? 0;
      isLikedByCurrentUser = json['is_liked_by_current_user'] ?? false;
    }

    // Get verification status - check both possible sources
    bool isVerified = false;
    if (json['is_user_verified'] == true) {
      isVerified = true;
    } else if (userData['is_verified'] == true) {
      isVerified = true;
    }

    return PostModel(
      id: json['id'] as int?,
      userEmail: (json['user_email'] ?? '').toString(),
      userName: fullName.isNotEmpty ? fullName : 'Anonymous',
      userProfileImage: userData['profile_image_url'] ??
          _generateDefaultProfileImage(fullName),
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      imageUrl: json['image_link'] != null
          ? json['image_link'] as String?
          : (json['image_url'] != null ? json['image_url'] as String? : null),
      interests:
          (json['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      likesCount: likesCount,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLikedByCurrentUser: isLikedByCurrentUser,
      isUserVerified: isVerified,
    );
  }
}
