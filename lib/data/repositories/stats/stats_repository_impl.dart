import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/dashboard_stats_model.dart';
import '../../services/stats_api_service.dart';
import 'stats_repository.dart';

/// Concrete implementation of [StatsRepository].
///
/// Calls [StatsApiService] for raw HTTP data, parses JSON into models,
/// and converts Dio errors into [ApiException].
class StatsRepositoryImpl implements StatsRepository {
  final StatsApiService _apiService;

  StatsRepositoryImpl(this._apiService);

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.message ??
            'Lỗi kết nối máy chủ',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<DashboardOverview> getOverview({
    required String fromDate,
    required String toDate,
  }) {
    return _run(() async {
      final raw = await _apiService.getOverview(
        fromDate: fromDate,
        toDate: toDate,
      );
      return DashboardOverview.fromJson(raw);
    });
  }

  @override
  Future<RevenueSeries> getRevenue({
    required String fromDate,
    required String toDate,
    required String groupBy,
  }) {
    return _run(() async {
      final raw = await _apiService.getRevenue(
        fromDate: fromDate,
        toDate: toDate,
        groupBy: groupBy,
      );
      return RevenueSeries.fromJson(raw);
    });
  }

  @override
  Future<RevenueByPaymentMethod> getRevenueByPaymentMethod({
    required String fromDate,
    required String toDate,
  }) {
    return _run(() async {
      final raw = await _apiService.getRevenueByPaymentMethod(
        fromDate: fromDate,
        toDate: toDate,
      );
      return RevenueByPaymentMethod.fromJson(raw);
    });
  }

  @override
  Future<RevenueByStaff> getRevenueByStaff({
    required String fromDate,
    required String toDate,
  }) {
    return _run(() async {
      final raw = await _apiService.getRevenueByStaff(
        fromDate: fromDate,
        toDate: toDate,
      );
      return RevenueByStaff.fromJson(raw);
    });
  }

  @override
  Future<DashboardCashflow> getCashflow({
    required String fromDate,
    required String toDate,
    String? flow,
  }) {
    return _run(() async {
      final raw = await _apiService.getCashflow(
        fromDate: fromDate,
        toDate: toDate,
        flow: flow,
      );
      return DashboardCashflow.fromJson(raw);
    });
  }

  @override
  Future<TopProducts> getTopProducts({
    required String fromDate,
    required String toDate,
    required String sortBy,
    required int limit,
  }) {
    return _run(() async {
      final raw = await _apiService.getTopProducts(
        fromDate: fromDate,
        toDate: toDate,
        sortBy: sortBy,
        limit: limit,
      );
      return TopProducts.fromJson(raw);
    });
  }

  @override
  Future<InventoryStats> getInventory({required int lowStockThreshold}) {
    return _run(() async {
      final raw = await _apiService.getInventory(
        lowStockThreshold: lowStockThreshold,
      );
      return InventoryStats.fromJson(raw);
    });
  }
}
