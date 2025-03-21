import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_details_model.freezed.dart';
part 'user_details_model.g.dart';

enum Gender { male, female }

@freezed
class UserDetailsModel with _$UserDetailsModel {
  const factory UserDetailsModel({
    required String name,
    required String email,
    required String familyName,
    String? profileImageUrl,
    String? description,
    required DateTime dateOfBirth,
    required String cityOfBirth,
    required String phoneNumber,
    required Gender gender,
    @Default(false) bool isVerified, // This field should be present
  }) = _UserDetailsModel;

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsModelFromJson(json);
}
