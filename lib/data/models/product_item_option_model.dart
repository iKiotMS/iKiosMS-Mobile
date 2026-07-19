/// One entry of `GET /products/items` — a flat SKU list, used only to
/// populate the product-item multi-select in the promotion create/edit
/// form. Mirrors the web app's `ProductItemListEntry`.
class ProductItemOption {
  final String id;
  final String productId;
  final String productName;
  final String productCode;
  final String sku;

  const ProductItemOption({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.sku,
  });

  factory ProductItemOption.fromJson(Map<String, dynamic> json) {
    return ProductItemOption(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
    );
  }
}
