import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement_repository.dart';

class ImportsState {
  final List<StockMovementModel> imports;
  final bool isLoading;
  final String? error;
  final String statusFilter; // ALL, PENDING, IN_TRANSIT, RECEIVED, CANCELLED

  const ImportsState({
    this.imports = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter = 'ALL',
  });

  ImportsState copyWith({
    List<StockMovementModel>? imports,
    bool? isLoading,
    String? error,
    String? statusFilter,
  }) {
    return ImportsState(
      imports: imports ?? this.imports,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class ImportsNotifier extends StateNotifier<ImportsState> {
  final StockMovementRepository _repository;

  ImportsNotifier(this._repository) : super(const ImportsState()) {
    fetchImports();
  }

  Future<void> fetchImports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getImports(status: state.statusFilter);
      state = state.copyWith(imports: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
    fetchImports();
  }

  Future<void> updateDetails(String id, List<Map<String, dynamic>> details) async {
    await _repository.updateDetails(id, details);
    await fetchImports();
  }

  Future<void> shipImport(String id) async {
    await _repository.ship(id);
    await fetchImports();
  }

  Future<void> receiveImport(String id, List<Map<String, dynamic>> receivedDetails) async {
    await _repository.receive(id, receivedDetails);
    await fetchImports();
  }

  Future<void> cancelImport(String id) async {
    await _repository.cancel(id);
    await fetchImports();
  }
}

final importsProvider = StateNotifierProvider<ImportsNotifier, ImportsState>((ref) {
  final repo = ref.watch(stockMovementRepositoryProvider);
  return ImportsNotifier(repo);
});
