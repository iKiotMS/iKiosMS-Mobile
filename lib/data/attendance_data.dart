import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';

class AttendanceModel {
  final String id;
  final String status;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;

  const AttendanceModel({
    required this.id,
    required this.status,
    this.checkedInAt,
    this.checkedOutAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      checkedInAt: DateTime.tryParse(json['actualCheckinAt']?.toString() ?? ''),
      checkedOutAt: DateTime.tryParse(
        json['actualCheckoutAt']?.toString() ?? '',
      ),
    );
  }
}

class AttendanceApi {
  final Dio dio;

  AttendanceApi(this.dio);

  Future<AttendanceModel?> getOpenAttendance() async {
    final response = await dio.get(
      ApiEndpoints.myAttendances,
      queryParameters: {'missingCheckout': true, 'page': 1, 'recordPerPage': 1},
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    final list = body['data'] as List? ?? const [];
    if (list.isEmpty) return null;
    return AttendanceModel.fromJson(
      Map<String, dynamic>.from(list.first as Map),
    );
  }

  Future<void> checkIn(String scheduleId) async {
    final position = await _getPosition();
    await dio.post(
      ApiEndpoints.checkIn,
      data: {
        'scheduleId': scheduleId,
        'actualCheckinAt': DateTime.now().toUtc().toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      },
    );
  }

  Future<void> checkOut(String attendanceId) async {
    final position = await _getPosition();
    await dio.post(
      ApiEndpoints.checkOut,
      data: {
        'attendanceId': attendanceId,
        'actualCheckoutAt': DateTime.now().toUtc().toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      },
    );
  }

  Future<Position> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('Vui lòng bật GPS để chấm công.');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Bạn chưa cấp quyền vị trí để chấm công.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}

final attendanceApiProvider = Provider<AttendanceApi>((ref) {
  return AttendanceApi(ref.watch(apiClientProvider));
});

class AttendanceState {
  final bool loading;
  final bool submitting;
  final AttendanceModel? openAttendance;
  final String? error;

  const AttendanceState({
    this.loading = false,
    this.submitting = false,
    this.openAttendance,
    this.error,
  });
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceApi api;

  AttendanceNotifier(this.api) : super(const AttendanceState(loading: true)) {
    load();
  }

  Future<void> load() async {
    state = AttendanceState(
      loading: true,
      openAttendance: state.openAttendance,
    );
    try {
      final attendance = await api.getOpenAttendance();
      state = AttendanceState(openAttendance: attendance);
    } catch (error) {
      state = AttendanceState(
        openAttendance: state.openAttendance,
        error: readableApiError(error),
      );
    }
  }

  Future<String?> submit({String? scheduleId}) async {
    state = AttendanceState(
      submitting: true,
      openAttendance: state.openAttendance,
    );
    try {
      if (state.openAttendance == null) {
        if (scheduleId == null) {
          throw Exception('Thiếu thông tin ca làm việc.');
        }
        await api.checkIn(scheduleId);
      } else {
        await api.checkOut(state.openAttendance!.id);
      }
      await load();
      return null;
    } catch (error) {
      final message = readableApiError(error);
      state = AttendanceState(
        openAttendance: state.openAttendance,
        error: message,
      );
      return message;
    }
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
      return AttendanceNotifier(ref.watch(attendanceApiProvider));
    });
