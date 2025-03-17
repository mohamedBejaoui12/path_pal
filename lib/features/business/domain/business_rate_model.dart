

class BusinessRateModel {
  final int? id;
  final int businessId;
  final String userEmail;
  final String? userName;
  final String? userProfileImage;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  BusinessRateModel({
    this.id,
    required this.businessId,
    required this.userEmail,
    this.userName,
    this.userProfileImage,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory BusinessRateModel.fromJson(Map<String, dynamic> json) {
    return BusinessRateModel(
      id: json['id'],
      businessId: json['business_id'],
      userEmail: json['user_email'],
      userName: json['user_name'],
      userProfileImage: json['user_profile_image'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'user_email': userEmail,
      'user_name': userName,
      'user_profile_image': userProfileImage,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  BusinessRateModel copyWith({
    int? id,
    int? businessId,
    String? userEmail,
    String? userName,
    String? userProfileImage,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return BusinessRateModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'BusinessRateModel(id: $id, businessId: $businessId, userEmail: $userEmail, rating: $rating, comment: $comment, createdAt: $createdAt)';
  }
}