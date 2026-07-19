import '../../models/inventory_item_model.dart';

/// Abstract interface for the inventory (product-at-location) repository.
abstract class InventoryRepository {
  Future<List<InventoryItem>> getList({
    required String locationId,
    required String locationType,
    String? search,
    required int page,
    required int limit,
  });
}
