// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stockMovementDetailHash() =>
    r'592a2c89c246f74203c4d435e15fdf87cff9c775';

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

/// Fetches a single movement's full detail (line items populated with
/// product name/sku — the list endpoint intentionally omits these).
///
/// Copied from [stockMovementDetail].
@ProviderFor(stockMovementDetail)
const stockMovementDetailProvider = StockMovementDetailFamily();

/// Fetches a single movement's full detail (line items populated with
/// product name/sku — the list endpoint intentionally omits these).
///
/// Copied from [stockMovementDetail].
class StockMovementDetailFamily extends Family<AsyncValue<StockMovement>> {
  /// Fetches a single movement's full detail (line items populated with
  /// product name/sku — the list endpoint intentionally omits these).
  ///
  /// Copied from [stockMovementDetail].
  const StockMovementDetailFamily();

  /// Fetches a single movement's full detail (line items populated with
  /// product name/sku — the list endpoint intentionally omits these).
  ///
  /// Copied from [stockMovementDetail].
  StockMovementDetailProvider call(String id) {
    return StockMovementDetailProvider(id);
  }

  @override
  StockMovementDetailProvider getProviderOverride(
    covariant StockMovementDetailProvider provider,
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
  String? get name => r'stockMovementDetailProvider';
}

/// Fetches a single movement's full detail (line items populated with
/// product name/sku — the list endpoint intentionally omits these).
///
/// Copied from [stockMovementDetail].
class StockMovementDetailProvider
    extends AutoDisposeFutureProvider<StockMovement> {
  /// Fetches a single movement's full detail (line items populated with
  /// product name/sku — the list endpoint intentionally omits these).
  ///
  /// Copied from [stockMovementDetail].
  StockMovementDetailProvider(String id)
    : this._internal(
        (ref) => stockMovementDetail(ref as StockMovementDetailRef, id),
        from: stockMovementDetailProvider,
        name: r'stockMovementDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$stockMovementDetailHash,
        dependencies: StockMovementDetailFamily._dependencies,
        allTransitiveDependencies:
            StockMovementDetailFamily._allTransitiveDependencies,
        id: id,
      );

  StockMovementDetailProvider._internal(
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
  Override overrideWith(
    FutureOr<StockMovement> Function(StockMovementDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StockMovementDetailProvider._internal(
        (ref) => create(ref as StockMovementDetailRef),
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
  AutoDisposeFutureProviderElement<StockMovement> createElement() {
    return _StockMovementDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StockMovementDetailProvider && other.id == id;
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
mixin StockMovementDetailRef on AutoDisposeFutureProviderRef<StockMovement> {
  /// The parameter `id` of this provider.
  String get id;
}

class _StockMovementDetailProviderElement
    extends AutoDisposeFutureProviderElement<StockMovement>
    with StockMovementDetailRef {
  _StockMovementDetailProviderElement(super.provider);

  @override
  String get id => (origin as StockMovementDetailProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
