import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/todo_model.dart';
import '../data/todo_provider.dart';

class AddTodoBottomSheet extends ConsumerStatefulWidget {
  final String userEmail;

  const AddTodoBottomSheet({Key? key, required this.userEmail}) : super(key: key);

  @override
  _AddTodoBottomSheetState createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends ConsumerState<AddTodoBottomSheet> {
  final _textController = TextEditingController();
  TodoCategory _selectedCategory = TodoCategory.Standard;
  String? _selectedEmoji;

  final List<String> _emojis = ['🍽️', '🏞️', '📝', '🌟', '🚀'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Enter your todo',
            ),
          ),
          SizedBox(height: 10),
          DropdownButton<TodoCategory>(
            value: _selectedCategory,
            onChanged: (category) {
              setState(() {
                _selectedCategory = category!;
              });
            },
            items: TodoCategory.values
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.name.toUpperCase()),
                    ))
                .toList(),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _emojis.map((emoji) {
              return ChoiceChip(
                label: Text(emoji),
                selected: _selectedEmoji == emoji,
                onSelected: (selected) {
                  setState(() {
                    _selectedEmoji = selected ? emoji : null;
                  });
                },
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: _addTodo,
            child: Text('Add Todo'),
          ),
        ],
      ),
    );
  }

void _addTodo() {
    if (_textController.text.isNotEmpty) {
      final newTodo = Todo.create(
        userEmail: widget.userEmail,
        text: _textController.text,
        category: _selectedCategory,
        emoji: _selectedEmoji,
      );

      ref.read(todosProvider.notifier).addTodo(newTodo);
      Navigator.pop(context);
    }
}
}