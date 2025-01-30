// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserDetailsModelImpl _$$UserDetailsModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserDetailsModelImpl(
      name: json['name'] as String,
      familyName: json['familyName'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      phoneNumber: json['phoneNumber'] as String,
      cityOfBirth: json['cityOfBirth'] as String,
      gender: $enumDecode(_$GenderEnumMap, json['gender']),
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );

Map<String, dynamic> _$$UserDetailsModelImplToJson(
        _$UserDetailsModelImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'familyName': instance.familyName,
      'dateOfBirth': instance.dateOfBirth.toIso8601String(),
      'phoneNumber': instance.phoneNumber,
      'cityOfBirth': instance.cityOfBirth,
      'gender': _$GenderEnumMap[instance.gender]!,
      'email': instance.email,
      'profileImageUrl': instance.profileImageUrl,
    };

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
};
