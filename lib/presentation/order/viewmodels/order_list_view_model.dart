import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/order_model.dart';
import '../../../data/services/order_api_service.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'order_list_view_model.g.dart';

class OrderListState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? error;
  final int page;
  final int totalPages;
  final int total;
  final String searchQuery;
  final String? statusFilter;
  final String? paymentMethodFilter;

  const OrderListState({
    this.orders = const [],
    this.isLoading = true,
    this.error,
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.searchQuery = '',
    this.statusFilter,
    this.paymentMethodFilter,
  });

  OrderListState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? error,
    int? page,
    int? totalPages,
    int? total,
    String? searchQuery,
    String? statusFilter,
    String? paymentMethodFilter,
  }) {
    return OrderListState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error, // overwrite with null explicitly by omitting fallback
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter != null ? (statusFilter.isEmpty ? null : statusFilter) : this.statusFilter,
      paymentMethodFilter: paymentMethodFilter != null ? (paymentMethodFilter.isEmpty ? null : paymentMethodFilter) : this.paymentMethodFilter,
    );
  }
}

@riverpod
class OrderListViewModel extends _$OrderListViewModel {
  Timer? _debounce;

  @override
  OrderListState build() {
    // Start fetching immediately
    Future.microtask(() => _fetchOrders(isRefresh: true));
    return const OrderListState();
  }

  Future<void> _fetchOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isLoading: true, page: 1, error: null);
    } else {
      if (state.page >= state.totalPages) return;
      state = state.copyWith(isLoading: true, page: state.page + 1, error: null);
    }

    try {
      final userProfile = ref.read(userProfileProvider).value;
      final branchId = userProfile?.branchId;

      final params = <String, dynamic>{
        'page': state.page,
        'limit': 15,
      };

      if (branchId != null && branchId.isNotEmpty) {
        params['branchId'] = branchId;
      }
      
      if (state.searchQuery.isNotEmpty) {
        params['search'] = state.searchQuery;
      }
      if (state.statusFilter != null) {
        params['status'] = state.statusFilter;
      }
      if (state.paymentMethodFilter != null) {
        params['paymentMethod'] = state.paymentMethodFilter;
      }

      final response = await ref.read(orderApiServiceProvider).getOrders(params);
      final result = OrderListResult.fromJson(response);

      state = state.copyWith(
        orders: isRefresh ? result.data : [...state.orders, ...result.data],
        isLoading: false,
        totalPages: result.totalPages,
        total: result.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void refresh() {
    _fetchOrders(isRefresh: true);
  }

  void loadMore() {
    if (!state.isLoading) {
      _fetchOrders();
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchOrders(isRefresh: true);
    });
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status ?? '');
    _fetchOrders(isRefresh: true);
  }

  void setPaymentMethodFilter(String? paymentMethod) {
    state = state.copyWith(paymentMethodFilter: paymentMethod ?? '');
    _fetchOrders(isRefresh: true);
  }
}
