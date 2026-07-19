import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'shift_api_service.g.dart';

/// Riverpod-generated provider for [ShiftApiService].
@riverpod
ShiftApiService shiftApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return ShiftApiService(dio);
}

/// Makes raw HTTP calls to the shift-related backend endpoints.
///
/// This class only deals with HTTP — no model parsing, no business logic.
/// The repository above this layer handles parsing and error wrapping.
class ShiftApiService {
  final Dio _dio;

  ShiftApiService(this._dio);

  /// GET /working-schedules?userId=123&startDate=...&endDate=...
  ///
  /// Returns a list of raw JSON maps.
  Future<List<Map<String, dynamic>>> getShifts({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(ApiEndpoints.myShifts(startDate, endDate));
    // Expect the backend to return a JSON array.
    final data = response.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    // Some backends wrap the list in a "data" key — adjust if needed.
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// GET /api/employee/shifts/{shiftId}
  ///
  /// Returns a single raw JSON map.
  Future<Map<String, dynamic>> getShiftById(String shiftId) async {
    final response = await _dio.get(ApiEndpoints.shiftDetail(shiftId));
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    return {};
  }
}
