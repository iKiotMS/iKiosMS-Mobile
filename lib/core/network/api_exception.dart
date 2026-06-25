/// A simple exception class for API errors.
///
/// Thrown by the repository when an HTTP request fails or
/// the backend returns an unexpected error.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}
