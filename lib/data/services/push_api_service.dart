import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'push_api_service.g.dart';

@riverpod
PushApiService pushApiService(Ref ref) {
  return PushApiService(ref.read(apiClientProvider));
}

/// Raw HTTP for registering/unregistering this device's FCM token with the
/// backend (`/notifications/device-token`). No logic here — see PushService.
class PushApiService {
  final Dio _dio;

  PushApiService(this._dio);

  Future<void> registerToken(String token) async {
    await _dio.post(ApiEndpoints.deviceToken, data: {'token': token});
  }

  Future<void> removeToken(String token) async {
    await _dio.delete(ApiEndpoints.deviceToken, data: {'token': token});
  }
}
