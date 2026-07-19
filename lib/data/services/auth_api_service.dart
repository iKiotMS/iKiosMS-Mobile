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

  /// Exchanges a Firebase ID token (from Google sign-in) for backend session
  /// tokens. `platform: 'mobile'` tells the backend to apply the employee-only
  /// role gate. Returns the raw LoginResponseDTO map.
  Future<Map<String, dynamic>> firebaseLogin(String idToken) async {
    final response = await _dio.post(
      ApiEndpoints.firebaseLogin,
      data: {
        'idToken': idToken,
        'platform': 'mobile',
      },
    );
    return response.data;
  }

  /// Fetches profile of the currently logged-in user.
  /// Returns raw JSON map representing UserProfileResponseDTO from backend.
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(ApiEndpoints.me);
    return response.data;
  }

  /// Updates the current user's profile (PATCH /auth/me). Pass only the fields
  /// to change, e.g. `{ 'email': '...' }`.
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final response = await _dio.patch(ApiEndpoints.me, data: body);
    return response.data;
  }
}
