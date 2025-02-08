import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/todo_model.dart';
import '../data/todo_service.dart';

final todoServiceProvider = Provider((ref) => TodoService());

final todosProvider = StateNotifierProvider<TodosNotifier, Map<TodoCategory, List<Todo>>>((ref) {
  final service = ref.watch(todoServiceProvider);
  return TodosNotifier(service);
});

class TodosNotifier extends StateNotifier<Map<TodoCategory, List<Todo>>> {
  final TodoService _service;
  StreamSubscription? _subscription;

  TodosNotifier(this._service) : super({
    TodoCategory.Food: [],
    TodoCategory.Places: [],
    TodoCategory.Standard: [],
  });

  Future<void> loadTodos(String userEmail) async {
    // Cancel existing subscription
    _subscription?.cancel();

    // Set up real-time subscription for all todos
    _subscription = _service
        .watchAllTodos(userEmail)
        .listen((allTodos) {
      // Categorize todos
      state = {
        TodoCategory.Food: allTodos.where((todo) => todo.category == TodoCategory.Food).toList(),
        TodoCategory.Places: allTodos.where((todo) => todo.category == TodoCategory.Places).toList(),
        TodoCategory.Standard: allTodos.where((todo) => todo.category == TodoCategory.Standard).toList(),
      };
    });
  }

  Future<void> addTodo(Todo todo) async {
    await _service.addTodo(todo);
  }
  

  Future<void> updateTodo(Todo todo) async {
    await _service.updateTodo(todo);
  }

  Future<void> deleteTodo(Todo todo) async {
    await _service.deleteTodo(todo.id!);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

    void updateTodoOrder(TodoCategory category, List<Todo> reorderedTodos) {
    // Update the state for the specific category
    state = {
      ...state,
      category: reorderedTodos,
    };}
}