import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/todo_model.dart';
import '../data/todo_provider.dart';

class TodoListWidget extends ConsumerWidget {
  final TodoCategory category;

  const TodoListWidget({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosProvider)[category] ?? [];
    
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return GestureDetector(
          onLongPress: () => _showTodoOptions(context, ref, todo),
          child: CheckboxListTile(
            title: Text(todo.text),
            secondary: Text(todo.emoji ?? ''),
            value: todo.isCompleted,
            onChanged: (value) {
              // Update todo's completed status
              ref.read(todosProvider.notifier).updateTodo(
                todo.copyWith(isCompleted: value ?? false),
              );
            },
          ),
        );
      },
    );
  }

  void _showTodoOptions(BuildContext context, WidgetRef ref, Todo todo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              // Implement edit logic
              _showEditTodoDialog(context, ref, todo);
            },
          ),
          ListTile(
            title: Text('Delete'),
            onTap: () {
              ref.read(todosProvider.notifier).deleteTodo(todo);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditTodoDialog(BuildContext context, WidgetRef ref, Todo todo) {
    final textController = TextEditingController(text: todo.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Todo'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(hintText: 'Enter new todo text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                ref.read(todosProvider.notifier).updateTodo(
                  todo.copyWith(text: textController.text),
                );
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}