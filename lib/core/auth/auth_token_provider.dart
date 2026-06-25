import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_token_provider.g.dart';

const _kAccessTokenKey = 'access_token';
const _kRefreshTokenKey = 'refresh_token';
const _kUserIdKey = 'user_id';

/// Manages the authentication state across the app.
///
/// Keeps the token in memory and persists it securely to the device.
/// Because reading from storage is async, this provider returns a [Future] of [String].
@Riverpod(keepAlive: true)
class AuthToken extends _$AuthToken {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  @override
  Future<String?> build() async {
    // Read the stored access token when the app starts
    return await _storage.read(key: _kAccessTokenKey);
  }

  /// Retrieves the stored userId synchronously if it has been loaded
  /// Since we only need it after login, reading it this way is convenient.
  Future<String?> getUserId() async {
    return await _storage.read(key: _kUserIdKey);
  }

  /// Retrieves the stored refresh token securely
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _kRefreshTokenKey);
  }

  /// Saves the tokens and user info to secure storage and updates the state.
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _storage.write(key: _kAccessTokenKey, value: accessToken);
    await _storage.write(key: _kRefreshTokenKey, value: refreshToken);
    await _storage.write(key: _kUserIdKey, value: userId);
    // Update Riverpod state so listeners (like the router) rebuild.
    state = AsyncData(accessToken);
  }

  /// Removes tokens from secure storage and clears the state.
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
    await _storage.delete(key: _kUserIdKey);
    state = const AsyncData(null);
  }
}
