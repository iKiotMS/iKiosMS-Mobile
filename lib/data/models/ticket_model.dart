import 'package:flutter/material.dart';

class TicketMessageModel {
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime? createdAt;

  const TicketMessageModel({
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.createdAt,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt']?.toString();
    return TicketMessageModel(
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: rawDate != null ? DateTime.tryParse(rawDate) : null,
    );
  }

  bool get isAdmin => senderRole == 'SUPER_ADMIN';
}

class TicketModel {
  final String id;
  final String ticketId;
  final String tenantId;
  final String tenantName;
  final String userId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final List<TicketMessageModel> messages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TicketModel({
    required this.id,
    required this.ticketId,
    required this.tenantId,
    required this.tenantName,
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.messages,
    this.createdAt,
    this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final rawCreated = json['createdAt']?.toString();
    final rawUpdated = json['updatedAt']?.toString();
    final rawMessages = json['messages'] as List<dynamic>? ?? [];

    return TicketModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      ticketId: json['ticketId']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      tenantName: json['tenantName']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      status: json['status']?.toString() ?? 'OPEN',
      messages: rawMessages
          .map((m) => TicketMessageModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: rawCreated != null ? DateTime.tryParse(rawCreated) : null,
      updatedAt: rawUpdated != null ? DateTime.tryParse(rawUpdated) : null,
    );
  }

  bool get isClosed => status == 'CLOSED';

  String get priorityLabel {
    switch (priority) {
      case 'URGENT':
        return 'Khẩn cấp';
      case 'HIGH':
        return 'Cao';
      case 'MEDIUM':
        return 'Trung bình';
      case 'LOW':
        return 'Thấp';
      default:
        return priority;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'URGENT':
        return Colors.red.shade700;
      case 'HIGH':
        return Colors.orange.shade800;
      case 'MEDIUM':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color get priorityBackgroundColor {
    switch (priority) {
      case 'URGENT':
        return Colors.red.shade50;
      case 'HIGH':
        return Colors.orange.shade50;
      case 'MEDIUM':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'OPEN':
        return 'Đang chờ';
      case 'IN_PROGRESS':
        return 'Đang xử lý';
      case 'RESOLVED':
        return 'Đã giải quyết';
      case 'CLOSED':
        return 'Đã đóng';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'OPEN':
        return Colors.green.shade700;
      case 'IN_PROGRESS':
        return Colors.amber.shade800;
      case 'RESOLVED':
        return Colors.teal.shade700;
      case 'CLOSED':
      default:
        return Colors.grey.shade600;
    }
  }

  Color get statusBackgroundColor {
    switch (status) {
      case 'OPEN':
        return Colors.green.shade50;
      case 'IN_PROGRESS':
        return Colors.amber.shade50;
      case 'RESOLVED':
        return Colors.teal.shade50;
      case 'CLOSED':
      default:
        return Colors.grey.shade100;
    }
  }
}
