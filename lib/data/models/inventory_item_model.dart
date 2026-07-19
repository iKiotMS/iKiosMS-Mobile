/// A single per-location stock record returned by `GET /inventory`.
///
/// Maps to the backend's `Inventory` Mongoose model, with `productItemId`
/// populated to `sku`/`productName`/`images`.
class InventoryItemModel {
  final String id;
  final String locationId;
  final String locationType; // 'branch' | 'warehouse'
  final String productItemId;
  final String productName;
  final String sku;
  final String? thumbnailUrl;
  final num stock;
  final num minStock;

  const InventoryItemModel({
    required this.id,
    required this.locationId,
    required this.locationType,
    required this.productItemId,
    required this.productName,
    required this.sku,
    this.thumbnailUrl,
    required this.stock,
    required this.minStock,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['productItemId'];
    final productMap = product is Map ? product.cast<String, dynamic>() : const <String, dynamic>{};
    final images = productMap['images'] as List? ?? const [];
    String? thumbnail;
    if (images.isNotEmpty) {
      final thumb = images.firstWhere(
        (img) => img is Map && img['isThumbnail'] == true,
        orElse: () => images.first,
      );
      thumbnail = (thumb as Map)['url']?.toString();
    }

    return InventoryItemModel(
      id: json['_id']?.toString() ?? '',
      locationId: json['locationId']?.toString() ?? '',
      locationType: json['locationType']?.toString() ?? '',
      productItemId: product is Map ? (product['_id']?.toString() ?? '') : product?.toString() ?? '',
      productName: productMap['productName']?.toString() ?? '',
      sku: productMap['sku']?.toString() ?? '',
      thumbnailUrl: thumbnail,
      stock: json['stock'] is num ? json['stock'] as num : num.tryParse(json['stock']?.toString() ?? '') ?? 0,
      minStock: json['minStock'] is num ? json['minStock'] as num : num.tryParse(json['minStock']?.toString() ?? '') ?? 0,
    );
  }

  /// True once stock has dropped to or below [minStock] (0 disables the alert).
  bool get isLowStock => minStock > 0 && stock <= minStock;

  InventoryItemModel copyWith({num? stock, num? minStock}) {
    return InventoryItemModel(
      id: id,
      locationId: locationId,
      locationType: locationType,
      productItemId: productItemId,
      productName: productName,
      sku: sku,
      thumbnailUrl: thumbnailUrl,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
    );
  }
}

class InventoryPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const InventoryPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory InventoryPagination.fromJson(Map<String, dynamic> json) {
    return InventoryPagination(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class InventoryListResult {
  final List<InventoryItemModel> items;
  final InventoryPagination pagination;

  const InventoryListResult({required this.items, required this.pagination});
}
