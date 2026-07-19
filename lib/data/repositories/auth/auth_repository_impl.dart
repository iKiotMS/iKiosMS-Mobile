import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/auth_token_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../models/user_model.dart';
import '../../services/auth_api_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiService _apiService;
  final AuthToken _authTokenNotifier;

  AuthRepositoryImpl(this._apiService, this._authTokenNotifier);

  Future<void> _persistSession(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;

    if (accessToken == null || refreshToken == null || userJson == null) {
      throw const ApiException(
        message: 'Dữ liệu trả về từ máy chủ không hợp lệ.',
      );
    }

    await _authTokenNotifier.setTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userJson['id'].toString(),
    );
  }

  @override
  Future<UserModel> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final data = await _apiService.login(phoneNumber, password);
      await _persistSession(data);
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ?? 'Lỗi kết nối máy chủ.';
      throw ApiException(message: message, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    try {
      // 1. Google account picker.
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User dismissed the picker — not a server error.
        throw const ApiException(message: 'Đã hủy đăng nhập Google.');
      }

      // 2. Sign in to Firebase with the Google credential so we can obtain a
      //    Firebase ID token (that is what the backend verifies).
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        throw const ApiException(
          message: 'Không lấy được mã xác thực từ Google.',
        );
      }

      // 3. Exchange it for our session tokens.
      final data = await _apiService.firebaseLogin(firebaseIdToken);
      await _persistSession(data);

      // 4. Drop the Firebase/Google client sessions — we only needed the token.
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
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

  @override
  Future<UserModel> updateEmail(String email) async {
    try {
      final responseData = await _apiService.updateProfile({'email': email});
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
