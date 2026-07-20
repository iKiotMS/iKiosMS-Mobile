import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class LeaveRequestModel {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final double paidLeaveDays;
  final double unpaidLeaveDays;
  final String? reviewNote;

  const LeaveRequestModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.paidLeaveDays,
    required this.unpaidLeaveDays,
    this.reviewNote,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['_id']?.toString() ?? '',
      startDate:
          DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate']?.toString() ?? '') ??
          DateTime.now(),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      paidLeaveDays: (json['paidLeaveDays'] as num?)?.toDouble() ?? 0,
      unpaidLeaveDays: (json['unpaidLeaveDays'] as num?)?.toDouble() ?? 0,
      reviewNote: json['reviewNote']?.toString(),
    );
  }
}

class LeaveBalance {
  final double annualLeaveDays;
  final double usedDays;
  final double remainingDays;

  const LeaveBalance({
    required this.annualLeaveDays,
    required this.usedDays,
    required this.remainingDays,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      annualLeaveDays: (json['annualLeaveDays'] as num?)?.toDouble() ?? 12,
      usedDays: (json['usedDays'] as num?)?.toDouble() ?? 0,
      remainingDays: (json['remainingDays'] as num?)?.toDouble() ?? 12,
    );
  }
}

class LeaveApi {
  final Dio dio;

  LeaveApi(this.dio);

  Future<List<LeaveRequestModel>> getMyRequests() async {
    final response = await dio.get(
      ApiEndpoints.myLeaveRequests,
      queryParameters: {'page': 1, 'recordPerPage': 100},
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    final list = body['data'] as List? ?? const [];
    return list
        .map(
          (item) => LeaveRequestModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<LeaveBalance> getBalance() async {
    final response = await dio.get(ApiEndpoints.leaveBalance);
    final body = Map<String, dynamic>.from(response.data as Map);
    final value = body['data'] is Map ? body['data'] : body;
    return LeaveBalance.fromJson(Map<String, dynamic>.from(value as Map));
  }

  Future<void> createRequest({
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    await dio.post(
      ApiEndpoints.createLeaveRequest,
      data: {
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        'reason': reason.trim(),
      },
    );
  }

  Future<void> cancelRequest(String id) async {
    await dio.post(ApiEndpoints.cancelLeaveRequest(id));
  }
}

final leaveApiProvider = Provider<LeaveApi>((ref) {
  return LeaveApi(ref.watch(apiClientProvider));
});
