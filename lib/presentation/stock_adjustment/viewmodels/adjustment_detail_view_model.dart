import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement/stock_movement_repository.dart';
import '../../../data/repositories/stock_movement/stock_movement_repository_provider.dart';

part 'adjustment_detail_view_model.g.dart';

// ── State ─────────────────────────────────────────────────────────────────

class AdjustmentDetailState {
  final bool isLoading;
  final bool isProcessing;
  final StockMovement? adjustment;
  final String? errorMessage;

  const AdjustmentDetailState({
    this.isLoading = false,
    this.isProcessing = false,
    this.adjustment,
    this.errorMessage,
  });

  AdjustmentDetailState copyWith({
    bool? isLoading,
    bool? isProcessing,
    StockMovement? adjustment,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdjustmentDetailState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      adjustment: adjustment ?? this.adjustment,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

/// Loads one ADJUST request's detail and exposes approve/cancel actions.
@riverpod
class AdjustmentDetailViewModel extends _$AdjustmentDetailViewModel {
  late String _id;

  @override
  AdjustmentDetailState build(String id) {
    _id = id;
    Future.microtask(_load);
    return const AdjustmentDetailState(isLoading: true);
  }

  StockMovementRepository get _repository => ref.read(stockMovementRepositoryProvider);

  Future<void> refetch() => _load();

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final adjustment = await _repository.getDetail(_id);
      state = state.copyWith(isLoading: false, adjustment: adjustment);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tải chi tiết phiếu điều chỉnh thất bại');
    }
  }

  /// Returns true on success.
  Future<bool> approve() async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final updated = await _repository.approveAdjust(_id);
      state = state.copyWith(isProcessing: false, adjustment: updated);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: 'Duyệt phiếu điều chỉnh thất bại');
      return false;
    }
  }

  /// Returns true on success.
  Future<bool> cancel() async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final updated = await _repository.cancel(_id);
      state = state.copyWith(isProcessing: false, adjustment: updated);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: 'Huỷ phiếu điều chỉnh thất bại');
      return false;
    }
  }
}
