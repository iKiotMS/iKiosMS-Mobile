import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'cash_flow_api_service.g.dart';

/// Riverpod-generated provider for [CashFlowApiService].
@riverpod
CashFlowApiService cashFlowApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return CashFlowApiService(dio);
}

/// Makes raw HTTP calls to the cashflow (sổ thu chi) stats endpoints.
///
/// HTTP only — no model parsing, no business logic. The repository above this
/// layer parses JSON and wraps failures in `ApiException`. Both endpoints are
/// wrapped by the backend as `{ success, message, data }`, so we unwrap `data`.
class CashFlowApiService {
  final Dio _dio;

  CashFlowApiService(this._dio);

  /// GET /stats/cashflow — aggregated income/expense totals for the range.
  ///
  /// Returns the raw `data` object: `{ income, expense, net, byType }`.
  Future<Map<String, dynamic>> getSummary({
    required String fromDate,
    required String toDate,
    String? flowType,
    String? branchId,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.cashflowSummary,
      queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
        'flowType': ?flowType,
        'branchId': ?branchId,
      },
    );
    return _unwrap(response.data);
  }

  /// GET /stats/cashflow/transactions — one page of ledger entries.
  ///
  /// Returns the raw `data` object: `{ data: [...], pagination: {...} }`.
  Future<Map<String, dynamic>> getTransactions({
    required String fromDate,
    required String toDate,
    String? flowType,
    String? paymentMethod,
    String? branchId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.cashflowTransactions,
      queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
        'flowType': ?flowType,
        'paymentMethod': ?paymentMethod,
        'branchId': ?branchId,
        'page': page,
        'limit': limit,
      },
    );
    return _unwrap(response.data);
  }

  /// Unwraps the backend success envelope: returns `data` when present,
  /// otherwise the body itself (some endpoints don't wrap).
  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map && body['data'] is Map) {
      return (body['data'] as Map).cast<String, dynamic>();
    }
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return body.cast<String, dynamic>();
    return {};
  }
}
