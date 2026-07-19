import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'staff_api_service.g.dart';

@riverpod
StaffApiService staffApiService(Ref ref) {
  return StaffApiService(ref.watch(apiClientProvider));
}

class StaffApiService {
  final Dio _dio;

  StaffApiService(this._dio);

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int recordPerPage = 50,
    String? keyword,
    String? status,
    String? role,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.staff,
      queryParameters: {
        'page': page,
        'recordPerPage': recordPerPage,
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (role != null && role.isNotEmpty) 'role': role,
      },
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiEndpoints.staff, data: body);
    return _asMap(response.data);
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    await _dio.patch(ApiEndpoints.staffById(id), data: body);
  }

  Future<void> deactivateAccount(String id) async {
    await _dio.patch(ApiEndpoints.staffAccountDeactivate(id));
  }

  Future<void> createAccount(String id, Map<String, dynamic> body) async {
    await _dio.post(ApiEndpoints.staffAccount(id), data: body);
  }

  Future<void> updatePassword(String id, Map<String, dynamic> body) async {
    await _dio.patch(ApiEndpoints.staffAccountPassword(id), data: body);
  }

  Future<void> remove(String id) async {
    await _dio.delete(ApiEndpoints.staffById(id));
  }

  Future<Map<String, dynamic>> createLeaveBalance(
    String id,
    int annualLeaveDays,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.staffLeaveBalance(id),
      data: {'annualLeaveDays': annualLeaveDays},
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> updateLeaveBalance(
    String id,
    int annualLeaveDays,
  ) async {
    final response = await _dio.patch(
      ApiEndpoints.staffLeaveBalance(id),
      data: {'annualLeaveDays': annualLeaveDays},
    );
    return _asMap(response.data);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
