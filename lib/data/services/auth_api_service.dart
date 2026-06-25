import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'auth_api_service.g.dart';

@riverpod
AuthApiService authApiService(Ref ref) {
  return AuthApiService(ref.read(apiClientProvider));
}

class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  /// Logs in using phone number and password.
  /// Returns raw JSON map representing LoginResponseDTO from backend.
  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );
    return response.data;
  }
}
