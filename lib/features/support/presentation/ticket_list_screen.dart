import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_provider.dart';
import '../data/support_providers.dart';
import '../domain/ticket_model.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshData() async {
    // Invalidate the providers to force a refresh
    ref.invalidate(ticketUpdatesProvider);
    ref.invalidate(activeTicketsCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final ticketsAsync = ref.watch(ticketUpdatesProvider);
    final activeTicketsCountAsync = ref.watch(activeTicketsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        backgroundColor:
            isDarkMode ? Colors.grey.shade800 : AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshIndicatorKey.currentState?.show();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              color: isDarkMode ? Colors.grey.shade700 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color:
                          isDarkMode ? Colors.white70 : AppColors.primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: activeTicketsCountAsync.when(
                        data: (count) => Text(
                          'You have $count active tickets (max 3)',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const Text('Loading...'),
                        error: (_, __) =>
                            const Text('Error loading ticket count'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tickets list with RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshData,
              color: AppColors.primaryColor,
              child: ticketsAsync.when(
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.support_agent,
                                  size: 64,
                                  color: isDarkMode
                                      ? Colors.white30
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No support tickets yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to create one',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white60
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return _TicketCard(
                        ticket: ticket,
                        isDarkMode: isDarkMode,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(
                        child: Text('Error: ${error.toString()}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final activeTicketsCount =
              await ref.read(activeTicketsCountProvider.future);
          if (activeTicketsCount >= 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You can only have 3 active tickets at a time.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTicketScreen(),
            ),
          ).then((_) {
            // Refresh the data when returning from create ticket screen
            _refreshData();
          });
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final bool isDarkMode;

  const _TicketCard({
    Key? key,
    required this.ticket,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(ticketId: ticket.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: TextStyle(
                        fontSize: 16,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
        ),
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
