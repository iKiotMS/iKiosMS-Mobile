import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/cash_flow_model.dart';
import '../../../data/repositories/cash_flow/cash_flow_repository.dart';
import '../../../data/repositories/cash_flow/cash_flow_repository_provider.dart';

part 'cash_flow_view_model.g.dart';

const int _kPageSize = 20;

/// Preset date ranges offered in the filter bar.
enum CashFlowRange { today, last7Days, thisMonth, last30Days }

extension CashFlowRangeX on CashFlowRange {
  String get label {
    switch (this) {
      case CashFlowRange.today:
        return 'Hôm nay';
      case CashFlowRange.last7Days:
        return '7 ngày';
      case CashFlowRange.thisMonth:
        return 'Tháng này';
      case CashFlowRange.last30Days:
        return '30 ngày';
    }
  }

  /// Resolves this preset to a concrete `[from, to]` day range around [now].
  ({DateTime from, DateTime to}) resolve(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case CashFlowRange.today:
        return (from: today, to: today);
      case CashFlowRange.last7Days:
        return (from: today.subtract(const Duration(days: 6)), to: today);
      case CashFlowRange.thisMonth:
        return (from: DateTime(now.year, now.month, 1), to: today);
      case CashFlowRange.last30Days:
        return (from: today.subtract(const Duration(days: 29)), to: today);
    }
  }
}

/// Optional income/expense filter. `null` value means "all".
enum CashFlowTypeFilter { all, income, expense }

extension CashFlowTypeFilterX on CashFlowTypeFilter {
  String get label {
    switch (this) {
      case CashFlowTypeFilter.all:
        return 'Tất cả';
      case CashFlowTypeFilter.income:
        return 'Thu';
      case CashFlowTypeFilter.expense:
        return 'Chi';
    }
  }

  String? get flowType {
    switch (this) {
      case CashFlowTypeFilter.all:
        return null;
      case CashFlowTypeFilter.income:
        return 'INCOME';
      case CashFlowTypeFilter.expense:
        return 'EXPENSE';
    }
  }
}

// ── State ────────────────────────────────────────────────────────────────────

class CashFlowState {
  final CashFlowRange range;
  final CashFlowTypeFilter typeFilter;
  final String? branchId; // null = all branches (TENANT_OWNER only)
  final CashFlowSummary summary;
  final List<CashFlowEntry> entries;
  final int page;
  final int totalPages;
  final bool isLoading; // first load / filter change
  final bool isLoadingMore;
  final String? errorMessage;

  const CashFlowState({
    this.range = CashFlowRange.thisMonth,
    this.typeFilter = CashFlowTypeFilter.all,
    this.branchId,
    this.summary = CashFlowSummary.empty,
    this.entries = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get hasMore => page < totalPages;

  CashFlowState copyWith({
    CashFlowRange? range,
    CashFlowTypeFilter? typeFilter,
    String? branchId,
    bool clearBranch = false,
    CashFlowSummary? summary,
    List<CashFlowEntry>? entries,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CashFlowState(
      range: range ?? this.range,
      typeFilter: typeFilter ?? this.typeFilter,
      branchId: clearBranch ? null : (branchId ?? this.branchId),
      summary: summary ?? this.summary,
      entries: entries ?? this.entries,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── ViewModel ────────────────────────────────────────────────────────────────

/// Owns the state of the "Sổ thu chi" screen: loads the summary + first page,
/// re-loads on filter changes, and appends pages on scroll.
@riverpod
class CashFlowViewModel extends _$CashFlowViewModel {
  @override
  CashFlowState build() {
    Future.microtask(_load);
    return const CashFlowState(isLoading: true);
  }

  CashFlowRepository get _repository => ref.read(cashFlowRepositoryProvider);

  /// Change the date-range preset and reload.
  Future<void> setRange(CashFlowRange range) async {
    if (range == state.range) return;
    state = state.copyWith(range: range, isLoading: true, clearError: true);
    await _load();
  }

  /// Change the income/expense filter and reload.
  Future<void> setTypeFilter(CashFlowTypeFilter filter) async {
    if (filter == state.typeFilter) return;
    state = state.copyWith(typeFilter: filter, isLoading: true, clearError: true);
    await _load();
  }

  /// Change the branch filter (TENANT_OWNER only) and reload.
  /// Pass `null` for "all branches".
  Future<void> setBranch(String? branchId) async {
    if (branchId == state.branchId) return;
    state = state.copyWith(
      branchId: branchId,
      clearBranch: branchId == null,
      isLoading: true,
      clearError: true,
    );
    await _load();
  }

  /// Pull-to-refresh: reload the summary + first page for the current filters.
  Future<void> refresh() => _load();

  /// Loads summary + first page in parallel for the current filters.
  Future<void> _load() async {
    final now = DateTime.now();
    final r = state.range.resolve(now);
    final flowType = state.typeFilter.flowType;
    try {
      final results = await Future.wait([
        _repository.getSummary(
          fromDate: r.from,
          toDate: r.to,
          flowType: flowType,
          branchId: state.branchId,
        ),
        _repository.getTransactions(
          fromDate: r.from,
          toDate: r.to,
          flowType: flowType,
          branchId: state.branchId,
          page: 1,
          limit: _kPageSize,
        ),
      ]);
      final summary = results[0] as CashFlowSummary;
      final firstPage = results[1] as CashFlowPage;
      state = state.copyWith(
        summary: summary,
        entries: firstPage.items,
        page: firstPage.page,
        totalPages: firstPage.totalPages,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFor(e),
      );
    }
  }

  /// Append the next page of entries when scrolling near the bottom.
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final now = DateTime.now();
    final r = state.range.resolve(now);
    try {
      final next = await _repository.getTransactions(
        fromDate: r.from,
        toDate: r.to,
        flowType: state.typeFilter.flowType,
        branchId: state.branchId,
        page: state.page + 1,
        limit: _kPageSize,
      );
      state = state.copyWith(
        entries: [...state.entries, ...next.items],
        page: next.page,
        totalPages: next.totalPages,
        isLoadingMore: false,
      );
    } catch (_) {
      // Keep the entries already loaded; just stop the spinner.
      state = state.copyWith(isLoadingMore: false);
    }
  }

  String _messageFor(Object e) {
    final text = e.toString();
    if (text.contains('403')) {
      return 'Bạn không có quyền xem sổ thu chi.';
    }
    return 'Không thể tải sổ thu chi. Vui lòng thử lại.';
  }
}
