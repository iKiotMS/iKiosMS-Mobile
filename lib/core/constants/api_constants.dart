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

  // Profile
  static const String me = '/auth/me';

  // AI Chat
  static const String aiChat = '/ai/chat';
  static const String aiConversations = '/ai/conversations';
  static String aiConversationDetail(String id) => '/ai/conversations/$id';
  static String deleteAiConversation(String id) => '/ai/conversations/$id';
  static String renameAiConversation(String id) => '/ai/conversations/$id';

  // Dashboard stats (backend scopes these to the caller's branch/tenant automatically)
  static const String statsOverview = '/stats/overview';
  static const String statsRevenue = '/stats/revenue';
  static const String statsRevenueByPaymentMethod = '/stats/revenue-by-payment-method';
  static const String statsRevenueByStaff = '/stats/revenue-by-staff';
  static const String statsCashflow = '/stats/cashflow';
  static const String statsTopProducts = '/stats/top-products';
  static const String statsInventory = '/stats/inventory';

  // Inventory (per-location stock list — warehouse/branch inventory management)
  static const String inventory = '/inventory';
  static String inventoryMinStock(String id) => '/inventory/$id/min-stock';
  static String inventoryItem(String id) => '/inventory/$id';

  // Stock movements (import/export/return/adjust history — read-only here)
  static const String stockMovements = '/stock-movements';
  static String stockMovementDetail(String id) => '/stock-movements/$id';

  // Branch / warehouse settings (view + edit the caller's own location only)
  static String branchDetail(String id) => '/branches/$id';
  static String warehouseDetail(String id) => '/warehouses/$id';
}
