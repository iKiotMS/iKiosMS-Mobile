import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'stock_movement_api_service.g.dart';

/// Riverpod-generated provider for [StockMovementApiService].
@riverpod
StockMovementApiService stockMovementApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return StockMovementApiService(dio);
}

/// Makes raw HTTP calls to the `/stock-movements` backend endpoints.
///
/// Only the read endpoints are implemented — this feature is a read-only
/// history view; creating/opening/closing/shipping/receiving/cancelling
/// movements is a separate task ("Xác nhận đơn nhập/xuất hàng").
///
/// `GET /stock-movements` accepts exactly `page`, `limit`, `status`,
/// `movementType` server-side — no date-range/location/search params exist.
class StockMovementApiService {
  final Dio _dio;

  StockMovementApiService(this._dio);

  Future<Map<String, dynamic>> getList({
    required String movementType,
    String? status,
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.stockMovements,
      queryParameters: {
        'movementType': movementType,
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
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

  Future<Map<String, dynamic>> getDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.stockMovementDetail(id));
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    return {};
  }
}
