// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserDetailsModelImpl _$$UserDetailsModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserDetailsModelImpl(
      name: json['name'] as String,
      email: json['email'] as String,
      familyName: json['familyName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      description: json['description'] as String?,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      cityOfBirth: json['cityOfBirth'] as String,
      phoneNumber: json['phoneNumber'] as String,
      gender: $enumDecode(_$GenderEnumMap, json['gender']),
      isVerified: json['isVerified'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserDetailsModelImplToJson(
        _$UserDetailsModelImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'familyName': instance.familyName,
      'profileImageUrl': instance.profileImageUrl,
      'description': instance.description,
      'dateOfBirth': instance.dateOfBirth.toIso8601String(),
      'cityOfBirth': instance.cityOfBirth,
      'phoneNumber': instance.phoneNumber,
      'gender': _$GenderEnumMap[instance.gender]!,
      'isVerified': instance.isVerified,
    };

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
};
