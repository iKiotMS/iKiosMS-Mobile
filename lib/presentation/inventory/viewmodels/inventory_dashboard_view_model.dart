import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/dashboard_stats_model.dart';
import '../../../data/models/inventory_item_model.dart';
import '../../../data/repositories/inventory/inventory_repository.dart';
import '../../../data/repositories/inventory/inventory_repository_provider.dart';
import '../../../data/repositories/stats/stats_repository.dart';
import '../../../data/repositories/stats/stats_repository_provider.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'inventory_dashboard_view_model.g.dart';

const int inventoryPageSize = 20;

// ── State ─────────────────────────────────────────────────────────────────

/// Holds all UI state for the "Dashboard, Quản lý tồn kho / kho" screen.
class InventoryDashboardState {
  final bool isLoadingSummary;
  final InventoryStats? summary;
  final int lowStockThreshold;

  final bool isLoadingList;
  final bool isLoadingMore;
  final List<InventoryItemModel> items;
  final int page;
  final int totalPages;
  final bool isLowStockOnly;
  final String search;

  /// True for TENANT_OWNER/BRANCH_MANAGER/WAREHOUSE_MANAGER — everyone who
  /// reaches this screen — per `PATCH /inventory/:id/min-stock`'s
  /// `inventory:["update"|"manage"]` permission (`permissions.json`), which
  /// BRANCH_MANAGER *does* have (unlike the remove permission below).
  final bool canEditMinStock;

  /// True only for TENANT_OWNER/WAREHOUSE_MANAGER, per `DELETE /inventory/:id`'s
  /// role gate in `inventory/index.js` (BRANCH_MANAGER is not included).
  final bool canRemove;

  final String? errorMessage;

  const InventoryDashboardState({
    this.isLoadingSummary = false,
    this.summary,
    this.lowStockThreshold = 10,
    this.isLoadingList = false,
    this.isLoadingMore = false,
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLowStockOnly = false,
    this.search = '',
    this.canEditMinStock = false,
    this.canRemove = false,
    this.errorMessage,
  });

  bool get hasMore => page < totalPages;

