/// Shift template from /shift-templates.
class ShiftTemplateModel {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final String? status;

  const ShiftTemplateModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.status,
  });

  String get timeRange => '$startTime - $endTime';

  factory ShiftTemplateModel.fromJson(Map<String, dynamic> json) {
    return ShiftTemplateModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startTime: _trimTime(json['startTime']?.toString() ?? ''),
      endTime: _trimTime(json['endTime']?.toString() ?? ''),
      status: json['status']?.toString(),
    );
  }

  static String _trimTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }
}

class CreateShiftTemplateInput {
  final String name;
  final String startTime;
  final String endTime;

  const CreateShiftTemplateInput({
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'startTime': startTime.trim(),
        'endTime': endTime.trim(),
      };
}
