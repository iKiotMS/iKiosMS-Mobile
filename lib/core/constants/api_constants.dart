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

  // Stock movements (import/export/return history, and the ADJUST
  // create/approve/cancel flow — see "Điều chỉnh tồn kho")
  static const String stockMovements = '/stock-movements';
  static String stockMovementDetail(String id) => '/stock-movements/$id';
  static String stockMovementApproveAdjust(String id) => '/stock-movements/$id/approve-adjust';
  static String stockMovementCancel(String id) => '/stock-movements/$id/cancel';

  // Branch / warehouse settings (view + edit the caller's own location only)
  static String branchDetail(String id) => '/branches/$id';
  static String warehouseDetail(String id) => '/warehouses/$id';

  // Branch / warehouse lists (used to build the ADJUST location picker for
  // TENANT_OWNER, who has no single owned branch/warehouse)
  static const String branches = '/branches';
  static const String warehouses = '/warehouses';

  // Promotions — list/detail/usage-log history, plus create/update/deactivate
  // for TENANT_OWNER/BRANCH_MANAGER (see promotion_permissions.dart).
  static const String promotions = '/promotions';
  static String promotionDetail(String id) => '/promotions/$id';
  static String promotionLogs(String id) => '/promotions/$id/logs';

  // Picker option lists for the promotion create/edit form.
  static const String categories = '/categories';
  static const String productItems = '/products/items';
}