  InventoryDashboardState copyWith({
    bool? isLoadingSummary,
    InventoryStats? summary,
    int? lowStockThreshold,
    bool? isLoadingList,
    bool? isLoadingMore,
    List<InventoryItemModel>? items,
    int? page,
    int? totalPages,
    bool? isLowStockOnly,
    String? search,
    bool? canEditMinStock,
    bool? canRemove,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InventoryDashboardState(
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      summary: summary ?? this.summary,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLowStockOnly: isLowStockOnly ?? this.isLowStockOnly,
      search: search ?? this.search,
      canEditMinStock: canEditMinStock ?? this.canEditMinStock,
      canRemove: canRemove ?? this.canRemove,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

/// Riverpod-generated notifier for the warehouse/branch inventory dashboard.
///
/// Combines two backend sources:
/// - `GET /stats/inventory` (already scoped server-side per role) for the
///   summary cards (stock value, total units, SKU count, out-of-stock).
/// - `GET /inventory` (NOT scoped server-side — the caller's `locationId`
///   is trusted as-is) for the searchable/paginated/editable item list, so
///   this notifier must resolve and pass the caller's own branch/warehouse
///   id itself, mirroring the web app's client-side `auth-scope.ts` pattern.
@riverpod
class InventoryDashboardViewModel extends _$InventoryDashboardViewModel {
  String? _locationId;
  String? _locationType;

  @override
  InventoryDashboardState build() {
    Future.microtask(_init);
    return const InventoryDashboardState(
      isLoadingSummary: true,
      isLoadingList: true,
    );
  }

  StatsRepository get _statsRepository => ref.read(statsRepositoryProvider);
  InventoryRepository get _inventoryRepository => ref.read(inventoryRepositoryProvider);

  Future<void> _init() async {
    final profile = await ref.read(userProfileProvider.future);
    if (profile == null) {
      state = state.copyWith(
        isLoadingSummary: false,
        isLoadingList: false,
        errorMessage: 'Không tìm thấy thông tin người dùng.',
      );
      return;
    }

    switch (profile.role) {
      case 'WAREHOUSE_MANAGER':
        _locationId = profile.warehouseId;
        _locationType = 'warehouse';
      case 'BRANCH_MANAGER':
        _locationId = profile.branchId;
        _locationType = 'branch';
      default:
        // TENANT_OWNER (and any other privileged role reaching this screen):
        // no location filter — view stock across the whole tenant.
        _locationId = null;
        _locationType = null;
    }

    if (_locationType != null && _locationId == null) {
      state = state.copyWith(
        isLoadingSummary: false,
        isLoadingList: false,
        errorMessage: 'Tài khoản chưa được gán chi nhánh/kho.',
      );
      return;
    }

    state = state.copyWith(
      // inventory:["update"|"manage"] — TENANT_OWNER/BRANCH_MANAGER/WAREHOUSE_MANAGER all have it.
      canEditMinStock: profile.role != 'STAFF',
      // DELETE /inventory/:id role gate — TENANT_OWNER/WAREHOUSE_MANAGER only.
      canRemove: profile.role == 'TENANT_OWNER' || profile.role == 'WAREHOUSE_MANAGER',
    );
    await Future.wait([_loadSummary(), _loadList(reset: true)]);
  }

  Future<void> refetch() => Future.wait([_loadSummary(), _loadList(reset: true)]);

  Future<void> loadMore() {
    if (!state.hasMore || state.isLoadingMore || state.isLoadingList) {
      return Future.value();
    }
    return _loadList();
  }

  Future<void> setSearch(String value) async {
    if (value == state.search) return;
    state = state.copyWith(search: value);
    await _loadList(reset: true);
  }

  Future<void> toggleLowStockOnly(bool value) async {
    if (value == state.isLowStockOnly) return;
    state = state.copyWith(isLowStockOnly: value);
    await _loadList(reset: true);
  }

  Future<void> setLowStockThreshold(int threshold) async {
    if (threshold == state.lowStockThreshold) return;
    state = state.copyWith(lowStockThreshold: threshold);
    await _loadSummary();
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> updateMinStock(String inventoryId, int minStock) async {
    try {
      final updated = await _inventoryRepository.updateMinStock(
        inventoryId: inventoryId,
        minStock: minStock,
      );
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == updated.id) item.copyWith(minStock: updated.minStock) else item,
        ],
      );
      return null;
    } catch (e) {
      return 'Cập nhật ngưỡng cảnh báo thất bại';
    }
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> removeFromLocation(String inventoryId) async {
    try {
      await _inventoryRepository.removeFromLocation(inventoryId);
      state = state.copyWith(
        items: state.items.where((item) => item.id != inventoryId).toList(),
      );
      return null;
    } catch (e) {
      return 'Không thể xoá — có thể tồn kho khác 0';
    }
  }

  Future<void> _loadSummary() async {
    state = state.copyWith(isLoadingSummary: true);
    try {
      final summary = await _statsRepository.getInventory(
        lowStockThreshold: state.lowStockThreshold,
      );
      state = state.copyWith(summary: summary, isLoadingSummary: false);
    } catch (e) {
      state = state.copyWith(isLoadingSummary: false);
    }
  }

  Future<void> _loadList({bool reset = false}) async {
    final targetPage = reset ? 1 : state.page + 1;
    state = reset
        ? state.copyWith(isLoadingList: true, clearError: true)
        : state.copyWith(isLoadingMore: true);

    try {
      final result = await _inventoryRepository.getList(
        page: targetPage,
        limit: inventoryPageSize,
        locationId: _locationId,
        locationType: _locationType,
        isLowStockOnly: state.isLowStockOnly,
        search: state.search.isEmpty ? null : state.search,
      );
      state = state.copyWith(
        items: reset ? result.items : [...state.items, ...result.items],
        page: result.pagination.page,
        totalPages: result.pagination.totalPages,
        isLoadingList: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingList: false,
        isLoadingMore: false,
        errorMessage: 'Tải dữ liệu tồn kho thất bại',
      );
    }
  }
}
