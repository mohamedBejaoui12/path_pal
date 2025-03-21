// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PostModel {
  int? get id => throw _privateConstructorUsedError;
  String get userEmail => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  String? get userProfileImage => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  List<String> get interests => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  int get likesCount => throw _privateConstructorUsedError;
  int get commentsCount => throw _privateConstructorUsedError;
  bool get isLikedByCurrentUser => throw _privateConstructorUsedError;
  bool get isUserVerified => throw _privateConstructorUsedError;

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostModelCopyWith<PostModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostModelCopyWith<$Res> {
  factory $PostModelCopyWith(PostModel value, $Res Function(PostModel) then) =
      _$PostModelCopyWithImpl<$Res, PostModel>;
  @useResult
  $Res call(
      {int? id,
      String userEmail,
      String userName,
      String? userProfileImage,
      String title,
      String? description,
      String? imageUrl,
      List<String> interests,
      DateTime? createdAt,
      int likesCount,
      int commentsCount,
      bool isLikedByCurrentUser,
      bool isUserVerified});
}

/// @nodoc
class _$PostModelCopyWithImpl<$Res, $Val extends PostModel>
    implements $PostModelCopyWith<$Res> {
  _$PostModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userEmail = null,
    Object? userName = null,
    Object? userProfileImage = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? interests = null,
    Object? createdAt = freezed,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? isLikedByCurrentUser = null,
    Object? isUserVerified = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      userEmail: null == userEmail
          ? _value.userEmail
          : userEmail // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      userProfileImage: freezed == userProfileImage
          ? _value.userProfileImage
          : userProfileImage // ignore: cast_nullable_to_non_nullable
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
      isUserVerified: null == isUserVerified
          ? _value.isUserVerified
          : isUserVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PostModelImplCopyWith<$Res>
    implements $PostModelCopyWith<$Res> {
  factory _$$PostModelImplCopyWith(
          _$PostModelImpl value, $Res Function(_$PostModelImpl) then) =
      __$$PostModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      String userEmail,
      String userName,
      String? userProfileImage,
      String title,
      String? description,
      String? imageUrl,
      List<String> interests,
      DateTime? createdAt,
      int likesCount,
      int commentsCount,
      bool isLikedByCurrentUser,
      bool isUserVerified});
}

/// @nodoc
class __$$PostModelImplCopyWithImpl<$Res>
    extends _$PostModelCopyWithImpl<$Res, _$PostModelImpl>
    implements _$$PostModelImplCopyWith<$Res> {
  __$$PostModelImplCopyWithImpl(
      _$PostModelImpl _value, $Res Function(_$PostModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userEmail = null,
    Object? userName = null,
    Object? userProfileImage = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? interests = null,
    Object? createdAt = freezed,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? isLikedByCurrentUser = null,
    Object? isUserVerified = null,
  }) {
    return _then(_$PostModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      userEmail: null == userEmail
          ? _value.userEmail
          : userEmail // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      userProfileImage: freezed == userProfileImage
          ? _value.userProfileImage
          : userProfileImage // ignore: cast_nullable_to_non_nullable
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
      isUserVerified: null == isUserVerified
          ? _value.isUserVerified
          : isUserVerified // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$PostModelImpl implements _PostModel {
  const _$PostModelImpl(
      {this.id,
      required this.userEmail,
      required this.userName,
      this.userProfileImage,
      required this.title,
      this.description,
      this.imageUrl,
      final List<String> interests = const [],
      this.createdAt,
      this.likesCount = 0,
      this.commentsCount = 0,
      this.isLikedByCurrentUser = false,
      this.isUserVerified = false})
      : _interests = interests;

  @override
  final int? id;
  @override
  final String userEmail;
  @override
  final String userName;
  @override
  final String? userProfileImage;
  @override
  final String title;
  @override
  final String? description;
  @override
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
  @JsonKey()
  final bool isUserVerified;

  @override
  String toString() {
    return 'PostModel(id: $id, userEmail: $userEmail, userName: $userName, userProfileImage: $userProfileImage, title: $title, description: $description, imageUrl: $imageUrl, interests: $interests, createdAt: $createdAt, likesCount: $likesCount, commentsCount: $commentsCount, isLikedByCurrentUser: $isLikedByCurrentUser, isUserVerified: $isUserVerified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userEmail, userEmail) ||
                other.userEmail == userEmail) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userProfileImage, userProfileImage) ||
                other.userProfileImage == userProfileImage) &&
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
                other.isLikedByCurrentUser == isLikedByCurrentUser) &&
            (identical(other.isUserVerified, isUserVerified) ||
                other.isUserVerified == isUserVerified));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userEmail,
      userName,
      userProfileImage,
      title,
      description,
      imageUrl,
      const DeepCollectionEquality().hash(_interests),
      createdAt,
      likesCount,
      commentsCount,
      isLikedByCurrentUser,
      isUserVerified);

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostModelImplCopyWith<_$PostModelImpl> get copyWith =>
      __$$PostModelImplCopyWithImpl<_$PostModelImpl>(this, _$identity);
}

abstract class _PostModel implements PostModel {
  const factory _PostModel(
      {final int? id,
      required final String userEmail,
      required final String userName,
      final String? userProfileImage,
      required final String title,
      final String? description,
      final String? imageUrl,
      final List<String> interests,
      final DateTime? createdAt,
      final int likesCount,
      final int commentsCount,
      final bool isLikedByCurrentUser,
      final bool isUserVerified}) = _$PostModelImpl;

  @override
  int? get id;
  @override
  String get userEmail;
  @override
  String get userName;
  @override
  String? get userProfileImage;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get imageUrl;
  @override
  List<String> get interests;
  @override
  DateTime? get createdAt;
  @override
  int get likesCount;
  @override
  int get commentsCount;
  @override
  bool get isLikedByCurrentUser;
  @override
  bool get isUserVerified;

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostModelImplCopyWith<_$PostModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
