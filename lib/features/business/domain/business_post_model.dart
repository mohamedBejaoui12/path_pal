import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_post_model.freezed.dart';
part 'business_post_model.g.dart';

@freezed
class BusinessPostModel with _$BusinessPostModel {
  const factory BusinessPostModel({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'business_id') required int businessId,
    @JsonKey(name: 'user_email') required String userEmail,
    @JsonKey(name: 'business_name') required String businessName,
    @JsonKey(name: 'business_profile_image') String? businessProfileImage,
    required String title,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @Default([]) List<String> interests,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    @Default(false) bool isLikedByCurrentUser,
  }) = _BusinessPostModel;

  factory BusinessPostModel.fromJson(Map<String, dynamic> json) => 
      _$BusinessPostModelFromJson(json);
}