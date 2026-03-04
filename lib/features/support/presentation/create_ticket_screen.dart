import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';
import '../data/support_providers.dart';
import '../domain/ticket_model.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TicketPriority _priority = TicketPriority.medium;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supportService = ref.read(supportServiceProvider);
      await supportService.createTicket(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
      );

      // Refresh the tickets list
      ref.refresh(userTicketsProvider);
      ref.refresh(activeTicketsCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Support Ticket'),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Brief description of your issue',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Detailed explanation of your issue',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                alignLabelWithHint: true,
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Priority selection
            Card(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPriorityRadio(
                      TicketPriority.low,
                      'Low',
                      'Not urgent, can wait',
                      Colors.green,
                      isDarkMode,
                    ),
                    const Divider(),
                    _buildPriorityRadio(
                      TicketPriority.medium,
                      'Medium',
                      'Important but not critical',
                      Colors.orange,
                      isDarkMode,
                    ),
                    const Divider(),
                    _buildPriorityRadio(
                      TicketPriority.high,
                      'High',
                      'Urgent issue requiring immediate attention',
                      Colors.red,
                      isDarkMode,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SUBMIT TICKET'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityRadio(
    TicketPriority priority,
    String title,
    String subtitle,
    Color color,
    bool isDarkMode,
  ) {
    return RadioListTile<TicketPriority>(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
      value: priority,
      groupValue: _priority,
      activeColor: color,
      onChanged: (value) {
        setState(() {
          _priority = value!;
        });
      },
      secondary: Icon(
        Icons.flag,
        color: color,
      ),
    );
  }
}