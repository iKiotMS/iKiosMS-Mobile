/// Models for `GET /stock-movements` (list) and `GET /stock-movements/:id`
/// (detail). Mirrors the web app's `src/types/stock-movement.ts`.
///
/// Both list and detail responses already have `fromLocationName` /
/// `toLocationName` attached server-side
/// (`StockMovementService._attachLocationNamesToMultiple`) — no client-side
/// branch/warehouse lookup is needed, unlike the inventory location badge.
library;

/// `IMPORT | EXPORT | RETURN | ADJUST` — this history screen only ever
/// requests `IMPORT`/`EXPORT`/`RETURN` (see [stockMovementHistoryTypes]);
/// `ADJUST` belongs to the separate "Điều chỉnh tồn kho" flow.
const List<String> stockMovementHistoryTypes = ['IMPORT', 'EXPORT', 'RETURN'];

class StockMovementLine {
  final String productItemId;
  final String? productName;
  final String? sku;
  final num quantity;
  final num importPrice;
  final num receivedQuantity;
  final String? note;

  const StockMovementLine({
    required this.productItemId,
    this.productName,
    this.sku,
    required this.quantity,
    required this.importPrice,
    required this.receivedQuantity,
    this.note,
  });

  num get lineTotal => quantity * importPrice;

  factory StockMovementLine.fromJson(Map<String, dynamic> json) {
    final product = json['productItemId'];
    final productMap = product is Map ? product.cast<String, dynamic>() : null;

    return StockMovementLine(
      productItemId: productMap != null ? (productMap['_id']?.toString() ?? '') : product?.toString() ?? '',
      productName: productMap?['productName']?.toString(),
      sku: productMap?['sku']?.toString(),
      quantity: (json['quantity'] as num?) ?? 0,
      importPrice: (json['importPrice'] as num?) ?? 0,
      receivedQuantity: (json['receivedQuantity'] as num?) ?? 0,
      note: json['note']?.toString(),
    );
  }
}

class StockMovement {
  final String id;
  final String movementType; // IMPORT | EXPORT | RETURN | ADJUST
  final String status;
  final String? fromLocationId;
  final String? fromLocationName;
  final String? fromLocationType; // 'branch' | 'warehouse'
  final String? supplierName;
  final String toLocationId;
  final String? toLocationName;
  final String toLocationType;
  final String requestedByName;
  final String? note;
  final List<StockMovementLine> details;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.movementType,
    required this.status,
    this.fromLocationId,
    this.fromLocationName,
    this.fromLocationType,
    this.supplierName,
    required this.toLocationId,
    this.toLocationName,
    required this.toLocationType,
    required this.requestedByName,
    this.note,
    required this.details,
    required this.createdAt,
  });

  int get totalItems => details.length;

  num get totalQuantity => details.fold<num>(0, (sum, d) => sum + d.quantity);

  num get totalValue => details.fold<num>(0, (sum, d) => sum + d.lineTotal);

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'];
    final createdByMap = createdBy is Map ? createdBy.cast<String, dynamic>() : null;
    final profile = createdByMap?['profile'] as Map<String, dynamic>?;
    final firstName = profile?['firstName']?.toString() ?? '';
    final lastName = profile?['lastName']?.toString() ?? '';
    final fullName = [firstName, lastName].where((n) => n.isNotEmpty).join(' ');
    final requestedByName = fullName.isNotEmpty
        ? fullName
        : (createdByMap?['phoneNumber']?.toString() ?? createdByMap?['email']?.toString() ?? 'Không rõ');

    final supplier = json['fromSupplierId'];
    final supplierMap = supplier is Map ? supplier.cast<String, dynamic>() : null;

    final rawDetails = json['details'] as List? ?? const [];

    return StockMovement(
      id: json['_id']?.toString() ?? '',
      movementType: json['movementType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      fromLocationId: json['fromLocationId']?.toString(),
      fromLocationName: json['fromLocationName']?.toString(),
      fromLocationType: json['fromLocationType']?.toString(),
      supplierName: supplierMap?['supplierName']?.toString(),
      toLocationId: json['toLocationId']?.toString() ?? '',
      toLocationName: json['toLocationName']?.toString(),
      toLocationType: json['toLocationType']?.toString() ?? '',
      requestedByName: requestedByName,
      note: json['note']?.toString(),
      details: rawDetails.map((e) => StockMovementLine.fromJson(e as Map<String, dynamic>)).toList(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class StockMovementPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const StockMovementPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory StockMovementPagination.fromJson(Map<String, dynamic> json) {
    return StockMovementPagination(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
