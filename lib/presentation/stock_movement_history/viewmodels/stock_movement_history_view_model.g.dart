// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement_history_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stockMovementHistoryViewModelHash() =>
    r'29602f9add2dddc3cf0ad71c9ffef3e1745731d7';

/// Riverpod-generated notifier for the read-only stock movement history.
///
/// Mirrors the web `/exchange/exports` provider's pattern of issuing one
/// `GET /stock-movements?movementType=X` request per type and merging the
/// results client-side, sorted by `createdAt` desc — the same approach the
/// web app already uses to combine EXPORT+RETURN into one list. This
/// screen extends that to IMPORT+EXPORT+RETURN (ADJUST is a separate flow),
/// except for BRANCH_MANAGER: the web app's `canAccessImports` blocklist
/// redirects BRANCH_MANAGER away from the imports list entirely, so this
/// notifier excludes IMPORT for that role too (see [_init]) even though the
/// backend would technically allow reading it for their own branch.
///
/// Copied from [StockMovementHistoryViewModel].
@ProviderFor(StockMovementHistoryViewModel)
final stockMovementHistoryViewModelProvider =
    AutoDisposeNotifierProvider<
      StockMovementHistoryViewModel,
      StockMovementHistoryState
    >.internal(
      StockMovementHistoryViewModel.new,
      name: r'stockMovementHistoryViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stockMovementHistoryViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StockMovementHistoryViewModel =
    AutoDisposeNotifier<StockMovementHistoryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
