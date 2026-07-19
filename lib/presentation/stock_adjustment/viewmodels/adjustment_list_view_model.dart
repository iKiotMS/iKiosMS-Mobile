import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement/stock_movement_repository.dart';
import '../../../data/repositories/stock_movement/stock_movement_repository_provider.dart';

part 'adjustment_list_view_model.g.dart';

const int _limit = 50;

// ── State ─────────────────────────────────────────────────────────────────

/// Holds all UI state for "Điều chỉnh tồn kho" (list of ADJUST requests).
/// Scoping to the caller's own branch/warehouse (for BRANCH_MANAGER/
/// WAREHOUSE_MANAGER) happens server-side — same as the read-only IMPORT/
/// EXPORT/RETURN history screen.
class AdjustmentListState {
  final bool isLoading;
  final List<StockMovement> adjustments;

  /// null = all statuses. Sent to the server.
  final String? statusFilter;

  final String? errorMessage;

  const AdjustmentListState({
    this.isLoading = false,
    this.adjustments = const [],
    this.statusFilter,
    this.errorMessage,
  });

  AdjustmentListState copyWith({
    bool? isLoading,
    List<StockMovement>? adjustments,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdjustmentListState(
      isLoading: isLoading ?? this.isLoading,
      adjustments: adjustments ?? this.adjustments,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

@riverpod
class AdjustmentListViewModel extends _$AdjustmentListViewModel {
  @override
  AdjustmentListState build() {
    Future.microtask(_load);
    return const AdjustmentListState(isLoading: true);
  }

  StockMovementRepository get _repository => ref.read(stockMovementRepositoryProvider);

  Future<void> refetch() => _load();

  Future<void> setStatusFilter(String? status) async {
    if (status == state.statusFilter) return;
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null, isLoading: true, clearError: true);
    await _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await _repository.getList(
        movementType: 'ADJUST',
        status: state.statusFilter,
        page: 1,
        limit: _limit,
      );
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(adjustments: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tải danh sách điều chỉnh tồn kho thất bại');
    }
  }
}
