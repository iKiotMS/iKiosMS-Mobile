/// Leave request for Branch Manager approval flow.
class LeaveRequestModel {
  final String id;
  final String userId;
  final String staffName;
  final String? requesterRole;
  final String branchName;
  final String reason;
  final String startDate;
  final String endDate;
  final String status;
  final int? paidLeaveDays;
  final int? unpaidLeaveDays;
  final String? reviewNote;
  final String? createdAt;

  const LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.staffName,
    this.requesterRole,
    this.branchName = '',
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.paidLeaveDays,
    this.unpaidLeaveDays,
    this.reviewNote,
    this.createdAt,
  });

  int get totalDays {
    final from = DateTime.tryParse(startDate.sliceSafe);
    final to = DateTime.tryParse(endDate.sliceSafe);
    if (from == null || to == null) return 1;
    return to.difference(from).inDays.abs() + 1;
  }

  String get statusLabel {
    const labels = {
      'PENDING': 'Chờ duyệt',
      'APPROVED': 'Đã duyệt',
      'REJECTED': 'Từ chối',
      'CANCELLED': 'Đã hủy',
      'EXPIRED': 'Hết hạn',
      'DELETED': 'Đã xóa',
    };
    return labels[status] ?? status;
  }

  /// BM chi nhánh: chỉ duyệt STAFF, không tự duyệt đơn mình.
  bool canReviewAs(String? reviewerId, {String? reviewerRole}) {
    if (status != 'PENDING') return false;
    if (reviewerRole != 'BRANCH_MANAGER') return false;
    if (reviewerId != null &&
        reviewerId.isNotEmpty &&
        userId.isNotEmpty &&
        userId == reviewerId) {
      return false;
    }
    if (requesterRole == null || requesterRole!.isEmpty) return false;
    return requesterRole == 'STAFF';
  }

  bool canCancelAs(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return false;
    if (userId != currentUserId) return false;
    return status == 'PENDING' || status == 'APPROVED';
  }

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    String userId = '';
    String staffName = '—';
    String? role;
    String branchName = '—';

    if (user is Map) {
      userId = user['_id']?.toString() ?? '';
      role = user['role']?.toString();
      final profile = user['profile'] as Map<String, dynamic>?;
      final first = profile?['firstName']?.toString() ?? '';
      final last = profile?['lastName']?.toString() ?? '';
      final name = '$last $first'.trim();
      staffName = name.isNotEmpty
          ? name
          : (user['phoneNumber']?.toString() ??
              user['email']?.toString() ??
              '—');
      final branch = user['branchId'];
      if (branch is Map) {
        branchName = branch['name']?.toString() ?? 'Chi nhánh';
      } else if (branch != null) {
        branchName = 'Chi nhánh';
      }
    } else if (user != null) {
      userId = user.toString();
      staffName = user.toString();
    }

    return LeaveRequestModel(
      id: json['_id']?.toString() ?? '',
      userId: userId,
      staffName: staffName,
      requesterRole: role,
      branchName: branchName,
      reason: json['reason']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      paidLeaveDays: json['paidLeaveDays'] != null
          ? int.tryParse(json['paidLeaveDays'].toString())
          : null,
      unpaidLeaveDays: json['unpaidLeaveDays'] != null
          ? int.tryParse(json['unpaidLeaveDays'].toString())
          : null,
      reviewNote: json['reviewNote']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

extension on String {
  String get sliceSafe => length >= 10 ? substring(0, 10) : this;
}

class LeaveRequestListResult {
  final List<LeaveRequestModel> data;
  final int total;
  final int page;
  final int totalPages;

  const LeaveRequestListResult({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}

class ApproveLeaveInput {
  final int paidLeaveDays;
  final int unpaidLeaveDays;
  final String? reviewNote;

  const ApproveLeaveInput({
    required this.paidLeaveDays,
    required this.unpaidLeaveDays,
    this.reviewNote,
  });

  Map<String, dynamic> toJson() => {
        'paidLeaveDays': paidLeaveDays,
        'unpaidLeaveDays': unpaidLeaveDays,
        if (reviewNote != null && reviewNote!.trim().isNotEmpty)
          'reviewNote': reviewNote!.trim(),
      };
}

class CreateEmergencyLeaveInput {
  final String userId;
  final String startDate;
  final String endDate;
  final String reason;

  const CreateEmergencyLeaveInput({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'startDate': _toApiDateTime(startDate, '08:00'),
        'endDate': _toApiDateTime(endDate, '17:00'),
        'reason': reason.trim(),
      };
}

class CreatePersonalLeaveInput {
  final String startDate;
  final String endDate;
  final String reason;
  final String? handoverToUserId;

  const CreatePersonalLeaveInput({
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.handoverToUserId,
  });

  Map<String, dynamic> toJson() => {
        'startDate': _toApiDateTime(startDate, '08:00'),
        'endDate': _toApiDateTime(endDate, '17:00'),
        'reason': reason.trim(),
        if (handoverToUserId != null && handoverToUserId!.isNotEmpty)
          'handoverToUserId': handoverToUserId,
      };
}

/// FE `HandoverPreview` from POST /leave-requests/handover/preview.
class HandoverPreview {
  final bool requiresHandover;
  final int count;
  final String? message;

  const HandoverPreview({
    required this.requiresHandover,
    this.count = 0,
    this.message,
  });

  factory HandoverPreview.fromJson(Map<String, dynamic> json) {
    final nested = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    return HandoverPreview(
      requiresHandover: nested['requiresHandover'] == true,
      count: int.tryParse(nested['count']?.toString() ?? '') ?? 0,
      message: nested['message']?.toString(),
    );
  }
}

/// Matches FE `combineLeaveDateTime` → `YYYY-MM-DDTHH:mm:00+07:00`.
String _toApiDateTime(String date, String time) {
  if (date.contains('T')) return date;
  final safe = date.length >= 10 ? date.substring(0, 10) : date;
  final safeTime = RegExp(r'^\d{2}:\d{2}$').hasMatch(time) ? time : '08:00';
  return '${safe}T$safeTime:00+07:00';
}
