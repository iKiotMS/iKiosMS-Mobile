import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../models/stock_movement_model.dart';

final stockMovementRepositoryProvider = Provider<StockMovementRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return StockMovementRepository(dio);
});

class StockMovementRepository {
  final Dio _dio;

  StockMovementRepository(this._dio);

  /// Lấy danh sách phiếu chuyển kho / trả hàng
  Future<List<StockMovementModel>> getTransfers({
    String? status,
  }) async {
    try {
      final query = <String, dynamic>{
        'limit': 50,
        if (status != null && status != 'ALL') 'status': status,
      };

      final exportRes = await _dio.get('/stock-movements', queryParameters: {
        ...query,
        'movementType': 'EXPORT',
      });
      final returnRes = await _dio.get('/stock-movements', queryParameters: {
        ...query,
        'movementType': 'RETURN',
      });

      final List<dynamic> exportList = (exportRes.data is Map) ? (exportRes.data['data'] as List? ?? []) : [];
      final List<dynamic> returnList = (returnRes.data is Map) ? (returnRes.data['data'] as List? ?? []) : [];

      final allData = [...exportList, ...returnList];
      final List<StockMovementModel> result = allData
          .map((item) => StockMovementModel.fromJson(item as Map<String, dynamic>))
          .toList();

      result.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy chi tiết 1 phiếu
  Future<StockMovementModel> getById(String id) async {
    try {
      final res = await _dio.get('/stock-movements/$id');
      final data = (res.data is Map && res.data['data'] != null) ? res.data['data'] : res.data;
      return StockMovementModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo phiếu chuyển kho / trả hàng mới
  Future<StockMovementModel> createExport(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/stock-movements', data: payload);
      final data = (res.data is Map && res.data['data'] != null) ? res.data['data'] : res.data;
      return StockMovementModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Mở phiếu nháp -> OPENING
  Future<StockMovementModel> open(String id) async {
    try {
      final res = await _dio.patch('/stock-movements/$id/open');
      final data = (res.data is Map && res.data['data'] != null) ? res.data['data'] : res.data;
      return StockMovementModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Cập nhật chi tiết mặt hàng lúc OPENING
  Future<StockMovementModel> updateDetails(String id, List<Map<String, dynamic>> details) async {
    try {
      final res = await _dio.patch('/stock-movements/$id/details', data: {
        'details': details,
      });
      final data = (res.data is Map && res.data['data'] != null) ? res.data['data'] : res.data;
      return StockMovementModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Chốt phiếu
  Future<StockMovementModel> close(String id) async {
    try {
      final res = await _dio.patch('/stock-movements/$id/close');
      final data = (res.data is Map && res.data['data'] != null) ? res.data['data'] : res.data;
      return StockMovementModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Xuất kho
  Future<StockMovementModel> ship(String id) async {
    try {
      final res = await _dio.patch('/stock-movements/$id/ship');
      final data = (res.data is Map && res.data['data'] != null) ? res.data['data'] : res.data;
      return StockMovementModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Nhận hàng (nhập số lượng thực nhận)
  Future<StockMovementModel> receive(String id, List<Map<String, dynamic>> receivedDetails) async {
    try {
      final res = await _dio.patch('/stock-movements/$id/receive', data: {
        'details': receivedDetails,
      });
      final data = (res.data is Map && res.data['data'] != null) ? res.data['data'] : res.data;
      return StockMovementModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Hủy phiếu
  Future<StockMovementModel> cancel(String id) async {
    try {
      final res = await _dio.patch('/stock-movements/$id/cancel');
      final data = (res.data is Map && res.data['data'] != null) ? res.data['data'] : res.data;
      return StockMovementModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo và xuất phiếu trả hàng ngược từ phiếu đã nhận
  Future<StockMovementModel> createAndShipReverseReturn(StockMovementModel source) async {
    try {
      final details = source.details.map((d) {
        final qty = d.receivedQuantity > 0 ? d.receivedQuantity : d.quantity;
        return {
          'productItemId': d.productItemId,
          'quantity': qty,
          if (d.importPrice > 0) 'importPrice': d.importPrice,
          if (d.note != null && d.note!.isNotEmpty) 'note': d.note,
        };
      }).toList();

      final fromLocationId = source.toLocationId;
      final fromLocationType = source.toLocationType;
      final toLocationId = source.fromLocationId ?? '';
      final toLocationType = source.fromLocationType ?? 'warehouse';

      final movementType = (fromLocationType == 'branch' && toLocationType == 'warehouse') ? 'RETURN' : 'EXPORT';

      final createRes = await _dio.post('/stock-movements', data: {
        'movementType': movementType,
        'fromLocationId': fromLocationId,
        'fromLocationType': fromLocationType,
        'toLocationId': toLocationId,
        'toLocationType': toLocationType,
        'note': 'Trả hàng từ phiếu ${source.id}',
        'details': details,
      });

      final createdData = (createRes.data is Map && createRes.data['data'] != null) ? createRes.data['data'] : createRes.data;
      final String newId = createdData['_id'].toString();

      await _dio.patch('/stock-movements/$newId/open');
      await _dio.patch('/stock-movements/$newId/close');
      final shipRes = await _dio.patch('/stock-movements/$newId/ship');

      final finalData = (shipRes.data is Map && shipRes.data['data'] != null) ? shipRes.data['data'] : shipRes.data;
      return StockMovementModel.fromJson(finalData as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy danh sách Địa điểm (Kho & Chi nhánh)
  Future<List<StockMovementLocationOption>> getLocationOptions() async {
    try {
      final warehousesRes = await _dio.get('/warehouses', queryParameters: {'page': 1, 'limit': 100});
      final branchesRes = await _dio.get('/branches', queryParameters: {'page': 1, 'limit': 100});

      final List<dynamic> whList = (warehousesRes.data is Map) ? (warehousesRes.data['data'] as List? ?? []) : [];
      final List<dynamic> brList = (branchesRes.data is Map) ? (branchesRes.data['data'] as List? ?? []) : [];

      final warehouses = whList
          .map((item) => StockMovementLocationOption.fromJson(item as Map<String, dynamic>, 'warehouse'))
          .toList();
      final branches = brList
          .map((item) => StockMovementLocationOption.fromJson(item as Map<String, dynamic>, 'branch'))
          .toList();

      return [...warehouses, ...branches];
    } catch (e) {
      return [];
    }
  }

  /// Lấy sản phẩm có tồn kho tại nơi gửi
  Future<List<StockMovementProductItemOption>> getProductItemsAtSource(String locationId, String locationType) async {
    try {
      final productsRes = await _dio.get('/products/search', queryParameters: {'page': 1, 'limit': 100, 'status': 'ACTIVE'});
      final inventoryRes = await _dio.get('/inventory', queryParameters: {'page': 1, 'limit': 100, 'locationId': locationId, 'locationType': locationType});

      final List<dynamic> rawProducts = (productsRes.data is Map) ? (productsRes.data['data'] as List? ?? []) : [];
      final List<dynamic> rawInventory = (inventoryRes.data is Map) ? (inventoryRes.data['data'] as List? ?? []) : [];

      final Map<String, int> inventoryMap = {};
      for (final row in rawInventory) {
        if (row is Map) {
          final pItem = row['productItemId'];
          final String pId = (pItem is Map) ? (pItem['_id']?.toString() ?? '') : (pItem?.toString() ?? '');
          final int stock = (row['stock'] as num?)?.toInt() ?? 0;
          if (pId.isNotEmpty) {
            inventoryMap[pId] = stock;
          }
        }
      }

      final List<StockMovementProductItemOption> items = [];
      for (final p in rawProducts) {
        if (p is Map) {
          final String pName = p['name']?.toString() ?? '';
          final String pId = p['_id']?.toString() ?? '';
          final List<dynamic> rawItems = (p['items'] ?? p['productItems']) as List? ?? [];
          for (final item in rawItems) {
            if (item is Map) {
              final String itemId = item['_id']?.toString() ?? '';
              final String itemName = item['productName']?.toString() ?? item['name']?.toString() ?? pName;
              final String sku = item['sku']?.toString() ?? '';
              final double costPrice = (item['costPrice'] as num?)?.toDouble() ?? (item['retailPrice'] as num?)?.toDouble() ?? 0.0;
              final double? retailPrice = (item['retailPrice'] as num?)?.toDouble();
              final int stock = inventoryMap[itemId] ?? 0;

              if (stock > 0) {
                items.add(StockMovementProductItemOption(
                  id: itemId,
                  productId: pId,
                  name: itemName,
                  sku: sku,
                  costPrice: costPrice,
                  retailPrice: retailPrice,
                  stock: stock,
                  atLocation: true,
                ));
              }
            }
          }
        }
      }
      return items;
    } catch (e) {
      return [];
    }
  }
}
