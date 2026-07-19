import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'schedule_admin_api_service.g.dart';

@riverpod
ScheduleAdminApiService scheduleAdminApiService(Ref ref) {
  return ScheduleAdminApiService(ref.watch(apiClientProvider));
}

class ScheduleAdminApiService {
  final Dio _dio;

  ScheduleAdminApiService(this._dio);

  Future<Map<String, dynamic>> getShiftTemplates({
    int page = 1,
    int recordPerPage = 50,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.shiftTemplates,
      queryParameters: {
        'page': page,
        'recordPerPage': recordPerPage,
      },
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> createShiftTemplate(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(ApiEndpoints.shiftTemplates, data: body);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> updateShiftTemplate(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch(
      ApiEndpoints.shiftTemplateById(id),
      data: body,
    );
    return _asMap(response.data);
  }

  Future<void> deleteShiftTemplate(String id) async {
    await _dio.delete(ApiEndpoints.shiftTemplateById(id));
  }

  /// BM: luôn GET /working-schedules/branches
  Future<Map<String, dynamic>> getBranchSchedules({
    int page = 1,
    int recordPerPage = 50,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.workingSchedulesBranches,
      queryParameters: {
        'page': page,
        'recordPerPage': recordPerPage,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> createBulkSchedules(
    List<Map<String, dynamic>> schedules,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.workingSchedulesBulk,
      data: {'schedules': schedules},
    );
    return _asMap(response.data);
  }

  Future<void> deleteSchedule(String id) async {
    await _dio.delete(ApiEndpoints.workingScheduleById(id));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
