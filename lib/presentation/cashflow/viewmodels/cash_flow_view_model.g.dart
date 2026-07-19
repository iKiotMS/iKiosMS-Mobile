// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_flow_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cashFlowViewModelHash() => r'f08e3804c0f4b37ceeb195f4c2efdad3efd4dd4c';

/// Owns the state of the "Sổ thu chi" screen: loads the summary + first page,
/// re-loads on filter changes, and appends pages on scroll.
///
/// Copied from [CashFlowViewModel].
@ProviderFor(CashFlowViewModel)
final cashFlowViewModelProvider =
    AutoDisposeNotifierProvider<CashFlowViewModel, CashFlowState>.internal(
      CashFlowViewModel.new,
      name: r'cashFlowViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cashFlowViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CashFlowViewModel = AutoDisposeNotifier<CashFlowState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
