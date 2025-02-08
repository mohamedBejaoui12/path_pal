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
    
    // Empty state handling
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_outlined, 
              size: 80, 
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${category.name.toLowerCase()} todos yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a new todo',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      itemCount: todos.length,
      onReorder: (oldIndex, newIndex) {
        // Adjust newIndex if moving an item down the list
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        
        // Create a new list with the reordered items
        final reorderedTodos = List<Todo>.from(todos);
        final movedTodo = reorderedTodos.removeAt(oldIndex);
        reorderedTodos.insert(newIndex, movedTodo);
        
        // Update the todos in the provider
        ref.read(todosProvider.notifier).updateTodoOrder(category, reorderedTodos);
      },
      itemBuilder: (context, index) {
        final todo = todos[index];
        return _buildTodoItem(context, ref, todo, index);
      },
    );
  }

  Widget _buildTodoItem(BuildContext context, WidgetRef ref, Todo todo, int index) {
    return Dismissible(
      key: Key(todo.id ?? UniqueKey().toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteConfirmation(context),
      onDismissed: (direction) => ref.read(todosProvider.notifier).deleteTodo(todo),
      child: ReorderableDelayedDragStartListener(
        index: index,
        child: Card(
          key: ValueKey(todo.id),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: ListTile(
            leading: Text(
              todo.emoji ?? '📝',
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              todo.text,
              style: TextStyle(
                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                color: todo.isCompleted ? Colors.grey : null,
              ),
            ),
            trailing: Checkbox(
              value: todo.isCompleted,
              onChanged: (value) {
                ref.read(todosProvider.notifier).updateTodo(
                      todo.copyWith(isCompleted: value ?? false),
                    );
              },
            ),
            onLongPress: () => _showTodoOptions(context, ref, todo),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Todo', style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        content: Text(
          'Are you sure you want to delete this todo?', 
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel', 
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color ?? Colors.white,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF862C24)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTodoOptions(BuildContext context, WidgetRef ref, Todo todo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _showEditTodoDialog(context, ref, todo);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmationDialog(context, ref, todo);
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
        title: const Text('Edit Todo'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter new todo text',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                ref.read(todosProvider.notifier).updateTodo(
                      todo.copyWith(text: textController.text.trim()),
                    );
                Navigator.pop(context);
              }
              
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF862C24)),
            child: const Text('Save',style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, Todo todo) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Delete Todo', 
          style: TextStyle(color: theme.textTheme.titleLarge?.color),
        ),
        content: Text(
          'Are you sure you want to delete this todo?',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel', 
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color ?? Colors.white,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(todosProvider.notifier).deleteTodo(todo);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }
}