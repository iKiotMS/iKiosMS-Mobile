class ProductItemModel {
  final String id;
  final String sku;
  final String productCode;
  final String productName;
  final String? barcode;
  final num retailPrice;
  final num costPrice;
  final int stock;
  final String? thumbnail;
  final List<Map<String, dynamic>> stockDetails;

  const ProductItemModel({
    required this.id,
    required this.sku,
    required this.productCode,
    required this.productName,
    this.barcode,
    required this.retailPrice,
    required this.costPrice,
    required this.stock,
    this.thumbnail,
    this.stockDetails = const [],
  });

  factory ProductItemModel.fromJson(Map<String, dynamic> json) {
    String? thumbUrl;
    if (json['images'] is List) {
      final images = json['images'] as List;
      for (final img in images) {
        if (img is Map && img['isThumbnail'] == true && img['url'] != null) {
          thumbUrl = img['url'].toString();
          break;
        }
      }
      if (thumbUrl == null && images.isNotEmpty && images.first is Map) {
        thumbUrl = images.first['url']?.toString();
      }
    }

    return ProductItemModel(
      id: json['_id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      retailPrice: json['retailPrice'] ?? 0,
      costPrice: json['costPrice'] ?? 0,
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      thumbnail: thumbUrl,
      stockDetails: (json['stockDetails'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String? brandId;
  final String? categoryId;
  final String? brandName;
  final String? categoryName;
  final String status;
  final String? thumbnail;
  final int totalStock;
  final List<ProductItemModel> items;

  const ProductModel({
    required this.id,
    required this.name,
    this.brandId,
    this.categoryId,
    this.brandName,
    this.categoryName,
    required this.status,
    this.thumbnail,
    required this.totalStock,
    this.items = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? thumbUrl;
    if (json['images'] is List) {
      final images = json['images'] as List;
      for (final img in images) {
        if (img is Map && img['isThumbnail'] == true && img['url'] != null) {
          thumbUrl = img['url'].toString();
          break;
        }
      }
      if (thumbUrl == null && images.isNotEmpty && images.first is Map) {
        thumbUrl = images.first['url']?.toString();
      }
    }

    final List<ProductItemModel> parsedItems = [];
    if (json['items'] is List) {
      for (final item in json['items']) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(ProductItemModel.fromJson(item));
        }
      }
    }

    return ProductModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Không tên',
      brandId: json['brandId']?.toString(),
      categoryId: json['categoryId']?.toString(),
      brandName: json['brandName']?.toString(),
      categoryName: json['categoryName']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      thumbnail: thumbUrl,
      totalStock: int.tryParse(json['totalStock']?.toString() ?? '0') ?? 0,
      items: parsedItems,
    );
  }
}

class ProductListResult {
  final List<ProductModel> data;
  final int total;
  final int page;
  final int totalPages;

  const ProductListResult({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory ProductListResult.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final pagination = json['pagination'];

    final dataList = <ProductModel>[];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          dataList.add(ProductModel.fromJson(item));
        }
      }
    }

    int total = 0;
    int page = 1;
    int totalPages = 1;

    if (pagination is Map) {
      total = int.tryParse(pagination['total']?.toString() ?? '0') ?? 0;
      page = int.tryParse(pagination['page']?.toString() ?? '1') ?? 1;
      totalPages = int.tryParse(pagination['totalPages']?.toString() ?? '1') ?? 1;
    }

    return ProductListResult(
      data: dataList,
      total: total,
      page: page,
      totalPages: totalPages,
    );
  }
}
