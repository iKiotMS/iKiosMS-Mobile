import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../models/cash_flow_model.dart';
import '../../services/cash_flow_api_service.dart';
import 'cash_flow_repository.dart';

/// Concrete implementation of [CashFlowRepository].
///
/// Calls [CashFlowApiService] for raw HTTP data, parses JSON into models,
/// and converts Dio errors into [ApiException]. Dates are sent as `yyyy-MM-dd`
/// so the backend applies Asia/Ho_Chi_Minh day boundaries (see StatsQueryDTO).
class CashFlowRepositoryImpl implements CashFlowRepository {
  final CashFlowApiService _apiService;

  CashFlowRepositoryImpl(this._apiService);

  @override
  Future<CashFlowSummary> getSummary({
    required DateTime fromDate,
    required DateTime toDate,
    String? flowType,
    String? branchId,
  }) async {
    try {
      final raw = await _apiService.getSummary(
        fromDate: DateTimeUtils.formatApiDate(fromDate),
        toDate: DateTimeUtils.formatApiDate(toDate),
        flowType: flowType,
        branchId: branchId,
      );
      return CashFlowSummary.fromJson(raw);
    } on DioException catch (e) {
      throw _toApiException(e, 'getSummary');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<CashFlowPage> getTransactions({
    required DateTime fromDate,
    required DateTime toDate,
    String? flowType,
    String? paymentMethod,
    String? branchId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final raw = await _apiService.getTransactions(
        fromDate: DateTimeUtils.formatApiDate(fromDate),
        toDate: DateTimeUtils.formatApiDate(toDate),
        flowType: flowType,
        paymentMethod: paymentMethod,
        branchId: branchId,
        page: page,
        limit: limit,
      );

      final list = (raw['data'] as List?) ?? const [];
      final items = list
          .whereType<Map>()
          .map((e) => CashFlowEntry.fromJson(e.cast<String, dynamic>()))
          .toList();

      final pagination = (raw['pagination'] as Map?)?.cast<String, dynamic>() ?? {};
      return CashFlowPage(
        items: items,
        total: (pagination['total'] as num?)?.toInt() ?? items.length,
        page: (pagination['page'] as num?)?.toInt() ?? page,
        totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      );
    } on DioException catch (e) {
      throw _toApiException(e, 'getTransactions');
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  ApiException _toApiException(DioException e, String op) {
    developer.log(
      '❌ [CashFlowRepository] $op FAILED! Error data: ${e.response?.data} | Exception: $e',
    );
    return ApiException(
      message: e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? e.message ?? 'Lỗi kết nối máy chủ')
          : (e.message ?? 'Lỗi kết nối máy chủ'),
      statusCode: e.response?.statusCode,
    );
  }
}
