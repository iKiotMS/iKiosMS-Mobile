import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../models/shift_model.dart';
import '../../services/shift_api_service.dart';
import 'shift_repository.dart';

/// Concrete implementation of [ShiftRepository].
///
/// Calls [ShiftApiService] for raw HTTP data, parses JSON into [ShiftModel],
/// and converts Dio errors into [ApiException].
class ShiftRepositoryImpl implements ShiftRepository {
  final ShiftApiService _apiService;

  ShiftRepositoryImpl(this._apiService);

  @override
  Future<List<ShiftModel>> getShifts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final rawList = await _apiService.getShifts(
        startDate: DateTimeUtils.formatApiDate(startDate),
        endDate: DateTimeUtils.formatApiDate(endDate),
      );
      developer.log(
        '✅ [ShiftRepository] getShifts SUCCESS! Raw response payload: $rawList',
      );
      return rawList.map(ShiftModel.fromJson).toList();
    } on DioException catch (e) {
      developer.log(
        '❌ [ShiftRepository] getShifts FAILED! Error data: ${e.response?.data} | Exception: $e',
      );
      throw ApiException(
        message: e.message ?? 'Lỗi kết nối máy chủ',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<ShiftModel> getShiftById(String shiftId) async {
    try {
      final raw = await _apiService.getShiftById(shiftId);
      developer.log(
        '✅ [ShiftRepository] getShiftById SUCCESS! Raw response payload: $raw',
      );
      return ShiftModel.fromJson(raw);
    } on DioException catch (e) {
      developer.log(
        '❌ [ShiftRepository] getShiftById FAILED! Error data: ${e.response?.data} | Exception: $e',
      );
      throw ApiException(
        message: e.message ?? 'Lỗi kết nối máy chủ',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
