import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/todo_model.dart';

class TodoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all todos for a user in real-time
  Stream<List<Todo>> watchAllTodos(String userEmail) {
    return _supabase
        .from('todos')
        .stream(primaryKey: ['id'])
        .eq('user_email', userEmail)
        .map((event) => 
          event.map((json) => Todo.fromJson(json)).toList()
        );
  }

  Future<List<Todo>> getTodosByCategory(String userEmail, TodoCategory category) async {
    final response = await _supabase
        .from('todos')
        .select()
        .eq('user_email', userEmail)
        .eq('category', category.name)
        .order('created_at');

    return response.map((json) => Todo.fromJson(json)).toList();
  }

  Future<Todo> addTodo(Todo todo) async {
    final todoToInsert = todo.id == null ? Todo.create(
      userEmail: todo.userEmail,
      text: todo.text,
      category: todo.category,
      emoji: todo.emoji,
      isCompleted: todo.isCompleted,
    ) : todo;

    final response = await _supabase
        .from('todos')
        .insert(todoToInsert.toJson())
        .select()
        .single();

    return Todo.fromJson(response);
  }

  Future<void> updateTodo(Todo todo) async {
    await _supabase
        .from('todos')
        .update(todo.toJson())
        .eq('id', todo.id as Object);
  }

  Future<void> deleteTodo(String todoId) async {
    await _supabase
        .from('todos')
        .delete()
        .eq('id', todoId);
  }
}