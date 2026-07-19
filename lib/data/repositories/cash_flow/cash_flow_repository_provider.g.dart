// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_flow_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cashFlowRepositoryHash() =>
    r'ad7339470ce16c53be8be5c166639a4e72919503';

/// Riverpod-generated provider that exposes [CashFlowRepository].
///
/// ViewModels use `ref.watch(cashFlowRepositoryProvider)`. Swap the concrete
/// implementation (e.g. a mock for testing) only here.
///
/// Copied from [cashFlowRepository].
@ProviderFor(cashFlowRepository)
final cashFlowRepositoryProvider =
    AutoDisposeProvider<CashFlowRepository>.internal(
      cashFlowRepository,
      name: r'cashFlowRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cashFlowRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CashFlowRepositoryRef = AutoDisposeProviderRef<CashFlowRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
