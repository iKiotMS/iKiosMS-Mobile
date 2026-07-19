/// Working schedule for Branch Manager roster management.
class WorkingScheduleAdminModel {
  final String id;
  final String workDate;
  final String status;
  final String scheduleType;
  final String shiftTemplateId;
  final String shiftName;
  final String startTime;
  final String endTime;
  final List<ScheduleAssigneeModel> assignees;

  const WorkingScheduleAdminModel({
    required this.id,
    required this.workDate,
    required this.status,
    required this.scheduleType,
    required this.shiftTemplateId,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    this.assignees = const [],
  });

  String get staffNames {
    if (assignees.isEmpty) return '—';
    return assignees.map((a) => a.staffName).join(', ');
  }

  String get timeRange => '$startTime - $endTime';

  String get statusLabel {
    const labels = {
      'SCHEDULED': 'Đã xếp lịch',
      'COMPLETED': 'Hoàn thành',
      'CANCELLED': 'Đã hủy',
      'DELETED': 'Đã xóa',
    };
    return labels[status] ?? status;
  }

  bool get isDeleted => status == 'DELETED' || status == 'CANCELLED';

  factory WorkingScheduleAdminModel.fromJson(Map<String, dynamic> json) {
    final template = json['shiftTemplateId'];
    String templateId = '';
    String shiftName = '';
    String startTime = '';
    String endTime = '';

    if (template is Map) {
      templateId = template['_id']?.toString() ?? '';
      shiftName = template['name']?.toString() ?? '';
      startTime = _trimTime(template['startTime']?.toString() ?? '');
      endTime = _trimTime(template['endTime']?.toString() ?? '');
    } else {
      templateId = template?.toString() ?? '';
    }

    final users = <ScheduleAssigneeModel>[];
    final rawUsers = json['userId'];
    if (rawUsers is List) {
      for (final item in rawUsers) {
        if (item is Map) {
          users.add(
            ScheduleAssigneeModel.fromJson(Map<String, dynamic>.from(item)),
          );
        } else if (item != null) {
          users.add(
            ScheduleAssigneeModel(
              userId: item.toString(),
              staffName: item.toString(),
              phoneNumber: '',
              role: '',
            ),
          );
        }
      }
    } else if (rawUsers is Map) {
      users.add(
        ScheduleAssigneeModel.fromJson(Map<String, dynamic>.from(rawUsers)),
      );
    } else if (rawUsers != null) {
      users.add(
        ScheduleAssigneeModel(
          userId: rawUsers.toString(),
          staffName: rawUsers.toString(),
          phoneNumber: '',
          role: '',
        ),
      );
    }

    return WorkingScheduleAdminModel(
      id: json['_id']?.toString() ?? '',
      workDate: (json['workDate']?.toString() ?? '').substring(
        0,
        (json['workDate']?.toString().length ?? 0).clamp(0, 10),
      ),
      status: json['status']?.toString() ?? 'SCHEDULED',
      scheduleType: json['scheduleType']?.toString() ?? 'NORMAL',
      shiftTemplateId: templateId,
      shiftName: shiftName.isEmpty ? 'Ca làm' : shiftName,
      startTime: startTime,
      endTime: endTime,
      assignees: users,
    );
  }

  static String _trimTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }
}

class ScheduleAssigneeModel {
  final String userId;
  final String staffName;
  final String phoneNumber;
  final String role;

  const ScheduleAssigneeModel({
    required this.userId,
    required this.staffName,
    required this.phoneNumber,
    required this.role,
  });

  factory ScheduleAssigneeModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final first = profile?['firstName']?.toString() ?? '';
    final last = profile?['lastName']?.toString() ?? '';
    final name = '$last $first'.trim();

    return ScheduleAssigneeModel(
      userId: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      staffName: name.isNotEmpty
          ? name
          : (json['phoneNumber']?.toString() ?? '—'),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

class CreateWorkingScheduleInput {
  final List<String> userIds;
  final String shiftTemplateId;
  final String workDate;
  final String scheduleType;

  const CreateWorkingScheduleInput({
    required this.userIds,
    required this.shiftTemplateId,
    required this.workDate,
    this.scheduleType = 'NORMAL',
  });

  Map<String, dynamic> toJson() => {
        // FE bulk luôn gửi userId (string | string[]).
        'userId': userIds,
        'shiftTemplateId': shiftTemplateId,
        'workDate': workDate,
        'scheduleType': scheduleType,
      };
}

class WorkingScheduleListResult {
  final List<WorkingScheduleAdminModel> data;
  final int total;
  final int page;
  final int totalPages;

  const WorkingScheduleListResult({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}
