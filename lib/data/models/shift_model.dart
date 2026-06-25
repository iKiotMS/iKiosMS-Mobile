import 'package:flutter/material.dart';

/// Represents a single employee shift returned by the backend.
///
/// To change what fields are parsed, update [fromJson] below.
class ShiftModel {
  final String id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final String role;
  final String status; // scheduled | upcoming | active | completed | missed
  final String? attendanceStatus; // NOT_CHECKED_IN, CHECKED_IN, CHECKED_OUT, ABSENT
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;

  const ShiftModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.role,
    required this.status,
    this.attendanceStatus,
    this.checkedInAt,
    this.checkedOutAt,
  });

  /// Parse a shift from the JSON map returned by the backend.
  ///
  /// Maps to the Backend's `WorkingSchedule` Mongoose model.
  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    // Safely extract nested data
    final shiftTemplate = json['shiftTemplateId'] as Map<String, dynamic>? ?? {};
    final user = json['userId'] as Map<String, dynamic>? ?? {};
    
    // Future-proofing: if the backend adds an aggregated 'attendance' field
    final attendance = json['attendance'] as Map<String, dynamic>?;

    return ShiftModel(
      id: json['_id']?.toString() ?? '',
      date: DateTime.tryParse(json['workDate']?.toString() ?? '') ?? DateTime.now(),
      startTime: shiftTemplate['startTime']?.toString() ?? '',
      endTime: shiftTemplate['endTime']?.toString() ?? '',
      location: '', // Add location mapping if the backend adds it to WorkingSchedule/Branch later
      role: user['role']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SCHEDULED',
      attendanceStatus: attendance?['status']?.toString(),
      checkedInAt: attendance?['actualCheckinAt'] != null
          ? DateTime.tryParse(attendance!['actualCheckinAt'].toString())
          : null,
      checkedOutAt: attendance?['actualCheckoutAt'] != null
          ? DateTime.tryParse(attendance!['actualCheckoutAt'].toString())
          : null,
    );
  }

  // ── Business logic helpers ────────────────────────────────────────────────

  /// True when the employee can tap "Chấm công vào ca".
  ///
  /// Only SCHEDULED shifts that haven't been checked-in yet are eligible.
  bool get isCheckInEligible => status == 'SCHEDULED' && 
                                (attendanceStatus == 'NOT_CHECKED_IN' || attendanceStatus == null) && 
                                checkedInAt == null;

  /// True if the employee has already checked in.
  bool get isAlreadyCheckedIn => attendanceStatus == 'CHECKED_IN' || 
                                 attendanceStatus == 'CHECKED_OUT' || 
                                 checkedInAt != null;

  /// Vietnamese label for the shift status.
  ///
  /// Maps to the `WorkingSchedule` status enum.
  String get statusLabel {
    const labels = {
      'SCHEDULED': 'Đã xếp lịch',
      'COMPLETED': 'Hoàn thành',
      'CANCELLED': 'Đã hủy',
      'DELETED': 'Đã xóa',
    };
    return labels[status] ?? status;
  }

  /// Color used for the status badge.
  Color get statusColor {
    switch (status) {
      case 'SCHEDULED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
      case 'DELETED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Vietnamese label for the attendance status.
  String get attendanceStatusLabel {
    if (attendanceStatus == 'CHECKED_OUT' || checkedOutAt != null) return 'Đã check-out';
    if (attendanceStatus == 'CHECKED_IN' || checkedInAt != null) return 'Đã check-in';
    if (attendanceStatus == 'ABSENT') return 'Vắng mặt';
    if (status == 'CANCELLED' || status == 'DELETED') return 'Không áp dụng';
    return 'Chưa chấm công';
  }

  /// Color used for the attendance status badge.
  Color get attendanceStatusColor {
    if (attendanceStatus == 'CHECKED_OUT' || checkedOutAt != null) return Colors.indigo;
    if (attendanceStatus == 'CHECKED_IN' || checkedInAt != null) return Colors.teal;
    if (attendanceStatus == 'ABSENT') return Colors.red;
    if (status == 'CANCELLED' || status == 'DELETED') return Colors.grey;
    return Colors.orange.shade700;
  }

  /// Creates a copy of this shift with updated fields.
  /// Useful for updating state after a check-in.
  ShiftModel copyWith({
    String? id,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? location,
    String? role,
    String? status,
    String? attendanceStatus,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      role: role ?? this.role,
      status: status ?? this.status,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
    );
  }
}
