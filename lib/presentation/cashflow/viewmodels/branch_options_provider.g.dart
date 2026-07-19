// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_options_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$branchOptionsHash() => r'6eed167eec0d8b6ff87ca734198d087e30b2a76d';

/// Loads the tenant's active branches for the cashflow branch picker.
///
/// Only watched for TENANT_OWNER (branch managers are locked to their branch
/// server-side, so the picker isn't shown for them).
///
/// Copied from [branchOptions].
@ProviderFor(branchOptions)
final branchOptionsProvider =
    AutoDisposeFutureProvider<List<BranchOption>>.internal(
      branchOptions,
      name: r'branchOptionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$branchOptionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BranchOptionsRef = AutoDisposeFutureProviderRef<List<BranchOption>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
