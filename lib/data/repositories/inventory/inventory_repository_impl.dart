import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/inventory_item_model.dart';
import '../../services/inventory_api_service.dart';
import 'inventory_repository.dart';

/// Concrete implementation of [InventoryRepository].
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryApiService _apiService;

  InventoryRepositoryImpl(this._apiService);

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
  Future<InventoryListResult> getList({
    required int page,
    required int limit,
    String? locationId,
    String? locationType,
    bool isLowStockOnly = false,
    String? search,
  }) {
    return _run(() async {
      final raw = await _apiService.getList(
        page: page,
        limit: limit,
        locationId: locationId,
        locationType: locationType,
        isLowStock: isLowStockOnly ? true : null,
        search: search,
      );
      final items = (raw['data'] as List)
          .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = InventoryPagination.fromJson(
        raw['pagination'] as Map<String, dynamic>,
      );
      return InventoryListResult(items: items, pagination: pagination);
    });
  }

  @override
  Future<InventoryItemModel> updateMinStock({
    required String inventoryId,
    required int minStock,
  }) {
    return _run(() async {
      final raw = await _apiService.updateMinStock(
        inventoryId: inventoryId,
        minStock: minStock,
      );
      return InventoryItemModel.fromJson(raw);
    });
  }

  @override
  Future<void> removeFromLocation(String inventoryId) {
    return _run(() => _apiService.removeFromLocation(inventoryId));
  }
}
