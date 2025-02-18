// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_post_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BusinessPostModel _$BusinessPostModelFromJson(Map<String, dynamic> json) {
  return _BusinessPostModel.fromJson(json);
}

/// @nodoc
mixin _$BusinessPostModel {
  @JsonKey(name: 'id')
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'business_id')
  int get businessId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_email')
  String get userEmail => throw _privateConstructorUsedError;
  @JsonKey(name: 'business_name')
  String get businessName => throw _privateConstructorUsedError;
  @JsonKey(name: 'business_profile_image')
  String? get businessProfileImage => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  List<String> get interests => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  int get likesCount => throw _privateConstructorUsedError;
  int get commentsCount => throw _privateConstructorUsedError;
  bool get isLikedByCurrentUser => throw _privateConstructorUsedError;

  /// Serializes this BusinessPostModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BusinessPostModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BusinessPostModelCopyWith<BusinessPostModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusinessPostModelCopyWith<$Res> {
  factory $BusinessPostModelCopyWith(
          BusinessPostModel value, $Res Function(BusinessPostModel) then) =
      _$BusinessPostModelCopyWithImpl<$Res, BusinessPostModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int? id,
      @JsonKey(name: 'business_id') int businessId,
      @JsonKey(name: 'user_email') String userEmail,
      @JsonKey(name: 'business_name') String businessName,
      @JsonKey(name: 'business_profile_image') String? businessProfileImage,
      String title,
      String? description,
      @JsonKey(name: 'image_url') String? imageUrl,
      List<String> interests,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      int likesCount,
      int commentsCount,
      bool isLikedByCurrentUser});
}

/// @nodoc
class _$BusinessPostModelCopyWithImpl<$Res, $Val extends BusinessPostModel>
    implements $BusinessPostModelCopyWith<$Res> {
  _$BusinessPostModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusinessPostModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? businessId = null,
    Object? userEmail = null,
    Object? businessName = null,
    Object? businessProfileImage = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? interests = null,
    Object? createdAt = freezed,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? isLikedByCurrentUser = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as int,
      userEmail: null == userEmail
          ? _value.userEmail
          : userEmail // ignore: cast_nullable_to_non_nullable
              as String,
      businessName: null == businessName
          ? _value.businessName
          : businessName // ignore: cast_nullable_to_non_nullable
              as String,
      businessProfileImage: freezed == businessProfileImage
          ? _value.businessProfileImage
          : businessProfileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      interests: null == interests
          ? _value.interests
          : interests // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentsCount: null == commentsCount
          ? _value.commentsCount
          : commentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      isLikedByCurrentUser: null == isLikedByCurrentUser
          ? _value.isLikedByCurrentUser
          : isLikedByCurrentUser // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BusinessPostModelImplCopyWith<$Res>
    implements $BusinessPostModelCopyWith<$Res> {
  factory _$$BusinessPostModelImplCopyWith(_$BusinessPostModelImpl value,
          $Res Function(_$BusinessPostModelImpl) then) =
      __$$BusinessPostModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int? id,
      @JsonKey(name: 'business_id') int businessId,
      @JsonKey(name: 'user_email') String userEmail,
      @JsonKey(name: 'business_name') String businessName,
      @JsonKey(name: 'business_profile_image') String? businessProfileImage,
      String title,
      String? description,
      @JsonKey(name: 'image_url') String? imageUrl,
      List<String> interests,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      int likesCount,
      int commentsCount,
      bool isLikedByCurrentUser});
}

