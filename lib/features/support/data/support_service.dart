import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import '../domain/ticket_model.dart';
import '../domain/ticket_message_model.dart';

class SupportService {
  final SupabaseClient _client = Supabase.instance.client;
  final Ref _ref;

  SupportService(this._ref);

  String get _userEmail => _ref.read(authProvider).user?.email ?? '';

  Future<List<SupportTicket>> getUserTickets() async {
    final response = await _client
        .from('support_tickets')
        .select()
        .eq('user_email', _userEmail)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((ticket) => SupportTicket.fromJson(ticket as Map<String, dynamic>))
        .toList();
  }

  Future<int> getActiveTicketsCount() async {
    final response = await _client
        .from('support_tickets')
        .select('id')
        .eq('user_email', _userEmail)
        .or('status.eq.pending,status.eq.in_progress');

    return (response as List<dynamic>).length;
  }

  Future<SupportTicket> createTicket({
    required String title,
    required String description,
    TicketPriority priority = TicketPriority.medium,
  }) async {
    final activeTicketsCount = await getActiveTicketsCount();
    if (activeTicketsCount >= 3) {
      throw Exception(
          'You can only have 3 active tickets at a time. Please wait for your existing tickets to be resolved.');
    }

    final response = await _client.from('support_tickets').insert({
      'user_email': _userEmail,
      'title': title,
      'description': description,
      'priority': _priorityToString(priority),
    }).select().single();

    return SupportTicket.fromJson(response as Map<String, dynamic>);
  }

  Future<SupportTicket> getTicketById(String ticketId) async {
    final response = await _client
        .from('support_tickets')
        .select()
        .eq('id', ticketId)
        .eq('user_email', _userEmail)
        .single();

    return SupportTicket.fromJson(response as Map<String, dynamic>);
  }

  Future<SupportTicket> updateTicketStatus(
      String ticketId, TicketStatus status) async {
    if (status != TicketStatus.closed) {
      throw Exception('You can only close your tickets.');
    }

    final response = await _client
        .from('support_tickets')
        .update({
          'status': _statusToString(status),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId)
        .eq('user_email', _userEmail)
        .select()
        .single();

    return SupportTicket.fromJson(response as Map<String, dynamic>);
  }

  Future<List<TicketMessage>> getTicketMessages(String ticketId) async {
    await getTicketById(ticketId);
    
    final response = await _client
        .from('support_ticket_messages')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at');

    return (response as List<dynamic>)
        .map((message) => TicketMessage.fromJson(message as Map<String, dynamic>))
        .toList();
  }

  Future<TicketMessage> addTicketMessage(
      String ticketId, String message) async {
    await getTicketById(ticketId);
    
    final response = await _client.from('support_ticket_messages').insert({
      'ticket_id': ticketId,
      'sender_email': _userEmail,
      'is_admin': false,
      'message': message,
    }).select().single();

    return TicketMessage.fromJson(response as Map<String, dynamic>);
  }

  Stream<List<SupportTicket>> watchUserTickets() {
    return _client
        .from('support_tickets')
        .stream(primaryKey: ['id'])
        .eq('user_email', _userEmail)
        .map((data) => data
            .map((ticket) => SupportTicket.fromJson(ticket as Map<String, dynamic>))
            .toList());
  }

  Stream<List<TicketMessage>> watchTicketMessages(String ticketId) {
    return _client
        .from('support_ticket_messages')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .map((data) => data
            .map((message) => TicketMessage.fromJson(message as Map<String, dynamic>))
            .toList());
  }
  
  String _statusToString(TicketStatus status) {
    switch (status) {
      case TicketStatus.pending:
        return 'pending';
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
    }
  }

  String _priorityToString(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'low';
      case TicketPriority.medium:
        return 'medium';
      case TicketPriority.high:
        return 'high';
    }
  }
}