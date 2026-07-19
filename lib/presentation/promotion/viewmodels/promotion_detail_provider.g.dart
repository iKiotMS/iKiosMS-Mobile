// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$promotionDetailHash() => r'a037f8dcc77a5507acea143e9070d6261cc88daa';

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

/// Fetches a single promotion's full detail.
///
/// Copied from [promotionDetail].
@ProviderFor(promotionDetail)
const promotionDetailProvider = PromotionDetailFamily();

/// Fetches a single promotion's full detail.
///
/// Copied from [promotionDetail].
class PromotionDetailFamily extends Family<AsyncValue<PromotionModel>> {
  /// Fetches a single promotion's full detail.
  ///
  /// Copied from [promotionDetail].
  const PromotionDetailFamily();

  /// Fetches a single promotion's full detail.
  ///
  /// Copied from [promotionDetail].
  PromotionDetailProvider call(String id) {
    return PromotionDetailProvider(id);
  }

  @override
  PromotionDetailProvider getProviderOverride(
    covariant PromotionDetailProvider provider,
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
  String? get name => r'promotionDetailProvider';
}

/// Fetches a single promotion's full detail.
///
/// Copied from [promotionDetail].
class PromotionDetailProvider
    extends AutoDisposeFutureProvider<PromotionModel> {
  /// Fetches a single promotion's full detail.
  ///
  /// Copied from [promotionDetail].
  PromotionDetailProvider(String id)
    : this._internal(
        (ref) => promotionDetail(ref as PromotionDetailRef, id),
        from: promotionDetailProvider,
        name: r'promotionDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$promotionDetailHash,
        dependencies: PromotionDetailFamily._dependencies,
        allTransitiveDependencies:
            PromotionDetailFamily._allTransitiveDependencies,
        id: id,
      );

  PromotionDetailProvider._internal(
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
    FutureOr<PromotionModel> Function(PromotionDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PromotionDetailProvider._internal(
        (ref) => create(ref as PromotionDetailRef),
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
  AutoDisposeFutureProviderElement<PromotionModel> createElement() {
    return _PromotionDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PromotionDetailProvider && other.id == id;
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
mixin PromotionDetailRef on AutoDisposeFutureProviderRef<PromotionModel> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PromotionDetailProviderElement
    extends AutoDisposeFutureProviderElement<PromotionModel>
    with PromotionDetailRef {
  _PromotionDetailProviderElement(super.provider);

  @override
  String get id => (origin as PromotionDetailProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
