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
  static const String firebaseLogin = '/auth/firebase-login';
  static const String refresh = '/auth/refresh';

  // Push notifications — register/unregister this device's FCM token.
  static const String deviceToken = '/notifications/device-token';

  // In-app notification inbox.
  static String notifications({int page = 1, int limit = 20}) =>
      '/notifications?page=$page&limit=$limit';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // GET /working-schedules?userId=123&startDate=yyyy-MM-dd&endDate=yyyy-MM-dd
  static String shifts(String userId, String startDate, String endDate) {
    return '/working-schedules?userId=$userId&startDate=$startDate&endDate=$endDate';
  }

  // GET /working-schedules/{shiftId}
  static String shiftDetail(String shiftId) =>
      '/working-schedules/$shiftId';

  // POST /attendances/check-in
  static const String checkIn = '/attendances/check-in';

  // Sổ thu chi (cashflow) — Owner/Manager only (backend requires reports:read).
  // Query params (fromDate/toDate as yyyy-MM-dd, flowType, paymentMethod, page,
  // limit) are passed via Dio queryParameters, not baked into the path.
  static const String cashflowSummary = '/stats/cashflow';
  static const String cashflowTransactions = '/stats/cashflow/transactions';

  // Branch list — powers the cashflow branch picker (TENANT_OWNER filters by
  // branch). Query params (limit, status) passed via Dio queryParameters.
  static const String branches = '/branches';

  // Profile
  static const String me = '/auth/me';

  // AI Chat
  static const String aiChat = '/ai/chat';
  static const String aiConversations = '/ai/conversations';
  static String aiConversationDetail(String id) => '/ai/conversations/$id';
  static String deleteAiConversation(String id) => '/ai/conversations/$id';
  static String renameAiConversation(String id) => '/ai/conversations/$id';
}
