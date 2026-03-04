import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import '../domain/ticket_model.dart';
import '../domain/ticket_message_model.dart';
import 'support_service.dart';

// Provider for the support service
final supportServiceProvider = Provider<SupportService>((ref) {
  // Pass the ref to the service so it can access the auth provider
  return SupportService(ref);
});

// Provider for user tickets
final userTicketsProvider = FutureProvider<List<SupportTicket>>((ref) async {
  final supportService = ref.watch(supportServiceProvider);
  return await supportService.getUserTickets();
});

// Provider for active tickets count
final activeTicketsCountProvider = FutureProvider<int>((ref) async {
  final supportService = ref.watch(supportServiceProvider);
  return await supportService.getActiveTicketsCount();
});

// Provider for a specific ticket
final ticketProvider = FutureProvider.family<SupportTicket, String>((ref, ticketId) async {
  final supportService = ref.watch(supportServiceProvider);
  return await supportService.getTicketById(ticketId);
});

// Provider for ticket messages
final ticketMessagesProvider = FutureProvider.family<List<TicketMessage>, String>((ref, ticketId) async {
  final supportService = ref.watch(supportServiceProvider);
  return await supportService.getTicketMessages(ticketId);
});

// Stream provider for watching ticket updates
final ticketUpdatesProvider = StreamProvider<List<SupportTicket>>((ref) {
  final supportService = ref.watch(supportServiceProvider);
  return supportService.watchUserTickets();
});

// Stream provider for watching ticket message updates
final ticketMessageUpdatesProvider = StreamProvider.family<List<TicketMessage>, String>((ref, ticketId) {
  final supportService = ref.watch(supportServiceProvider);
  return supportService.watchTicketMessages(ticketId);
});