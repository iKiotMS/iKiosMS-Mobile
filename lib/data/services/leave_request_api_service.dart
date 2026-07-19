import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'leave_request_api_service.g.dart';

@riverpod
LeaveRequestApiService leaveRequestApiService(Ref ref) {
  return LeaveRequestApiService(ref.watch(apiClientProvider));
}

class LeaveRequestApiService {
  final Dio _dio;

  LeaveRequestApiService(this._dio);

  /// BM: luôn GET /leave-requests/branches
  Future<Map<String, dynamic>> getList({
    int page = 1,
    int recordPerPage = 50,
    String? status,
    String? keyword,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.leaveRequestsBranches,
      queryParameters: {
        'page': page,
        'recordPerPage': recordPerPage,
        if (status != null && status.isNotEmpty) 'status': status,
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
      },
    );
    return _asMap(response.data);
  }

  Future<void> approve(String id, Map<String, dynamic> body) async {
    await _dio.post(ApiEndpoints.leaveRequestApprove(id), data: body);
  }

  Future<void> reject(String id, String reviewNote) async {
    await _dio.post(
      ApiEndpoints.leaveRequestReject(id),
      data: {'reviewNote': reviewNote.trim()},
    );
  }

  Future<Map<String, dynamic>> createEmergency(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.leaveRequestEmergency,
      data: body,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> createPersonal(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(ApiEndpoints.leaveRequests, data: body);
    return _asMap(response.data);
  }

  Future<void> cancel(String id) async {
    await _dio.post(ApiEndpoints.leaveRequestCancel(id));
  }

  Future<Map<String, dynamic>> getBalance() async {
    final response = await _dio.get(ApiEndpoints.leaveRequestBalance);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> previewHandover({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.leaveRequestHandoverPreview,
      data: {
        'startDate': startDate,
        'endDate': endDate,
      },
    );
    return _asMap(response.data);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
