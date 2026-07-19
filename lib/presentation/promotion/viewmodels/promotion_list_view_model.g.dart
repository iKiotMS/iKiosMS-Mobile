// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_list_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$promotionListViewModelHash() =>
    r'9854017898da380a894a4dfad8d0960ca15c0b8f';

/// Riverpod-generated notifier for the read-only "Khuyến mãi" list.
///
/// Fetches a single page of up to [_pageLimit] promotions (mirrors the web
/// provider's `recordPerPage: 100` fetch-everything-at-once approach) —
/// the backend already scopes results to the caller's branch/tenant.
///
/// Copied from [PromotionListViewModel].
@ProviderFor(PromotionListViewModel)
final promotionListViewModelProvider =
    AutoDisposeNotifierProvider<
      PromotionListViewModel,
      PromotionListState
    >.internal(
      PromotionListViewModel.new,
      name: r'promotionListViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$promotionListViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PromotionListViewModel = AutoDisposeNotifier<PromotionListState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
