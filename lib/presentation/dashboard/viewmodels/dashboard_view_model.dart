import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/dashboard_stats_model.dart';
import '../../../data/repositories/stats/stats_repository.dart';
import '../../../data/repositories/stats/stats_repository_provider.dart';

part 'dashboard_view_model.g.dart';

/// Preset time ranges for the dashboard, matching the web app's
/// `DashboardRange` ('7d' | '30d' | '90d' | '12m').
enum DashboardRange {
  sevenDays,
  thirtyDays,
  ninetyDays,
  twelveMonths;

  int get days {
    switch (this) {
      case DashboardRange.sevenDays:
        return 7;
      case DashboardRange.thirtyDays:
        return 30;
      case DashboardRange.ninetyDays:
        return 90;
      case DashboardRange.twelveMonths:
        return 365;
    }
  }

  /// Only the 12-month range groups the revenue series by month.
  String get groupBy => this == DashboardRange.twelveMonths ? 'month' : 'day';

  String get label {
    switch (this) {
      case DashboardRange.sevenDays:
        return '7 ngày qua';
      case DashboardRange.thirtyDays:
        return '30 ngày qua';
      case DashboardRange.ninetyDays:
        return '90 ngày qua';
      case DashboardRange.twelveMonths:
        return '12 tháng qua';
    }
  }
}

const List<int> lowStockThresholdOptions = [5, 10, 20, 50];

// ── State ─────────────────────────────────────────────────────────────────

/// Holds all UI state for the branch revenue dashboard screen.
class DashboardState {
  final DashboardRange range;
  final bool isLoading;
  final String? errorMessage;
  final DashboardOverview? overview;
  final RevenueSeries? revenue;
  final RevenueByPaymentMethod? revenueByPaymentMethod;
  final RevenueByStaff? revenueByStaff;
  final DashboardCashflow? cashflow;
  final TopProducts? topProducts;
  final InventoryStats? inventory;
  final String topProductsSortBy; // 'revenue' | 'quantity'
  final int lowStockThreshold;
  final DateTime fromDate;
  final DateTime toDate;

  const DashboardState({
    this.range = DashboardRange.thirtyDays,
    this.isLoading = false,
    this.errorMessage,
    this.overview,
    this.revenue,
    this.revenueByPaymentMethod,
    this.revenueByStaff,
    this.cashflow,
    this.topProducts,
    this.inventory,
    this.topProductsSortBy = 'revenue',
    this.lowStockThreshold = 10,
    required this.fromDate,
    required this.toDate,
  });

  DashboardState copyWith({
    DashboardRange? range,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    DashboardOverview? overview,
    RevenueSeries? revenue,
    RevenueByPaymentMethod? revenueByPaymentMethod,
    RevenueByStaff? revenueByStaff,
    DashboardCashflow? cashflow,
    TopProducts? topProducts,
    InventoryStats? inventory,
    String? topProductsSortBy,
    int? lowStockThreshold,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return DashboardState(
      range: range ?? this.range,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      overview: overview ?? this.overview,
      revenue: revenue ?? this.revenue,
      revenueByPaymentMethod: revenueByPaymentMethod ?? this.revenueByPaymentMethod,
      revenueByStaff: revenueByStaff ?? this.revenueByStaff,
      cashflow: cashflow ?? this.cashflow,
      topProducts: topProducts ?? this.topProducts,
      inventory: inventory ?? this.inventory,
      topProductsSortBy: topProductsSortBy ?? this.topProductsSortBy,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

/// Riverpod-generated notifier for the branch revenue dashboard screen.
///
/// Mirrors the web app's `useDashboardStats` hook: every widget's data is
/// fetched together and a change to the range, the top-products sort, or
/// the low-stock threshold triggers a full refetch of all seven endpoints
/// (not just the affected widget) — replicated here for parity even though
/// it re-fetches more than strictly necessary.
@riverpod
class DashboardViewModel extends _$DashboardViewModel {
  @override
  DashboardState build() {
    final now = DateTime.now();
    const initialRange = DashboardRange.thirtyDays;

    Future.microtask(_loadAll);

    return DashboardState(
      range: initialRange,
      isLoading: true,
      fromDate: now.subtract(Duration(days: initialRange.days)),
      toDate: now,
    );
  }

  StatsRepository get _repository => ref.read(statsRepositoryProvider);

  Future<void> refetch() => _loadAll();

  Future<void> setRange(DashboardRange range) async {
    if (range == state.range) return;
    state = state.copyWith(range: range, isLoading: true, clearError: true);
    await _loadAll();
  }

  Future<void> setTopProductsSortBy(String sortBy) async {
    if (sortBy == state.topProductsSortBy) return;
    state = state.copyWith(
      topProductsSortBy: sortBy,
      isLoading: true,
      clearError: true,
    );
    await _loadAll();
  }

  Future<void> setLowStockThreshold(int threshold) async {
    if (threshold == state.lowStockThreshold) return;
    state = state.copyWith(
      lowStockThreshold: threshold,
      isLoading: true,
      clearError: true,
    );
    await _loadAll();
  }

  Future<void> _loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final now = DateTime.now();
    final range = state.range;
    final fromDate = now.subtract(Duration(days: range.days));
    final fromDateStr = DateTimeUtils.formatApiDate(fromDate);
    final toDateStr = DateTimeUtils.formatApiDate(now);
    final groupBy = range.groupBy;

    try {
      final results = await Future.wait([
        _repository.getOverview(fromDate: fromDateStr, toDate: toDateStr),
        _repository.getRevenue(
          fromDate: fromDateStr,
          toDate: toDateStr,
          groupBy: groupBy,
        ),
        _repository.getRevenueByPaymentMethod(
          fromDate: fromDateStr,
          toDate: toDateStr,
        ),
        _repository.getRevenueByStaff(
          fromDate: fromDateStr,
          toDate: toDateStr,
        ),
        _repository.getCashflow(
          fromDate: fromDateStr,
          toDate: toDateStr,
          flow: 'ORD',
        ),
        _repository.getTopProducts(
          fromDate: fromDateStr,
          toDate: toDateStr,
          sortBy: state.topProductsSortBy,
          limit: 5,
        ),
        _repository.getInventory(lowStockThreshold: state.lowStockThreshold),
      ]);

      state = state.copyWith(
        overview: results[0] as DashboardOverview,
        revenue: results[1] as RevenueSeries,
        revenueByPaymentMethod: results[2] as RevenueByPaymentMethod,
        revenueByStaff: results[3] as RevenueByStaff,
        cashflow: results[4] as DashboardCashflow,
        topProducts: results[5] as TopProducts,
        inventory: results[6] as InventoryStats,
        fromDate: fromDate,
        toDate: now,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Tải dữ liệu thống kê thất bại',
      );
    }
  }
}
