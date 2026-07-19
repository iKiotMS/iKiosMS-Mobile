// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adjustmentDetailViewModelHash() =>
    r'179db97cf5728a0ff8a47aa61b2d0c2836f696ec';

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

abstract class _$AdjustmentDetailViewModel
    extends BuildlessAutoDisposeNotifier<AdjustmentDetailState> {
  late final String id;

  AdjustmentDetailState build(String id);
}

/// Loads one ADJUST request's detail and exposes approve/cancel actions.
///
/// Copied from [AdjustmentDetailViewModel].
@ProviderFor(AdjustmentDetailViewModel)
const adjustmentDetailViewModelProvider = AdjustmentDetailViewModelFamily();

/// Loads one ADJUST request's detail and exposes approve/cancel actions.
///
/// Copied from [AdjustmentDetailViewModel].
class AdjustmentDetailViewModelFamily extends Family<AdjustmentDetailState> {
  /// Loads one ADJUST request's detail and exposes approve/cancel actions.
  ///
  /// Copied from [AdjustmentDetailViewModel].
  const AdjustmentDetailViewModelFamily();

  /// Loads one ADJUST request's detail and exposes approve/cancel actions.
  ///
  /// Copied from [AdjustmentDetailViewModel].
  AdjustmentDetailViewModelProvider call(String id) {
    return AdjustmentDetailViewModelProvider(id);
  }

  @override
  AdjustmentDetailViewModelProvider getProviderOverride(
    covariant AdjustmentDetailViewModelProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'adjustmentDetailViewModelProvider';
}

/// Loads one ADJUST request's detail and exposes approve/cancel actions.
///
/// Copied from [AdjustmentDetailViewModel].
class AdjustmentDetailViewModelProvider
    extends
        AutoDisposeNotifierProviderImpl<
          AdjustmentDetailViewModel,
          AdjustmentDetailState
        > {
  /// Loads one ADJUST request's detail and exposes approve/cancel actions.
  ///
  /// Copied from [AdjustmentDetailViewModel].
  AdjustmentDetailViewModelProvider(String id)
    : this._internal(
        () => AdjustmentDetailViewModel()..id = id,
        from: adjustmentDetailViewModelProvider,
        name: r'adjustmentDetailViewModelProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$adjustmentDetailViewModelHash,
        dependencies: AdjustmentDetailViewModelFamily._dependencies,
        allTransitiveDependencies:
            AdjustmentDetailViewModelFamily._allTransitiveDependencies,
        id: id,
      );

  AdjustmentDetailViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  AdjustmentDetailState runNotifierBuild(
    covariant AdjustmentDetailViewModel notifier,
  ) {
    return notifier.build(id);
  }

  @override
  Override overrideWith(AdjustmentDetailViewModel Function() create) {
    return ProviderOverride(
      origin: this,
      override: AdjustmentDetailViewModelProvider._internal(
        () => create()..id = id,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<
    AdjustmentDetailViewModel,
    AdjustmentDetailState
  >
  createElement() {
    return _AdjustmentDetailViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdjustmentDetailViewModelProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdjustmentDetailViewModelRef
    on AutoDisposeNotifierProviderRef<AdjustmentDetailState> {
  /// The parameter `id` of this provider.
  String get id;
}

class _AdjustmentDetailViewModelProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          AdjustmentDetailViewModel,
          AdjustmentDetailState
        >
    with AdjustmentDetailViewModelRef {
  _AdjustmentDetailViewModelProviderElement(super.provider);

  @override
  String get id => (origin as AdjustmentDetailViewModelProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
