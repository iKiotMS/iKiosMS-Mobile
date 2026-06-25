// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shiftDetailViewModelHash() =>
    r'5c38da4245a6b5f82abb039e56dcd997636065fa';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ShiftDetailViewModel
    extends BuildlessAutoDisposeNotifier<ShiftDetailState> {
  late final String shiftId;

  ShiftDetailState build(String shiftId);
}

/// Riverpod-generated notifier for the shift detail screen.
///
/// [shiftId] is passed as a family argument so each detail screen
/// has its own isolated provider instance.
///
/// Copied from [ShiftDetailViewModel].
@ProviderFor(ShiftDetailViewModel)
const shiftDetailViewModelProvider = ShiftDetailViewModelFamily();

/// Riverpod-generated notifier for the shift detail screen.
///
/// [shiftId] is passed as a family argument so each detail screen
/// has its own isolated provider instance.
///
/// Copied from [ShiftDetailViewModel].
class ShiftDetailViewModelFamily extends Family<ShiftDetailState> {
  /// Riverpod-generated notifier for the shift detail screen.
  ///
  /// [shiftId] is passed as a family argument so each detail screen
  /// has its own isolated provider instance.
  ///
  /// Copied from [ShiftDetailViewModel].
  const ShiftDetailViewModelFamily();

  /// Riverpod-generated notifier for the shift detail screen.
  ///
  /// [shiftId] is passed as a family argument so each detail screen
  /// has its own isolated provider instance.
  ///
  /// Copied from [ShiftDetailViewModel].
  ShiftDetailViewModelProvider call(String shiftId) {
    return ShiftDetailViewModelProvider(shiftId);
  }

  @override
  ShiftDetailViewModelProvider getProviderOverride(
    covariant ShiftDetailViewModelProvider provider,
  ) {
    return call(provider.shiftId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'shiftDetailViewModelProvider';
}

/// Riverpod-generated notifier for the shift detail screen.
///
/// [shiftId] is passed as a family argument so each detail screen
/// has its own isolated provider instance.
///
/// Copied from [ShiftDetailViewModel].
class ShiftDetailViewModelProvider
    extends
        AutoDisposeNotifierProviderImpl<
          ShiftDetailViewModel,
          ShiftDetailState
        > {
  /// Riverpod-generated notifier for the shift detail screen.
  ///
  /// [shiftId] is passed as a family argument so each detail screen
  /// has its own isolated provider instance.
  ///
  /// Copied from [ShiftDetailViewModel].
  ShiftDetailViewModelProvider(String shiftId)
    : this._internal(
        () => ShiftDetailViewModel()..shiftId = shiftId,
        from: shiftDetailViewModelProvider,
        name: r'shiftDetailViewModelProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$shiftDetailViewModelHash,
        dependencies: ShiftDetailViewModelFamily._dependencies,
        allTransitiveDependencies:
            ShiftDetailViewModelFamily._allTransitiveDependencies,
        shiftId: shiftId,
      );

  ShiftDetailViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.shiftId,
  }) : super.internal();

  final String shiftId;

  @override
  ShiftDetailState runNotifierBuild(covariant ShiftDetailViewModel notifier) {
    return notifier.build(shiftId);
  }

  @override
  Override overrideWith(ShiftDetailViewModel Function() create) {
    return ProviderOverride(
      origin: this,
      override: ShiftDetailViewModelProvider._internal(
        () => create()..shiftId = shiftId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        shiftId: shiftId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ShiftDetailViewModel, ShiftDetailState>
  createElement() {
    return _ShiftDetailViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShiftDetailViewModelProvider && other.shiftId == shiftId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, shiftId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShiftDetailViewModelRef
    on AutoDisposeNotifierProviderRef<ShiftDetailState> {
  /// The parameter `shiftId` of this provider.
  String get shiftId;
}

class _ShiftDetailViewModelProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          ShiftDetailViewModel,
          ShiftDetailState
        >
    with ShiftDetailViewModelRef {
  _ShiftDetailViewModelProviderElement(super.provider);

  @override
  String get shiftId => (origin as ShiftDetailViewModelProvider).shiftId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
