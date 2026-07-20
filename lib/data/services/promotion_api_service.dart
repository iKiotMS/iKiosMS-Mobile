import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/promotion_model.dart';

part 'promotion_api_service.g.dart';

/// Riverpod-generated provider for [PromotionApiService].
@riverpod
PromotionApiService promotionApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return PromotionApiService(dio);
}

/// Makes raw HTTP calls to the `/promotions` backend endpoints. Mobile only
/// consumes the read endpoints — the backend already scopes results to the
/// caller's branch/tenant (`PromotionService`'s role-based `_branchScope`),
/// so no `branchId` param is sent from here.
class PromotionApiService {
  final Dio _dio;

  PromotionApiService(this._dio);

  Future<Map<String, dynamic>> getList({
    String? search,
    String? status,
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.promotions,
      queryParameters: {
        'page': page,
        'recordPerPage': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        'status': ?status,
      },
    );
    final data = response.data;
    if (data is Map) {
      return {
        'data': (data['data'] as List? ?? const [])
            .cast<Map<String, dynamic>>(),
        'pagination':
            (data['pagination'] as Map?)?.cast<String, dynamic>() ?? const {},
      };
    }
    return {'data': const <Map<String, dynamic>>[], 'pagination': const {}};
  }

  Future<Map<String, dynamic>> getDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.promotionDetail(id));
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    return {};
  }

  Future<Map<String, dynamic>> getLogs(
    String id, {
    required int page,
    required int limit,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.promotionLogs(id),
      queryParameters: {'page': page, 'recordPerPage': limit},
    );
    final data = response.data;
    if (data is Map) {
      return {
        'data': (data['data'] as List? ?? const [])
            .cast<Map<String, dynamic>>(),
        'pagination':
            (data['pagination'] as Map?)?.cast<String, dynamic>() ?? const {},
      };
    }
    return {'data': const <Map<String, dynamic>>[], 'pagination': const {}};
  }

  Map<String, dynamic> _unwrap(Response response) {
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    return {};
  }

  Future<Map<String, dynamic>> create(PromotionFormPayload payload) async {
    return _unwrap(
      await _dio.post(ApiEndpoints.promotions, data: payload.toJson()),
    );
  }

  Future<Map<String, dynamic>> update(
    String id,
    PromotionFormPayload payload,
  ) async {
    return _unwrap(
      await _dio.patch(
        ApiEndpoints.promotionDetail(id),
        data: payload.toJson(),
      ),
    );
  }

  Future<Map<String, dynamic>> remove(String id) async {
    return _unwrap(await _dio.delete(ApiEndpoints.promotionDetail(id)));
  }
}
