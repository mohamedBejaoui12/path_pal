import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';
import '../data/support_providers.dart';
import '../domain/ticket_model.dart';
import '../domain/ticket_message_model.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const TicketDetailScreen({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final supportService = ref.read(supportServiceProvider);
      await supportService.addTicketMessage(widget.ticketId, message);
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _closeTicket() async {
    try {
      final supportService = ref.read(supportServiceProvider);
      await supportService.updateTicketStatus(
        widget.ticketId,
        TicketStatus.closed,
      );

      // Refresh providers
      ref.refresh(ticketProvider(widget.ticketId));
      ref.refresh(userTicketsProvider);
      ref.refresh(activeTicketsCountProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket closed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error closing ticket: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this method to the class
  Future<void> _refreshMessages() async {
    ref.refresh(ticketMessageUpdatesProvider(widget.ticketId));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final ticketAsync = ref.watch(ticketProvider(widget.ticketId));
    final messagesAsync =
        ref.watch(ticketMessageUpdatesProvider(widget.ticketId));

    // Scroll to bottom when new messages are added
    messagesAsync.whenData((messages) {
      if (messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: ticketAsync.when(
          data: (ticket) => Text('Ticket: ${ticket.title}'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Ticket Details'),
        ),
        backgroundColor:
            isDarkMode ? Colors.grey.shade800 : AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMessages,
          ),
          ticketAsync.when(
            data: (ticket) {
              if (ticket.status != TicketStatus.closed) {
                return IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Close Ticket',
                  onPressed: _closeTicket,
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ticket info card
          ticketAsync.when(
            data: (ticket) => _TicketInfoCard(
              ticket: ticket,
              isDarkMode: isDarkMode,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error: ${error.toString()}'),
            ),
          ),

          // Messages
          // Update the messages section in the build method
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDarkMode
                              ? Colors.white30
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDarkMode
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white60
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Add a debug print to check messages
                debugPrint('Messages count: ${messages.length}');
                for (var msg in messages) {
                  debugPrint(
                      'Message: ${msg.message}, isAdmin: ${msg.isAdmin}, sender: ${msg.senderEmail}');
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      message: message,
                      isDarkMode: isDarkMode,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ),

          // Message input
          ticketAsync.when(
            data: (ticket) {
              if (ticket.status == TicketStatus.closed) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  color:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: const Text(
                    'This ticket is closed. You cannot send more messages.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey.shade700
                                : Colors.grey.withOpacity(0.1),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: _isSending ? null : _sendMessage,
                        backgroundColor: AppColors.primaryColor,
                        elevation: 0,
                        child: _isSending
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TicketInfoCard extends StatelessWidget {
  final SupportTicket ticket;
  final bool isDarkMode;

  const _TicketInfoCard({
    Key? key,
    required this.ticket,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              _buildStatusChip(ticket.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.description,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriorityIndicator(ticket.priority),
              Text(
                'Created: ${DateFormat.yMMMd().format(ticket.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TicketStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case TicketStatus.pending:
        chipColor = Colors.orange;
        statusText = 'Pending';
        break;
      case TicketStatus.inProgress:
        chipColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case TicketStatus.resolved:
        chipColor = Colors.green;
        statusText = 'Resolved';
        break;
      case TicketStatus.closed:
        chipColor = Colors.grey;
        statusText = 'Closed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(TicketPriority priority) {
    Color priorityColor;
    String priorityText;

    switch (priority) {
      case TicketPriority.low:
        priorityColor = Colors.green;
        priorityText = 'Low Priority';
        break;
      case TicketPriority.medium:
        priorityColor = Colors.orange;
        priorityText = 'Medium Priority';
        break;
      case TicketPriority.high:
        priorityColor = Colors.red;
        priorityText = 'High Priority';
        break;
    }

    return Row(
      children: [
        Icon(
          Icons.flag,
          size: 16,
          color: priorityColor,
        ),
        const SizedBox(width: 4),
        Text(
          priorityText,
          style: TextStyle(
            fontSize: 12,
            color: priorityColor,
          ),
        ),
      ],
    );
  }
}

// The existing code for _MessageBubble class needs to be updated to properly show both user and admin messages

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  final bool isDarkMode;

  const _MessageBubble({
    Key? key,
    required this.message,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.isAdmin;
    final time = DateFormat.jm().format(message.createdAt);

    // Extract username from email for display
    final displayName =
        isAdmin ? "Support Agent" : message.senderEmail.split('@')[0];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAdmin) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.support_agent,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isAdmin
                    ? (isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.withOpacity(0.1))
                    : AppColors.primaryColor,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isAdmin
                      ? const Radius.circular(0)
                      : const Radius.circular(16),
                  bottomRight: isAdmin
                      ? const Radius.circular(16)
                      : const Radius.circular(0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add sender name for clarity
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAdmin
                          ? (isDarkMode ? Colors.white : Colors.black87)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isAdmin
                          ? (isDarkMode ? Colors.white : Colors.black87)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isAdmin
                          ? (isDarkMode ? Colors.white70 : Colors.grey)
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: isDarkMode ? Colors.white70 : Colors.grey,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
