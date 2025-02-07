import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

part 'todo_model.freezed.dart';
part 'todo_model.g.dart';

enum TodoCategory { Food, Places, Standard }

@freezed
class Todo with _$Todo {
  const factory Todo({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'user_email') required String userEmail,
    required String text,
    String? emoji,
    @JsonKey(name: 'category') required TodoCategory category,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);

  // Factory method to create a new todo with a generated UUID
  factory Todo.create({
    required String userEmail,
    required String text,
    TodoCategory category = TodoCategory.Standard,
    String? emoji,
    bool isCompleted = false,
  }) => Todo(
    id: const Uuid().v4(),
    userEmail: userEmail,
    text: text,
    category: category,
    emoji: emoji,
    createdAt: DateTime.now(),
    isCompleted: isCompleted,
  );
}