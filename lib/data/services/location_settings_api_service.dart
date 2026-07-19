import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'location_settings_api_service.g.dart';

/// Riverpod-generated provider for [LocationSettingsApiService].
@riverpod
LocationSettingsApiService locationSettingsApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return LocationSettingsApiService(dio);
}

/// Makes raw HTTP calls to `/branches/:id` and `/warehouses/:id`.
///
/// Note: neither endpoint is scoped server-side to the caller's own
/// branch/warehouse (confirmed in `BranchService.getBranchById`/
/// `updateBranch` and the warehouse equivalents — both filter only by
/// `tenantId`). The repository above this layer is trusted to only ever
/// pass the caller's own id, mirroring how `/inventory` is handled.
class LocationSettingsApiService {
  final Dio _dio;

  LocationSettingsApiService(this._dio);

  Map<String, dynamic> _unwrap(Response response) {
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    return {};
  }

  Future<Map<String, dynamic>> getBranch(String id) async {
    return _unwrap(await _dio.get(ApiEndpoints.branchDetail(id)));
  }

  Future<Map<String, dynamic>> updateBranch({
    required String id,
    required String name,
    String? phoneNumber,
    String? address,
  }) async {
    return _unwrap(
      await _dio.patch(
        ApiEndpoints.branchDetail(id),
        data: {
          'name': name,
          if (phoneNumber != null) 'phoneNumber': [phoneNumber],
          if (address != null) 'address': address,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getWarehouse(String id) async {
    return _unwrap(await _dio.get(ApiEndpoints.warehouseDetail(id)));
  }

  Future<Map<String, dynamic>> updateWarehouse({
    required String id,
    required String name,
    String? address,
  }) async {
    return _unwrap(
      await _dio.patch(
        ApiEndpoints.warehouseDetail(id),
        data: {
          'name': name,
          if (address != null) 'address': address,
        },
      ),
    );
  }
}
