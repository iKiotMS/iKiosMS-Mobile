import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'branch_api_service.g.dart';

/// Riverpod-generated provider for [BranchApiService].
@riverpod
BranchApiService branchApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return BranchApiService(dio);
}

/// Raw HTTP calls to the branch endpoints. No parsing, no logic.
class BranchApiService {
  final Dio _dio;

  BranchApiService(this._dio);

  /// GET /branches?limit=100&status=ACTIVE — active branches for this tenant.
  ///
  /// Returns the raw list from the `data` key of the success envelope.
  Future<List<Map<String, dynamic>>> getBranches() async {
    final response = await _dio.get(
      ApiEndpoints.branches,
      queryParameters: const {'limit': 100, 'status': 'ACTIVE'},
    );
    final body = response.data;
    if (body is Map && body['data'] is List) {
      return (body['data'] as List).cast<Map<String, dynamic>>();
    }
    if (body is List) return body.cast<Map<String, dynamic>>();
    return [];
  }
}
