import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'package:geolocator/geolocator.dart';

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
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final rawList = await _apiService.getShifts(
        userId: userId,
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

  @override
  Future<ShiftModel> checkIn(String shiftId) async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const ApiException(
          message: 'Dịch vụ định vị đang tắt. Vui lòng bật GPS.',
        );
      }

      // 2. Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const ApiException(
            message:
                'Bạn đã từ chối quyền truy cập vị trí. Không thể chấm công.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw const ApiException(
          message:
              'Quyền vị trí đã bị từ chối vĩnh viễn. Vui lòng mở Cài đặt để cấp quyền.',
        );
      }

      // 3. Get current location
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 4. Call API
      final raw = await _apiService.checkIn(
        scheduleId: shiftId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      developer.log(
        '✅ [ShiftRepository] Check-in API SUCCESS! Raw response payload: $raw',
      );

      return ShiftModel.fromJson(raw);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      developer.log(
        '❌ [ShiftRepository] Check-in API FAILED! Error data: ${e.response?.data} | Exception: $e',
      );
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.message ??
            'Lỗi kết nối máy chủ',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: 'Không thể định vị: $e');
    }
  }
}
