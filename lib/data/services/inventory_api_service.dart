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

/// Makes raw HTTP calls to `GET /inventory` — only used to populate the
/// product picker in the stock-adjustment create form (search products at a
/// given branch/warehouse and show their current stock).
class InventoryApiService {
  final Dio _dio;

  InventoryApiService(this._dio);

  Future<Map<String, dynamic>> getList({
    required String locationId,
    required String locationType,
    String? search,
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.inventory,
      queryParameters: {
        'locationId': locationId,
        'locationType': locationType,
        'page': page,
        'limit': limit,
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
}
