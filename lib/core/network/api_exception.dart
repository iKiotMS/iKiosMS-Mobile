/// A simple exception class for API errors.
///
/// Thrown by the repository when an HTTP request fails or
/// the backend returns an unexpected error.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  /// Maps a Dio-style exception / response body into a user-facing message.
  ///
  /// Backend may return `{ message }` or `{ error }` (staff create uses `error`).
  factory ApiException.fromDio(Object error) {
    final response = _readResponse(error);
    final statusCode = response?.statusCode as int?;
    final fromBody = _messageFromBody(response?.data);
    String? fallback;
    try {
      fallback = (error as dynamic).message?.toString();
    } catch (_) {
      fallback = null;
    }

    return ApiException(
      message:
          fromBody ??
          (fallback != null && fallback.isNotEmpty
              ? fallback
              : 'Lỗi kết nối máy chủ'),
      statusCode: statusCode,
    );
  }

  static dynamic _readResponse(Object error) {
    try {
      return (error as dynamic).response;
    } catch (_) {
      return null;
    }
  }

  static String? _messageFromBody(dynamic data) {
    if (data is! Map) return null;
    final message = data['message']?.toString();
    if (message != null && message.trim().isNotEmpty) return message.trim();
    final err = data['error']?.toString();
    if (err != null && err.trim().isNotEmpty) return err.trim();
    return null;
  }

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}

/// Returns a short message that can be shown directly in the UI.
String readableApiError(Object error) {
  if (error is ApiException) return error.message;

  final apiError = ApiException.fromDio(error);
  if (apiError.message != 'Lỗi kết nối máy chủ') {
    return apiError.message;
  }

  final message = error.toString();
  return message.startsWith('Exception: ')
      ? message.substring('Exception: '.length)
      : message;
}
