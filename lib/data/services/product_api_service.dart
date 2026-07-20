import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/product_model.dart';

part 'product_api_service.g.dart';

@riverpod
ProductApiService productApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return ProductApiService(dio);
}

class ProductApiService {
  final Dio _dio;

  ProductApiService(this._dio);

  Future<ProductListResult> getProducts({
    int page = 1,
    int limit = 20,
    String search = '',
    String? categoryId,
    String? status,
    String? locationId,
    String? locationType,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search.isNotEmpty) 'q': search,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (locationId != null && locationId.isNotEmpty) 'locationId': locationId,
      if (locationType != null && locationType.isNotEmpty) 'locationType': locationType,
    };

    final response = await _dio.get(
      ApiEndpoints.productsSearch,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ProductListResult.fromJson(data);
    }
    return const ProductListResult(data: [], total: 0, page: 1, totalPages: 1);
  }
}
