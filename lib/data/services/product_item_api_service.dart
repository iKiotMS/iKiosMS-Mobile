import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'product_item_api_service.g.dart';

/// Riverpod-generated provider for [ProductItemApiService].
@riverpod
ProductItemApiService productItemApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return ProductItemApiService(dio);
}

/// Makes raw HTTP calls to `GET /products/items` (flat SKU list) — only
/// used to populate the promotion form's product-item multi-select picker.
class ProductItemApiService {
  final Dio _dio;

  ProductItemApiService(this._dio);

  Future<List<Map<String, dynamic>>> listItems({String? search, required int limit}) async {
    final response = await _dio.get(
      ApiEndpoints.productItems,
      queryParameters: {
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
}
