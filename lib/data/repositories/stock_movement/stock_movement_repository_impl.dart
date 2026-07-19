import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/stock_movement_model.dart';
import '../../services/stock_movement_api_service.dart';
import 'stock_movement_repository.dart';

/// Concrete implementation of [StockMovementRepository].
class StockMovementRepositoryImpl implements StockMovementRepository {
  final StockMovementApiService _apiService;

  StockMovementRepositoryImpl(this._apiService);

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
  Future<List<StockMovement>> getList({
    required String movementType,
    String? status,
    required int page,
    required int limit,
  }) {
    return _run(() async {
      final raw = await _apiService.getList(
        movementType: movementType,
        status: status,
        page: page,
        limit: limit,
      );
      return (raw['data'] as List)
          .map((e) => StockMovement.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<StockMovement> getDetail(String id) {
    return _run(() async {
      final raw = await _apiService.getDetail(id);
      return StockMovement.fromJson(raw);
    });
  }
}
