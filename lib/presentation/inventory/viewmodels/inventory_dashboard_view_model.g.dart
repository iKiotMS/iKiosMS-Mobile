// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dashboard_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inventoryDashboardViewModelHash() =>
    r'0c9a4ef944e1728f55ce14627ffbf24a0343483b';

/// Riverpod-generated notifier for the warehouse/branch inventory dashboard.
///
/// Combines two backend sources:
/// - `GET /stats/inventory` (already scoped server-side per role) for the
///   summary cards (stock value, total units, SKU count, out-of-stock).
/// - `GET /inventory` (NOT scoped server-side — the caller's `locationId`
///   is trusted as-is) for the searchable/paginated/editable item list, so
///   this notifier must resolve and pass the caller's own branch/warehouse
///   id itself, mirroring the web app's client-side `auth-scope.ts` pattern.
///
/// Copied from [InventoryDashboardViewModel].
@ProviderFor(InventoryDashboardViewModel)
final inventoryDashboardViewModelProvider =
    AutoDisposeNotifierProvider<
      InventoryDashboardViewModel,
      InventoryDashboardState
    >.internal(
      InventoryDashboardViewModel.new,
      name: r'inventoryDashboardViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$inventoryDashboardViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$InventoryDashboardViewModel =
    AutoDisposeNotifier<InventoryDashboardState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
