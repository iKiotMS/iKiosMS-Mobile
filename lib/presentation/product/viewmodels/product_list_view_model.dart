import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/product_model.dart';
import '../../../data/services/product_api_service.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'product_list_view_model.g.dart';

class ProductListState {
  final List<ProductModel> products;
  final bool isLoading;
  final bool isPaginating;
  final bool hasMore;
  final int page;
  final String? error;
  
  // Filters
  final String searchQuery;
  final String? selectedLocationId;
  final String? selectedCategoryId;
  final String? selectedStatus;

  ProductListState({
    required this.products,
    this.isLoading = false,
    this.isPaginating = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.searchQuery = '',
    this.selectedLocationId,
    this.selectedCategoryId,
    this.selectedStatus,
  });

  ProductListState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    bool? isPaginating,
    bool? hasMore,
    int? page,
    String? error,
    String? searchQuery,
    String? selectedLocationId,
    String? selectedCategoryId,
    String? selectedStatus,
    bool clearLocation = false,
    bool clearCategory = false,
    bool clearStatus = false,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error, // Can be set to null explicitly
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLocationId: clearLocation ? null : (selectedLocationId ?? this.selectedLocationId),
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
    );
  }
}

@riverpod
class ProductListViewModel extends _$ProductListViewModel {
  @override
  ProductListState build() {
    // Determine the default branch from the user profile
    final userProfile = ref.watch(userProfileProvider).value;
    final defaultBranchId = userProfile?.branchId;

    return ProductListState(
      products: [],
      selectedLocationId: defaultBranchId,
    );
  }

  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(page: 1, hasMore: true, isLoading: true, error: null);
    } else {
      if (!state.hasMore || state.isPaginating || state.isLoading) return;
      state = state.copyWith(isPaginating: true, error: null);
    }

    try {
      final api = ref.read(productApiServiceProvider);
      
      final result = await api.getProducts(
        page: state.page,
        limit: 20,
        search: state.searchQuery,
        locationId: state.selectedLocationId,
        locationType: state.selectedLocationId != null ? 'branch' : null,
        categoryId: state.selectedCategoryId,
        status: state.selectedStatus,
      );

      final newProducts = isRefresh ? result.data : [...state.products, ...result.data];
      
      state = state.copyWith(
        products: newProducts,
        page: state.page + 1,
        hasMore: state.page < result.totalPages,
        isLoading: false,
        isPaginating: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isPaginating: false,
      );
    }
  }

  void search(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    fetchProducts(isRefresh: true);
  }

  void setLocation(String? locationId) {
    if (state.selectedLocationId == locationId) return;
    state = state.copyWith(selectedLocationId: locationId, clearLocation: locationId == null);
    fetchProducts(isRefresh: true);
  }

  void setCategory(String? categoryId) {
    if (state.selectedCategoryId == categoryId) return;
    state = state.copyWith(selectedCategoryId: categoryId, clearCategory: categoryId == null);
    fetchProducts(isRefresh: true);
  }

  void setStatus(String? status) {
    if (state.selectedStatus == status) return;
    state = state.copyWith(selectedStatus: status, clearStatus: status == null);
    fetchProducts(isRefresh: true);
  }

  void refresh() {
    fetchProducts(isRefresh: true);
  }
}
