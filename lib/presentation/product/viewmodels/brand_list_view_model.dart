import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/brand_model.dart';
import '../../../data/services/brand_api_service.dart';

part 'brand_list_view_model.g.dart';

class BrandListState {
  final List<BrandModel> brands;
  final bool isLoading;
  final bool isPaginating;
  final bool hasMore;
  final int page;
  final String? error;
  
  // Filters
  final String searchQuery;

  BrandListState({
    required this.brands,
    this.isLoading = false,
    this.isPaginating = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.searchQuery = '',
  });

  BrandListState copyWith({
    List<BrandModel>? brands,
    bool? isLoading,
    bool? isPaginating,
    bool? hasMore,
    int? page,
    String? error,
    String? searchQuery,
  }) {
    return BrandListState(
      brands: brands ?? this.brands,
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

@riverpod
class BrandListViewModel extends _$BrandListViewModel {
  @override
  BrandListState build() {
    return BrandListState(brands: []);
  }

  Future<void> fetchBrands({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(page: 1, hasMore: true, isLoading: true, error: null);
    } else {
      if (!state.hasMore || state.isPaginating || state.isLoading) return;
      state = state.copyWith(isPaginating: true, error: null);
    }

    try {
      final api = ref.read(brandApiServiceProvider);
      
      final result = await api.getBrands(
        page: state.page,
        limit: 20,
        search: state.searchQuery,
      );

      final newBrands = isRefresh ? result.data : [...state.brands, ...result.data];
      
      state = state.copyWith(
        brands: newBrands,
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
    fetchBrands(isRefresh: true);
  }

  void refresh() {
    fetchBrands(isRefresh: true);
  }

  Future<bool> createBrand(Map<String, dynamic> payload) async {
    try {
      final api = ref.read(brandApiServiceProvider);
      await api.createBrand(payload);
      refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateBrand(String id, Map<String, dynamic> payload) async {
    try {
      final api = ref.read(brandApiServiceProvider);
      await api.updateBrand(id, payload);
      refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteBrand(String id) async {
    try {
      final api = ref.read(brandApiServiceProvider);
      await api.deleteBrand(id);
      refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
