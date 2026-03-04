
import 'package:flutter/foundation.dart';

enum TicketStatus {
  pending,
  inProgress,
  resolved,
  closed,
}

enum TicketPriority {
  low,
  medium,
  high,
}

class SupportTicket {
  final String id;
  final String userEmail;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.userEmail,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      userEmail: json['user_email'],
      title: json['title'],
      description: json['description'],
      status: _statusFromString(json['status']),
      priority: _priorityFromString(json['priority']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_email': userEmail,
      'title': title,
      'description': description,
      'status': _statusToString(status),
      'priority': _priorityToString(priority),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static TicketStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return TicketStatus.pending;
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.pending;
    }
  }

  static String _statusToString(TicketStatus status) {
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

  static TicketPriority _priorityFromString(String priority) {
    switch (priority) {
      case 'low':
        return TicketPriority.low;
      case 'medium':
        return TicketPriority.medium;
      case 'high':
        return TicketPriority.high;
      default:
        return TicketPriority.medium;
    }
  }

  static String _priorityToString(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return 'low';
      case TicketPriority.medium:
        return 'medium';
      case TicketPriority.high:
        return 'high';
    }
  }

  SupportTicket copyWith({
    String? id,
    String? userEmail,
    String? title,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}