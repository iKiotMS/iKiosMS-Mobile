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
  Future<List<InventoryItem>> getList({
    required String locationId,
    required String locationType,
    String? search,
    required int page,
    required int limit,
  }) {
    return _run(() async {
      final raw = await _apiService.getList(
        locationId: locationId,
        locationType: locationType,
        search: search,
        page: page,
        limit: limit,
      );
      return (raw['data'] as List)
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}
