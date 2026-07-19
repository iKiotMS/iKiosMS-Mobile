import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'inventory_api_service.g.dart';

/// Riverpod-generated provider for [InventoryApiService].
@riverpod
InventoryApiService inventoryApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return InventoryApiService(dio);
}

/// Makes raw HTTP calls to the `/inventory` backend endpoints.
///
/// Response envelope here is `{success, message, data, pagination}` —
/// `data` is the raw list directly (not nested), unlike `/stats/*`.
class InventoryApiService {
  final Dio _dio;

  InventoryApiService(this._dio);

  Future<Map<String, dynamic>> getList({
    required int page,
    required int limit,
    String? locationId,
    String? locationType,
    bool? isLowStock,
    String? search,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.inventory,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (locationId != null) 'locationId': locationId,
        if (locationType != null) 'locationType': locationType,
        if (isLowStock == true) 'isLowStock': true,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final data = response.data;
    if (data is Map) {
      return {
        'data': (data['data'] as List? ?? const []).cast<Map<String, dynamic>>(),
        'pagination': (data['pagination'] as Map?)?.cast<String, dynamic>() ?? const {},
      };
    }
    return {'data': const <Map<String, dynamic>>[], 'pagination': const {}};
  }

  Future<Map<String, dynamic>> updateMinStock({
    required String inventoryId,
    required int minStock,
  }) async {
    final response = await _dio.patch(
      ApiEndpoints.inventoryMinStock(inventoryId),
      data: {'minStock': minStock},
    );
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    return {};
  }

  Future<void> removeFromLocation(String inventoryId) async {
    await _dio.delete(ApiEndpoints.inventoryItem(inventoryId));
  }
}
