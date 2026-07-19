import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'stats_api_service.g.dart';

/// Riverpod-generated provider for [StatsApiService].
@riverpod
StatsApiService statsApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return StatsApiService(dio);
}

/// Makes raw HTTP calls to the `/stats/*` backend endpoints.
///
/// Backend response envelope is `{success, data}`; this layer unwraps
/// `data` and returns the raw JSON map. No parsing into models, no
/// business logic — the repository above this layer handles that.
///
/// `branchId`/`warehouseId` are intentionally never sent: BRANCH_MANAGER
/// is hard-scoped to their own branch server-side regardless of what's
/// passed, and TENANT_OWNER omitting it gets the whole-tenant view — so
/// there is nothing for the client to add here.
class StatsApiService {
  final Dio _dio;

  StatsApiService(this._dio);

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<Map<String, dynamic>> getOverview({
    required String fromDate,
    required String toDate,
  }) {
    return _get(
      ApiEndpoints.statsOverview,
      queryParameters: {'fromDate': fromDate, 'toDate': toDate},
    );
  }

  Future<Map<String, dynamic>> getRevenue({
    required String fromDate,
    required String toDate,
    required String groupBy,
  }) {
    return _get(
      ApiEndpoints.statsRevenue,
      queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
        'groupBy': groupBy,
      },
    );
  }

  Future<Map<String, dynamic>> getRevenueByPaymentMethod({
    required String fromDate,
    required String toDate,
  }) {
    return _get(
      ApiEndpoints.statsRevenueByPaymentMethod,
      queryParameters: {'fromDate': fromDate, 'toDate': toDate},
    );
  }

  Future<Map<String, dynamic>> getRevenueByStaff({
    required String fromDate,
    required String toDate,
  }) {
    return _get(
      ApiEndpoints.statsRevenueByStaff,
      queryParameters: {'fromDate': fromDate, 'toDate': toDate},
    );
  }

  Future<Map<String, dynamic>> getCashflow({
    required String fromDate,
    required String toDate,
    String? flow,
  }) {
    return _get(
      ApiEndpoints.statsCashflow,
      queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
        'flow': ?flow,
      },
    );
  }

  Future<Map<String, dynamic>> getTopProducts({
    required String fromDate,
    required String toDate,
    required String sortBy,
    required int limit,
  }) {
    return _get(
      ApiEndpoints.statsTopProducts,
      queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
        'sortBy': sortBy,
        'limit': limit,
      },
    );
  }

  Future<Map<String, dynamic>> getInventory({required int lowStockThreshold}) {
    return _get(
      ApiEndpoints.statsInventory,
      queryParameters: {'lowStockThreshold': lowStockThreshold},
    );
  }
}
