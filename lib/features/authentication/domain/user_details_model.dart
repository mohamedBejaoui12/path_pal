import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_details_model.freezed.dart';
part 'user_details_model.g.dart';

enum Gender { male, female }

@freezed
class UserDetailsModel with _$UserDetailsModel {
  const factory UserDetailsModel({
    required String name,
    required String familyName,
    required DateTime dateOfBirth,
    required String phoneNumber,
    required String cityOfBirth,
    required Gender gender,
    required String email,
  }) = _UserDetailsModel;

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) => 
      _$UserDetailsModelFromJson(json);
}