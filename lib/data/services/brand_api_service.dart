import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/brand_model.dart';

part 'brand_api_service.g.dart';

@riverpod
BrandApiService brandApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return BrandApiService(dio);
}

class BrandApiService {
  final Dio _dio;

  BrandApiService(this._dio);

  Future<BrandListResult> getBrands({
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
      ApiEndpoints.brands,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return BrandListResult.fromJson(data);
    }
    return const BrandListResult(data: [], total: 0, page: 1, totalPages: 1);
  }

  Future<BrandModel> createBrand(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      ApiEndpoints.brands,
      data: payload,
    );
    return BrandModel.fromJson(response.data['data']);
  }

  Future<BrandModel> updateBrand(String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch(
      ApiEndpoints.brandDetail(id),
      data: payload,
    );
    return BrandModel.fromJson(response.data['data']);
  }

  Future<void> deleteBrand(String id) async {
    await _dio.delete(ApiEndpoints.brandDetail(id));
  }
}
