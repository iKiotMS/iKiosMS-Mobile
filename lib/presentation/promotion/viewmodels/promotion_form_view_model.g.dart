// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_form_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$promotionFormViewModelHash() =>
    r'd70d4bb757b2ed773608a4562254ca6f9528bd6a';

/// Thin submit-only notifier for the promotion create/edit form — all field
/// state/validation lives locally in `PromotionFormView` (a `Form` with
/// controllers), mirroring `AdjustmentCreateViewModel`'s split of concerns.
///
/// Copied from [PromotionFormViewModel].
@ProviderFor(PromotionFormViewModel)
final promotionFormViewModelProvider =
    AutoDisposeNotifierProvider<
      PromotionFormViewModel,
      PromotionFormState
    >.internal(
      PromotionFormViewModel.new,
      name: r'promotionFormViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$promotionFormViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PromotionFormViewModel = AutoDisposeNotifier<PromotionFormState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
