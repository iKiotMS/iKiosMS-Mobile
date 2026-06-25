import 'package:flutter_dotenv/flutter_dotenv.dart';

// Reads BACKEND_URL from the .env file at runtime.
// dotenv is loaded in main.dart before the app starts.
// Note: cannot be `const` because dotenv.env is a runtime map.
String get kBaseUrl => dotenv.env['BACKEND_URL'] ?? '';


// Endpoint paths — change these if your backend routes change.
class ApiEndpoints {
  ApiEndpoints._(); // prevent instantiation

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';

  // GET /working-schedules?userId=123&startDate=yyyy-MM-dd&endDate=yyyy-MM-dd
  static String shifts(String userId, String startDate, String endDate) {
    return '/working-schedules?userId=$userId&startDate=$startDate&endDate=$endDate';
  }

  // GET /working-schedules/{shiftId}
  static String shiftDetail(String shiftId) =>
      '/working-schedules/$shiftId';

  // POST /attendances/check-in
  static const String checkIn = '/attendances/check-in';
}
