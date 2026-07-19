/// Model for `GET /inventory` rows — used only to populate the product
/// picker in the "Điều chỉnh tồn kho" (stock adjustment) create form, so
/// the caller can see each product's current system stock at the chosen
/// location while entering a counted quantity.
class InventoryItem {
  final String id;
  final String productItemId;
  final String productName;
  final String? sku;
  final num stock;

  const InventoryItem({
    required this.id,
    required this.productItemId,
    required this.productName,
    this.sku,
    required this.stock,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final product = json['productItemId'];
    final productMap = product is Map ? product.cast<String, dynamic>() : null;

    return InventoryItem(
      id: json['_id']?.toString() ?? '',
      productItemId: productMap != null ? (productMap['_id']?.toString() ?? '') : product?.toString() ?? '',
      productName: productMap?['productName']?.toString() ?? 'Sản phẩm',
      sku: productMap?['sku']?.toString(),
      stock: (json['stock'] as num?) ?? 0,
    );
  }
}
