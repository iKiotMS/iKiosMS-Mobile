import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/promotion_model.dart';
import '../../../data/repositories/promotion/promotion_repository.dart';
import '../../../data/repositories/promotion/promotion_repository_provider.dart';

part 'promotion_list_view_model.g.dart';

const int _pageLimit = 100;

// ── State ─────────────────────────────────────────────────────────────────

/// Holds all UI state for "Khuyến mãi".
class PromotionListState {
  final bool isLoading;
  final List<PromotionModel> promotions;

  /// null = all statuses. Sent to the server (unlike [searchQuery]).
  final String? statusFilter;

  /// Client-side only — filters the already-fetched [promotions] by name,
  /// mirroring the web table's TanStack `globalFilter`.
  final String searchQuery;

  final String? errorMessage;

  const PromotionListState({
    this.isLoading = false,
    this.promotions = const [],
    this.statusFilter,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<PromotionModel> get filteredPromotions {
    if (searchQuery.isEmpty) return promotions;
    final query = searchQuery.toLowerCase();
    return promotions.where((p) => p.promoName.toLowerCase().contains(query)).toList();
  }

  PromotionListState copyWith({
    bool? isLoading,
    List<PromotionModel>? promotions,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PromotionListState(
      isLoading: isLoading ?? this.isLoading,
      promotions: promotions ?? this.promotions,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

/// Riverpod-generated notifier for the read-only "Khuyến mãi" list.
///
/// Fetches a single page of up to [_pageLimit] promotions (mirrors the web
/// provider's `recordPerPage: 100` fetch-everything-at-once approach) —
/// the backend already scopes results to the caller's branch/tenant.
@riverpod
class PromotionListViewModel extends _$PromotionListViewModel {
  @override
  PromotionListState build() {
    Future.microtask(_load);
    return const PromotionListState(isLoading: true);
  }

  PromotionRepository get _repository => ref.read(promotionRepositoryProvider);

  Future<void> refetch() => _load();

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> setStatusFilter(String? status) async {
    if (status == state.statusFilter) return;
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null, isLoading: true, clearError: true);
    await _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await _repository.getList(
        status: state.statusFilter,
        page: 1,
        limit: _pageLimit,
      );
      state = state.copyWith(promotions: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tải danh sách khuyến mãi thất bại');
    }
  }
}
