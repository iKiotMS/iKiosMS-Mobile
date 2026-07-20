import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_token_provider.dart';
import '../constants/api_constants.dart';

part 'api_client.g.dart';

/// Riverpod-generated provider that returns a configured [Dio] instance.
///
/// All HTTP calls in the app go through this single Dio client.
/// To add authentication, update the interceptor below.
@riverpod
Dio apiClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Attach the Bearer token to all requests if the user is logged in.
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Read the current state of the token synchronously.
        // Because we wait for it to load on app startup, it should be available.
        final tokenState = ref.read(authTokenProvider);
        if (tokenState.value != null) {
          options.headers['Authorization'] = 'Bearer ${tokenState.value}';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        // If we get a 401 Unauthorized, or 403 Invalid/expired token, try to refresh
        final isTokenExpired = e.response?.statusCode == 401 ||
            (e.response?.statusCode == 403 &&
                e.response?.data != null &&
                (e.response?.data is Map) &&
                e.response?.data['message'] == 'Invalid or expired token.');

        if (isTokenExpired) {
          final notifier = ref.read(authTokenProvider.notifier);
          final refreshToken = await notifier.getRefreshToken();

          if (refreshToken != null) {
            try {
              // Use a clean Dio instance to avoid interceptor loops
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: kBaseUrl,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ),
              );

              final response = await refreshDio.post(ApiEndpoints.refresh, data: {
                'refreshToken': refreshToken,
              });

              if (response.statusCode == 200 || response.statusCode == 201) {
                // The structure could be response.data['accessToken'] or response.data['data']['accessToken']
                // Depending on the backend wrapper, we safely extract it:
                final data = response.data['data'] ?? response.data;
                final newAccessToken = data['accessToken'] as String?;
                final newRefreshToken = data['refreshToken'] as String?;

                if (newAccessToken != null && newRefreshToken != null) {
                  final userId = await notifier.getUserId() ?? '';
                  
                  // Save the new tokens
                  await notifier.setTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                    userId: userId,
                  );

                  // Update the original request's headers and retry
                  final options = e.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newAccessToken';

                  final retryDio = Dio(BaseOptions(baseUrl: kBaseUrl));
                  final retryResponse = await retryDio.fetch(options);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (_) {
              // Refresh failed (e.g., refresh token expired)
            }
          }
          
          // No refresh token available or refresh failed: force logout
          await notifier.clearTokens();
        }
        
        // Pass the error along if not 401 or if retry failed
        return handler.next(e);
      },
    ),
  );

  return dio;
}
