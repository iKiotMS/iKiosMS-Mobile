// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shiftRepositoryHash() => r'f4e03a0029307379c404727d0c860056c2a87f04';

/// Riverpod-generated provider that exposes [ShiftRepository].
///
/// ViewModels use `ref.watch(shiftRepositoryProvider)` to get the repository.
/// To swap the implementation (e.g., a mock for testing), only change here.
///
/// Copied from [shiftRepository].
@ProviderFor(shiftRepository)
final shiftRepositoryProvider = AutoDisposeProvider<ShiftRepository>.internal(
  shiftRepository,
  name: r'shiftRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shiftRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShiftRepositoryRef = AutoDisposeProviderRef<ShiftRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
