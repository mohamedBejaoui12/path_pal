import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
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
  bool _showEmojiPicker = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add New Todo',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Enter todo description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TodoCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: TodoCategory.values
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.name),
                      ))
                  .toList(),
              onChanged: (category) {
                if (category != null) {
                  setState(() {
                    _selectedCategory = category;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emoji (Optional):',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                GestureDetector(
                  onTap: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
                  child: Text(
                    _selectedEmoji ?? 'Select Emoji',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ],
            ),
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    setState(() {
                      _selectedEmoji = emoji.emoji;
                      _showEmojiPicker = false;
                    });
                  },
                  config: Config(
                    columns: 7,
                    emojiSizeMax: 32,
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    bgColor: Theme.of(context).scaffoldBackgroundColor,
                    indicatorColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15),
              child: ElevatedButton(
                onPressed: _addTodo,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Color(0xFF862C24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Todo', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTodo() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      final newTodo = Todo.create(
        userEmail: widget.userEmail,
        text: text,
        category: _selectedCategory,
        emoji: _selectedEmoji,
      );

      ref.read(todosProvider.notifier).addTodo(newTodo);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}