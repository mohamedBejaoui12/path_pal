class TicketMessage {
  final String id;
  final String ticketId;
  final String senderEmail;
  final bool isAdmin;
  final String message;
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderEmail,
    required this.isAdmin,
    required this.message,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'],
      ticketId: json['ticket_id'],
      senderEmail: json['sender_email'],
      isAdmin: json['is_admin'] ?? false,
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'sender_email': senderEmail,
      'is_admin': isAdmin,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}