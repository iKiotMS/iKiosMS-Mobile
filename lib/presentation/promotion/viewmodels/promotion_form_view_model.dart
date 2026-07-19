import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/promotion_model.dart';
import '../../../data/repositories/promotion/promotion_repository.dart';
import '../../../data/repositories/promotion/promotion_repository_provider.dart';

part 'promotion_form_view_model.g.dart';

class PromotionFormState {
  final bool isSubmitting;
  final String? errorMessage;

  const PromotionFormState({this.isSubmitting = false, this.errorMessage});

  PromotionFormState copyWith({bool? isSubmitting, String? errorMessage, bool clearError = false}) {
    return PromotionFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Thin submit-only notifier for the promotion create/edit form — all field
/// state/validation lives locally in `PromotionFormView` (a `Form` with
/// controllers), mirroring `AdjustmentCreateViewModel`'s split of concerns.
@riverpod
class PromotionFormViewModel extends _$PromotionFormViewModel {
  @override
  PromotionFormState build() => const PromotionFormState();

  PromotionRepository get _repository => ref.read(promotionRepositoryProvider);

  Future<bool> create(PromotionFormPayload payload) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.create(payload);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Tạo khuyến mãi thất bại');
      return false;
    }
  }

  Future<bool> update(String id, PromotionFormPayload payload) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.update(id, payload);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Cập nhật khuyến mãi thất bại');
      return false;
    }
  }

  Future<bool> deactivate(String id) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.remove(id);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Tắt khuyến mãi thất bại');
      return false;
    }
  }
}
