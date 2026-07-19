import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement_repository.dart';

class TransfersState {
  final List<StockMovementModel> transfers;
  final bool isLoading;
  final String? error;
  final String statusFilter; // ALL, DRAFT, OPENING, CLOSED, IN_TRANSIT, RECEIVED, CANCELLED
  final String fromFilter;
  final String toFilter;
  final String searchQuery;

  const TransfersState({
    this.transfers = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter = 'ALL',
    this.fromFilter = 'ALL',
    this.toFilter = 'ALL',
    this.searchQuery = '',
  });

  TransfersState copyWith({
    List<StockMovementModel>? transfers,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? fromFilter,
    String? toFilter,
    String? searchQuery,
  }) {
    return TransfersState(
      transfers: transfers ?? this.transfers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      fromFilter: fromFilter ?? this.fromFilter,
      toFilter: toFilter ?? this.toFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<StockMovementModel> get filteredTransfers {
    return transfers.where((row) {
      if (statusFilter != 'ALL' && row.status != statusFilter) return false;
      if (fromFilter != 'ALL' && row.fromLocationId != fromFilter) return false;
      if (toFilter != 'ALL' && row.toLocationId != toFilter) return false;
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchId = row.id.toLowerCase().contains(q);
        final matchReq = (row.requestedByName ?? '').toLowerCase().contains(q);
        final matchNote = (row.note ?? '').toLowerCase().contains(q);
        final matchFrom = (row.fromLocationName ?? '').toLowerCase().contains(q);
        final matchTo = (row.toLocationName).toLowerCase().contains(q);
        if (!matchId && !matchReq && !matchNote && !matchFrom && !matchTo) return false;
      }
      return true;
    }).toList();
  }
}

class TransfersNotifier extends StateNotifier<TransfersState> {
  final StockMovementRepository _repository;

  TransfersNotifier(this._repository) : super(const TransfersState()) {
    fetchTransfers();
  }

  Future<void> fetchTransfers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getTransfers(status: state.statusFilter);
      state = state.copyWith(transfers: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
    fetchTransfers();
  }

  void setFromFilter(String fromId) {
    state = state.copyWith(fromFilter: fromId);
  }

  void setToFilter(String toId) {
    state = state.copyWith(toFilter: toId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> openTransfer(String id) async {
    await _repository.open(id);
    await fetchTransfers();
  }

  Future<void> closeTransfer(String id) async {
    await _repository.close(id);
    await fetchTransfers();
  }

  Future<void> shipTransfer(String id) async {
    await _repository.ship(id);
    await fetchTransfers();
  }

  Future<void> updateDetails(String id, List<Map<String, dynamic>> details) async {
    await _repository.updateDetails(id, details);
    await fetchTransfers();
  }

  Future<void> receiveTransfer(String id, List<Map<String, dynamic>> receivedDetails) async {
    await _repository.receive(id, receivedDetails);
    await fetchTransfers();
  }

  Future<void> cancelTransfer(String id) async {
    await _repository.cancel(id);
    await fetchTransfers();
  }

  Future<void> returnGoods(StockMovementModel source) async {
    await _repository.createAndShipReverseReturn(source);
    await fetchTransfers();
  }
}

final transfersProvider = StateNotifierProvider<TransfersNotifier, TransfersState>((ref) {
  final repo = ref.watch(stockMovementRepositoryProvider);
  return TransfersNotifier(repo);
});
