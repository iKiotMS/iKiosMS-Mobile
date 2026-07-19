import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'location_option_api_service.g.dart';

/// Riverpod-generated provider for [LocationOptionApiService].
@riverpod
LocationOptionApiService locationOptionApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return LocationOptionApiService(dio);
}

/// Makes raw HTTP calls to `GET /branches` and `GET /warehouses` (list) —
/// only used to populate the ADJUST location picker for TENANT_OWNER.
/// Both are tenant-scoped server-side; a single page of up to 100 ACTIVE
/// locations is fetched (no pagination UI — a tenant's branch/warehouse
/// count is small enough for a flat picker list).
class LocationOptionApiService {
  final Dio _dio;

  LocationOptionApiService(this._dio);

  List<Map<String, dynamic>> _unwrapList(Response response) {
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> getBranches() async {
    return _unwrapList(
      await _dio.get(ApiEndpoints.branches, queryParameters: {'page': 1, 'limit': 100, 'status': 'ACTIVE'}),
    );
  }

  Future<List<Map<String, dynamic>>> getWarehouses() async {
    return _unwrapList(
      await _dio.get(ApiEndpoints.warehouses, queryParameters: {'page': 1, 'limit': 100, 'status': 'ACTIVE'}),
    );
  }
}
