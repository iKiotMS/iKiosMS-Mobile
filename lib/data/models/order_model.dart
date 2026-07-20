class OrderItemModel {
  final String productItemId;
  final String productName;
  final int quantity;
  final num unitPrice;
  final num discountAmount;
  final String id;

  const OrderItemModel({
    required this.productItemId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.id,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productItemId: json['productItemId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unitPrice: json['unitPrice'] ?? 0,
      discountAmount: json['discountAmount'] ?? 0,
      id: json['_id']?.toString() ?? '',
    );
  }
}

class OrderModel {
  final String id;
  final String tenantId;
  final String branchId;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String status;
  final String userId;
  final String? userName;
  final String paymentMethod;
  final String? paymentReference;
  final num grandTotal;
  final num? customerPay;
  final num? change;
  final String? note;
  final List<OrderItemModel> items;
  final String createdAt;
  final String updatedAt;

  const OrderModel({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.status,
    required this.userId,
    this.userName,
    required this.paymentMethod,
    this.paymentReference,
    required this.grandTotal,
    this.customerPay,
    this.change,
    this.note,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    String? custName;
    String? custPhone;
    if (json['customerId'] is Map) {
      custName = json['customerId']['name']?.toString();
      custPhone = json['customerId']['phone']?.toString();
    }

    String? uName;
    if (json['userId'] is Map) {
      uName = json['userId']['name']?.toString();
    }

    final parsedItems = <OrderItemModel>[];
    if (json['items'] is List) {
      for (final item in json['items']) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(OrderItemModel.fromJson(item));
        }
      }
    }

    return OrderModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      customerId: (json['customerId'] is Map)
          ? (json['customerId']['_id']?.toString() ?? '')
          : json['customerId']?.toString() ?? '',
      customerName: custName,
      customerPhone: custPhone,
      status: json['status']?.toString() ?? 'PENDING',
      userId: (json['userId'] is Map)
          ? (json['userId']['_id']?.toString() ?? '')
          : json['userId']?.toString() ?? '',
      userName: uName,
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH',
      paymentReference: json['paymentReference']?.toString(),
      grandTotal: json['grandTotal'] ?? 0,
      customerPay: json['customerPay'],
      change: json['change'],
      note: json['note']?.toString(),
      items: parsedItems,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

class OrderListResult {
  final List<OrderModel> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const OrderListResult({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory OrderListResult.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final pagination = json['pagination'];

    final dataList = <OrderModel>[];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          dataList.add(OrderModel.fromJson(item));
        }
      }
    }

    int total = 0;
    int page = 1;
    int limit = 20;
    int totalPages = 1;

    if (pagination is Map) {
      total = int.tryParse(pagination['total']?.toString() ?? '0') ?? 0;
      page = int.tryParse(pagination['page']?.toString() ?? '1') ?? 1;
      limit = int.tryParse(pagination['limit']?.toString() ?? '20') ?? 20;
      totalPages = int.tryParse(pagination['totalPages']?.toString() ?? '1') ?? 1;
    }

    return OrderListResult(
      data: dataList,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
    );
  }
}