/// @nodoc
class __$$BusinessPostModelImplCopyWithImpl<$Res>
    extends _$BusinessPostModelCopyWithImpl<$Res, _$BusinessPostModelImpl>
    implements _$$BusinessPostModelImplCopyWith<$Res> {
  __$$BusinessPostModelImplCopyWithImpl(_$BusinessPostModelImpl _value,
      $Res Function(_$BusinessPostModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of BusinessPostModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? businessId = null,
    Object? userEmail = null,
    Object? businessName = null,
    Object? businessProfileImage = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? interests = null,
    Object? createdAt = freezed,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? isLikedByCurrentUser = null,
  }) {
    return _then(_$BusinessPostModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as int,
      userEmail: null == userEmail
          ? _value.userEmail
          : userEmail // ignore: cast_nullable_to_non_nullable
              as String,
      businessName: null == businessName
          ? _value.businessName
          : businessName // ignore: cast_nullable_to_non_nullable
              as String,
      businessProfileImage: freezed == businessProfileImage
          ? _value.businessProfileImage
          : businessProfileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      interests: null == interests
          ? _value._interests
          : interests // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentsCount: null == commentsCount
          ? _value.commentsCount
          : commentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      isLikedByCurrentUser: null == isLikedByCurrentUser
          ? _value.isLikedByCurrentUser
          : isLikedByCurrentUser // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BusinessPostModelImpl implements _BusinessPostModel {
  const _$BusinessPostModelImpl(
      {@JsonKey(name: 'id') this.id,
      @JsonKey(name: 'business_id') required this.businessId,
      @JsonKey(name: 'user_email') required this.userEmail,
      @JsonKey(name: 'business_name') required this.businessName,
      @JsonKey(name: 'business_profile_image') this.businessProfileImage,
      required this.title,
      this.description,
      @JsonKey(name: 'image_url') this.imageUrl,
      final List<String> interests = const [],
      @JsonKey(name: 'created_at') this.createdAt,
      this.likesCount = 0,
      this.commentsCount = 0,
      this.isLikedByCurrentUser = false})
      : _interests = interests;

  factory _$BusinessPostModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BusinessPostModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int? id;
  @override
  @JsonKey(name: 'business_id')
  final int businessId;
  @override
  @JsonKey(name: 'user_email')
  final String userEmail;
  @override
  @JsonKey(name: 'business_name')
  final String businessName;
  @override
  @JsonKey(name: 'business_profile_image')
  final String? businessProfileImage;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final List<String> _interests;
  @override
  @JsonKey()
  List<String> get interests {
    if (_interests is EqualUnmodifiableListView) return _interests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_interests);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey()
  final int likesCount;
  @override
  @JsonKey()
  final int commentsCount;
  @override
  @JsonKey()
  final bool isLikedByCurrentUser;

  @override
  String toString() {
    return 'BusinessPostModel(id: $id, businessId: $businessId, userEmail: $userEmail, businessName: $businessName, businessProfileImage: $businessProfileImage, title: $title, description: $description, imageUrl: $imageUrl, interests: $interests, createdAt: $createdAt, likesCount: $likesCount, commentsCount: $commentsCount, isLikedByCurrentUser: $isLikedByCurrentUser)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusinessPostModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.userEmail, userEmail) ||
                other.userEmail == userEmail) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.businessProfileImage, businessProfileImage) ||
                other.businessProfileImage == businessProfileImage) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality()
                .equals(other._interests, _interests) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.commentsCount, commentsCount) ||
                other.commentsCount == commentsCount) &&
            (identical(other.isLikedByCurrentUser, isLikedByCurrentUser) ||
                other.isLikedByCurrentUser == isLikedByCurrentUser));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      businessId,
      userEmail,
      businessName,
      businessProfileImage,
      title,
      description,
      imageUrl,
      const DeepCollectionEquality().hash(_interests),
      createdAt,
      likesCount,
      commentsCount,
      isLikedByCurrentUser);

  /// Create a copy of BusinessPostModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusinessPostModelImplCopyWith<_$BusinessPostModelImpl> get copyWith =>
      __$$BusinessPostModelImplCopyWithImpl<_$BusinessPostModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BusinessPostModelImplToJson(
      this,
    );
  }
}

abstract class _BusinessPostModel implements BusinessPostModel {
  const factory _BusinessPostModel(
      {@JsonKey(name: 'id') final int? id,
      @JsonKey(name: 'business_id') required final int businessId,
      @JsonKey(name: 'user_email') required final String userEmail,
      @JsonKey(name: 'business_name') required final String businessName,
      @JsonKey(name: 'business_profile_image')
      final String? businessProfileImage,
      required final String title,
      final String? description,
      @JsonKey(name: 'image_url') final String? imageUrl,
      final List<String> interests,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      final int likesCount,
      final int commentsCount,
      final bool isLikedByCurrentUser}) = _$BusinessPostModelImpl;

  factory _BusinessPostModel.fromJson(Map<String, dynamic> json) =
      _$BusinessPostModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int? get id;
  @override
  @JsonKey(name: 'business_id')
  int get businessId;
  @override
  @JsonKey(name: 'user_email')
  String get userEmail;
  @override
  @JsonKey(name: 'business_name')
  String get businessName;
  @override
  @JsonKey(name: 'business_profile_image')
  String? get businessProfileImage;
  @override
  String get title;
  @override
  String? get description;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  List<String> get interests;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  int get likesCount;
  @override
  int get commentsCount;
  @override
  bool get isLikedByCurrentUser;

  /// Create a copy of BusinessPostModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusinessPostModelImplCopyWith<_$BusinessPostModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
