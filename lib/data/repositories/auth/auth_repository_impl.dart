import 'package:dio/dio.dart';

import '../../../core/auth/auth_token_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../models/user_model.dart';
import '../../services/auth_api_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _apiService;
  final AuthToken _authTokenNotifier;

  AuthRepositoryImpl(this._apiService, this._authTokenNotifier);

  @override
  Future<UserModel> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final data = await _apiService.login(phoneNumber, password);

      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (accessToken == null || refreshToken == null || userJson == null) {
        throw const ApiException(
          message: 'Dữ liệu trả về từ máy chủ không hợp lệ.',
        );
      }

      // Save tokens using the Riverpod notifier which also persists to secure storage
      await _authTokenNotifier.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userJson['id'].toString(),
      );

      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ?? 'Lỗi kết nối máy chủ.';
      throw ApiException(message: message, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _authTokenNotifier.clearTokens();
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final responseData = await _apiService.getProfile();
      final userData = responseData['data'] as Map<String, dynamic>?;
      if (userData == null) {
        throw const ApiException(message: 'Dữ liệu người dùng không hợp lệ.');
      }
      return UserModel.fromProfileJson(userData);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ?? 'Lỗi kết nối máy chủ.';
      throw ApiException(message: message, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
