// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardViewModelHash() =>
    r'007d0d2cef5ce3e51d9ff76473df152db043e095';

/// Riverpod-generated notifier for the branch revenue dashboard screen.
///
/// Mirrors the web app's `useDashboardStats` hook: every widget's data is
/// fetched together and a change to the range, the top-products sort, or
/// the low-stock threshold triggers a full refetch of all seven endpoints
/// (not just the affected widget) — replicated here for parity even though
/// it re-fetches more than strictly necessary.
///
/// Copied from [DashboardViewModel].
@ProviderFor(DashboardViewModel)
final dashboardViewModelProvider =
    AutoDisposeNotifierProvider<DashboardViewModel, DashboardState>.internal(
      DashboardViewModel.new,
      name: r'dashboardViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dashboardViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DashboardViewModel = AutoDisposeNotifier<DashboardState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
