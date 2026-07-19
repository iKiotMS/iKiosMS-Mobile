import '../../models/inventory_item_model.dart';

/// Abstract interface for the per-location inventory repository.
abstract class InventoryRepository {
  Future<InventoryListResult> getList({
    required int page,
    required int limit,
    String? locationId,
    String? locationType,
    bool isLowStockOnly = false,
    String? search,
  });

  /// 0 disables the low-stock alert for this item.
  Future<InventoryItemModel> updateMinStock({
    required String inventoryId,
    required int minStock,
  });

  /// Only allowed by the backend when the item's stock is 0.
  Future<void> removeFromLocation(String inventoryId);
}
