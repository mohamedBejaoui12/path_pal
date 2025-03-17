class VocabularyModel {
  final int? id;
  final String userEmail;
  final String originalWord;
  final String translation;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String languageFrom;
  final String languageTo;

  VocabularyModel({
    this.id,
    required this.userEmail,
    required this.originalWord,
    required this.translation,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.languageFrom = 'en',
    this.languageTo = 'fr',
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    return VocabularyModel(
      id: json['id'],
      userEmail: json['user_email'],
      originalWord: json['original_word'],
      translation: json['translation'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      languageFrom: json['language_from'] ?? 'en',
      languageTo: json['language_to'] ?? 'fr',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_email': userEmail,
      'original_word': originalWord,
      'translation': translation,
      'notes': notes,
      'language_from': languageFrom,
      'language_to': languageTo,
    };
  }

  VocabularyModel copyWith({
    int? id,
    String? userEmail,
    String? originalWord,
    String? translation,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? languageFrom,
    String? languageTo,
  }) {
    return VocabularyModel(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      originalWord: originalWord ?? this.originalWord,
      translation: translation ?? this.translation,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      languageFrom: languageFrom ?? this.languageFrom,
      languageTo: languageTo ?? this.languageTo,
    );
  }

  @override
  String toString() {
    return 'VocabularyModel(id: $id, originalWord: $originalWord, translation: $translation)';
  }
}
