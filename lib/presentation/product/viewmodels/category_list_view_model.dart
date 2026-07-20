import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/category_model.dart';
import '../../../data/services/category_api_service.dart';

part 'category_list_view_model.g.dart';

class CategoryListState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final bool isPaginating;
  final bool hasMore;
  final int page;
  final String? error;
  
  // Filters
  final String searchQuery;

  CategoryListState({
    required this.categories,
    this.isLoading = false,
    this.isPaginating = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.searchQuery = '',
  });

  CategoryListState copyWith({
    List<CategoryModel>? categories,
    bool? isLoading,
    bool? isPaginating,
    bool? hasMore,
    int? page,
    String? error,
    String? searchQuery,
  }) {
    return CategoryListState(
      categories: categories ?? this.categories,
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
class CategoryListViewModel extends _$CategoryListViewModel {
  @override
  CategoryListState build() {
    return CategoryListState(categories: []);
  }

  Future<void> fetchCategories({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(page: 1, hasMore: true, isLoading: true, error: null);
    } else {
      if (!state.hasMore || state.isPaginating || state.isLoading) return;
      state = state.copyWith(isPaginating: true, error: null);
    }

    try {
      final api = ref.read(categoryApiServiceProvider);
      
      final result = await api.getCategories(
        page: state.page,
        limit: 20,
        search: state.searchQuery,
      );

      final newCategories = isRefresh ? result.data : [...state.categories, ...result.data];
      
      state = state.copyWith(
        categories: newCategories,
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
    fetchCategories(isRefresh: true);
  }

  void refresh() {
    fetchCategories(isRefresh: true);
  }

  Future<bool> createCategory(Map<String, dynamic> payload) async {
    try {
      final api = ref.read(categoryApiServiceProvider);
      await api.createCategory(payload);
      refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> payload) async {
    try {
      final api = ref.read(categoryApiServiceProvider);
      await api.updateCategory(id, payload);
      refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final api = ref.read(categoryApiServiceProvider);
      await api.deleteCategory(id);
      refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
