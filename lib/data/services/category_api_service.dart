import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

import '../models/category_model.dart';

part 'category_api_service.g.dart';

/// Riverpod-generated provider for [CategoryApiService].
@riverpod
CategoryApiService categoryApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return CategoryApiService(dio);
}

class CategoryApiService {
  final Dio _dio;

  CategoryApiService(this._dio);

  /// Keeps backward compatibility for picker
  Future<List<Map<String, dynamic>>> getList({String? search, required int limit}) async {
    final response = await _dio.get(
      ApiEndpoints.categories,
      queryParameters: {
        'page': 1,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return const [];
  }

  Future<CategoryListResult> getCategories({
    int page = 1,
    int limit = 20,
    String search = '',
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _dio.get(
      ApiEndpoints.categories,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CategoryListResult.fromJson(data);
    }
    return const CategoryListResult(data: [], total: 0, page: 1, totalPages: 1);
  }

  Future<CategoryModel> createCategory(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      ApiEndpoints.categories,
      data: payload,
    );
    return CategoryModel.fromJson(response.data['data']);
  }

  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch(
      ApiEndpoints.categoryDetail(id),
      data: payload,
    );
    return CategoryModel.fromJson(response.data['data']);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete(ApiEndpoints.categoryDetail(id));
  }
}
