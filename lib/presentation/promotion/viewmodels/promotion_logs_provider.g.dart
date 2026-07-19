// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_logs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$promotionLogsHash() => r'ad6a157c03e8cf5bfc5d93bbe422f53a37deaa25';

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

/// Fetches a promotion's usage-log history (first page, matches the web
/// panel's default `recordPerPage: 50`).
///
/// Copied from [promotionLogs].
@ProviderFor(promotionLogs)
const promotionLogsProvider = PromotionLogsFamily();

/// Fetches a promotion's usage-log history (first page, matches the web
/// panel's default `recordPerPage: 50`).
///
/// Copied from [promotionLogs].
class PromotionLogsFamily extends Family<AsyncValue<List<PromotionLogModel>>> {
  /// Fetches a promotion's usage-log history (first page, matches the web
  /// panel's default `recordPerPage: 50`).
  ///
  /// Copied from [promotionLogs].
  const PromotionLogsFamily();

  /// Fetches a promotion's usage-log history (first page, matches the web
  /// panel's default `recordPerPage: 50`).
  ///
  /// Copied from [promotionLogs].
  PromotionLogsProvider call(String id) {
    return PromotionLogsProvider(id);
  }

  @override
  PromotionLogsProvider getProviderOverride(
    covariant PromotionLogsProvider provider,
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
  String? get name => r'promotionLogsProvider';
}

/// Fetches a promotion's usage-log history (first page, matches the web
/// panel's default `recordPerPage: 50`).
///
/// Copied from [promotionLogs].
class PromotionLogsProvider
    extends AutoDisposeFutureProvider<List<PromotionLogModel>> {
  /// Fetches a promotion's usage-log history (first page, matches the web
  /// panel's default `recordPerPage: 50`).
  ///
  /// Copied from [promotionLogs].
  PromotionLogsProvider(String id)
    : this._internal(
        (ref) => promotionLogs(ref as PromotionLogsRef, id),
        from: promotionLogsProvider,
        name: r'promotionLogsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$promotionLogsHash,
        dependencies: PromotionLogsFamily._dependencies,
        allTransitiveDependencies:
            PromotionLogsFamily._allTransitiveDependencies,
        id: id,
      );

  PromotionLogsProvider._internal(
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
    FutureOr<List<PromotionLogModel>> Function(PromotionLogsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PromotionLogsProvider._internal(
        (ref) => create(ref as PromotionLogsRef),
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
  AutoDisposeFutureProviderElement<List<PromotionLogModel>> createElement() {
    return _PromotionLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PromotionLogsProvider && other.id == id;
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
mixin PromotionLogsRef
    on AutoDisposeFutureProviderRef<List<PromotionLogModel>> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PromotionLogsProviderElement
    extends AutoDisposeFutureProviderElement<List<PromotionLogModel>>
    with PromotionLogsRef {
  _PromotionLogsProviderElement(super.provider);

  @override
  String get id => (origin as PromotionLogsProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
