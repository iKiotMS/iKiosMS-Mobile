import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/stock_movement_model.dart';

part 'stock_movement_api_service.g.dart';

/// Riverpod-generated provider for [StockMovementApiService].
@riverpod
StockMovementApiService stockMovementApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return StockMovementApiService(dio);
}

/// Makes raw HTTP calls to the `/stock-movements` backend endpoints.
///
/// The read endpoints (`getList`/`getDetail`) back the read-only IMPORT/
/// EXPORT/RETURN history view ("Lịch sử nhập/xuất kho") but are reused as-is
/// by the ADJUST flow ("Điều chỉnh tồn kho") too, since both movement kinds
/// live in the same collection/endpoint. `createAdjustment`/`approveAdjust`/
/// `cancel` back only the ADJUST flow — opening/closing/shipping/receiving
/// IMPORT/EXPORT movements is still a separate, unimplemented task
/// ("Xác nhận nhập"/"Xác nhận xuất").
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

  Map<String, dynamic> _unwrap(Response response) {
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    return {};
  }

  /// Creates a `PENDING` ADJUST request. `toLocationId`/`toLocationType` are
  /// sent equal to `fromLocationId`/`fromLocationType`: the Mongoose schema
  /// requires them unconditionally even though the backend's ADJUST branch
  /// never reads them (confirmed against `StockMovementRequest.js` +
  /// `StockMovementService.create`).
  Future<Map<String, dynamic>> createAdjustment({
    required String locationId,
    required String locationType,
    String? note,
    required List<AdjustmentDetailInput> details,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.stockMovements,
      data: {
        'movementType': 'ADJUST',
        'fromLocationId': locationId,
        'fromLocationType': locationType,
        'toLocationId': locationId,
        'toLocationType': locationType,
        if (note != null && note.isNotEmpty) 'note': note,
        'details': details.map((d) => d.toJson()).toList(),
      },
    );
    return _unwrap(response);
  }

  Future<Map<String, dynamic>> approveAdjust(String id) async {
    return _unwrap(await _dio.patch(ApiEndpoints.stockMovementApproveAdjust(id)));
  }

  Future<Map<String, dynamic>> cancel(String id) async {
    return _unwrap(await _dio.patch(ApiEndpoints.stockMovementCancel(id)));
  }
}
