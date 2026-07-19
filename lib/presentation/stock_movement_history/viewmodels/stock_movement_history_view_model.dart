import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement/stock_movement_repository.dart';
import '../../../data/repositories/stock_movement/stock_movement_repository_provider.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'stock_movement_history_view_model.g.dart';

const int _perTypeLimit = 50;

// ── State ─────────────────────────────────────────────────────────────────

/// Holds all UI state for "Lịch sử nhập/xuất kho".
class StockMovementHistoryState {
  final bool isLoading;
  final List<StockMovement> movements;

  /// Types this signed-in role is allowed to see (see [StockMovementHistoryViewModel._init]).
  /// Defaults to all of [stockMovementHistoryTypes] until the profile loads.
  final List<String> visibleTypes;

  /// null = all of [visibleTypes]; otherwise one type. Must be a member of
  /// [visibleTypes].
  final String? typeFilter;

  /// null = all statuses. Sent to the server (unlike [searchQuery]).
  final String? statusFilter;

  /// Client-side only — filters the already-fetched [movements], mirroring
  /// the web table's TanStack `globalFilter` (no server-side search param
  /// exists for this endpoint).
  final String searchQuery;

  final String? errorMessage;

  const StockMovementHistoryState({
    this.isLoading = false,
    this.movements = const [],
    this.visibleTypes = stockMovementHistoryTypes,
    this.typeFilter,
    this.statusFilter,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<StockMovement> get filteredMovements {
    if (searchQuery.isEmpty) return movements;
    final query = searchQuery.toLowerCase();
    return movements.where((m) {
      final code = m.id.length >= 6 ? m.id.substring(m.id.length - 6) : m.id;
      return code.toLowerCase().contains(query) ||
          (m.fromLocationName?.toLowerCase().contains(query) ?? false) ||
          (m.toLocationName?.toLowerCase().contains(query) ?? false) ||
          (m.supplierName?.toLowerCase().contains(query) ?? false) ||
          m.requestedByName.toLowerCase().contains(query);
    }).toList();
  }

  StockMovementHistoryState copyWith({
    bool? isLoading,
    List<StockMovement>? movements,
    List<String>? visibleTypes,
    String? typeFilter,
    bool clearTypeFilter = false,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StockMovementHistoryState(
      isLoading: isLoading ?? this.isLoading,
      movements: movements ?? this.movements,
      visibleTypes: visibleTypes ?? this.visibleTypes,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

/// Riverpod-generated notifier for the read-only stock movement history.
///
/// Mirrors the web `/exchange/exports` provider's pattern of issuing one
/// `GET /stock-movements?movementType=X` request per type and merging the
/// results client-side, sorted by `createdAt` desc — the same approach the
/// web app already uses to combine EXPORT+RETURN into one list. This
/// screen extends that to IMPORT+EXPORT+RETURN (ADJUST is a separate flow),
/// except for BRANCH_MANAGER: the web app's `canAccessImports` blocklist
/// redirects BRANCH_MANAGER away from the imports list entirely, so this
/// notifier excludes IMPORT for that role too (see [_init]) even though the
/// backend would technically allow reading it for their own branch.
@riverpod
class StockMovementHistoryViewModel extends _$StockMovementHistoryViewModel {
  @override
  StockMovementHistoryState build() {
    Future.microtask(_init);
    return const StockMovementHistoryState(isLoading: true);
  }

  StockMovementRepository get _repository => ref.read(stockMovementRepositoryProvider);

  Future<void> refetch() => _load();

  Future<void> _init() async {
    final profile = await ref.read(userProfileProvider.future);
    final visibleTypes = profile?.role == 'BRANCH_MANAGER'
        ? stockMovementHistoryTypes.where((t) => t != 'IMPORT').toList()
        : stockMovementHistoryTypes;

    state = state.copyWith(visibleTypes: visibleTypes);
    await _load();
  }

  Future<void> setTypeFilter(String? type) async {
    if (type == state.typeFilter) return;
    state = state.copyWith(typeFilter: type, clearTypeFilter: type == null, isLoading: true, clearError: true);
    await _load();
  }

  Future<void> setStatusFilter(String? status) async {
    if (status == state.statusFilter) return;
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null, isLoading: true, clearError: true);
    await _load();
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final types = state.typeFilter != null ? [state.typeFilter!] : state.visibleTypes;

    try {
      final results = await Future.wait([
        for (final type in types)
          _repository.getList(
            movementType: type,
            status: state.statusFilter,
            page: 1,
            limit: _perTypeLimit,
          ),
      ]);

      final merged = results.expand((list) => list).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(movements: merged, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tải lịch sử nhập/xuất kho thất bại');
    }
  }
}
