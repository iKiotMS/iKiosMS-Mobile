import '../../models/dashboard_stats_model.dart';

/// Abstract interface for the dashboard stats repository.
///
/// The ViewModel depends on this interface, not the concrete implementation.
abstract class StatsRepository {
  Future<DashboardOverview> getOverview({
    required String fromDate,
    required String toDate,
  });

  Future<RevenueSeries> getRevenue({
    required String fromDate,
    required String toDate,
    required String groupBy,
  });

  Future<RevenueByPaymentMethod> getRevenueByPaymentMethod({
    required String fromDate,
    required String toDate,
  });

  Future<RevenueByStaff> getRevenueByStaff({
    required String fromDate,
    required String toDate,
  });

  /// [flow] filters by payment reference prefix ('ORD' | 'SUP' | 'PAYR');
  /// the branch dashboard always passes 'ORD' (sales-only cashflow).
  Future<DashboardCashflow> getCashflow({
    required String fromDate,
    required String toDate,
    String? flow,
  });

  Future<TopProducts> getTopProducts({
    required String fromDate,
    required String toDate,
    required String sortBy,
    required int limit,
  });

  Future<InventoryStats> getInventory({required int lowStockThreshold});
}
