import 'package:flutter/material.dart';

class StockMovementDetailModel {
  final String productItemId;
  final String productName;
  final String sku;
  final int quantity;
  final double importPrice;
  final int receivedQuantity;
  final String? note;

  const StockMovementDetailModel({
    required this.productItemId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.importPrice,
    required this.receivedQuantity,
    this.note,
  });

  factory StockMovementDetailModel.fromJson(Map<String, dynamic> json) {
    final productRef = json['productItemId'];
    String pId = '';
    String pName = '';
    String pSku = '';

    if (productRef is String) {
      pId = productRef;
    } else if (productRef is Map<String, dynamic>) {
      pId = productRef['_id']?.toString() ?? '';
      pName = productRef['productName']?.toString() ?? '';
      pSku = productRef['sku']?.toString() ?? '';
    }

    return StockMovementDetailModel(
      productItemId: pId,
      productName: json['productName']?.toString() ?? pName,
      sku: json['sku']?.toString() ?? pSku,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      importPrice: (json['importPrice'] as num?)?.toDouble() ?? 0.0,
      receivedQuantity: (json['receivedQuantity'] as num?)?.toInt() ?? 0,
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productItemId': productItemId,
      'quantity': quantity,
      'importPrice': importPrice,
      'receivedQuantity': receivedQuantity,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }

  double get totalPrice => quantity * importPrice;

  StockMovementDetailModel copyWith({
    String? productItemId,
    String? productName,
    String? sku,
    int? quantity,
    double? importPrice,
    int? receivedQuantity,
    String? note,
  }) {
    return StockMovementDetailModel(
      productItemId: productItemId ?? this.productItemId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      importPrice: importPrice ?? this.importPrice,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      note: note ?? this.note,
    );
  }
}

class StockMovementModel {
  final String id;
  final String tenantId;
  final String movementType; // EXPORT, RETURN, IMPORT, ADJUST
  final String status; // DRAFT, OPENING, CLOSED, IN_TRANSIT, RECEIVED, CANCELLED, COMPLETED
  final String? fromSupplierId;
  final String? supplierName;
  final String? fromLocationId;
  final String? fromLocationName;
  final String? fromLocationType; // warehouse, branch
  final String toLocationId;
  final String toLocationName;
  final String toLocationType; // warehouse, branch
  final String? requestedBy;
  final String? requestedByName;
  final String? note;
  final List<StockMovementDetailModel> details;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StockMovementModel({
    required this.id,
    required this.tenantId,
    required this.movementType,
    required this.status,
    this.fromSupplierId,
    this.supplierName,
    this.fromLocationId,
    this.fromLocationName,
    this.fromLocationType,
    required this.toLocationId,
    required this.toLocationName,
    required this.toLocationType,
    this.requestedBy,
    this.requestedByName,
    this.note,
    required this.details,
    this.createdAt,
    this.updatedAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    // Resolve user/creator name
    final creator = json['createdBy'] ?? json['requestedBy'];
    String creatorId = '';
    String creatorName = '';
    if (creator is Map<String, dynamic>) {
      creatorId = creator['_id']?.toString() ?? '';
      if (creator['fullName'] != null && creator['fullName'].toString().trim().isNotEmpty) {
        creatorName = creator['fullName'].toString().trim();
      } else if (creator['profile'] is Map<String, dynamic>) {
        final profile = creator['profile'] as Map<String, dynamic>;
        creatorName = '${profile['lastName'] ?? ''} ${profile['firstName'] ?? ''}'.trim();
      }
      if (creatorName.isEmpty) {
        creatorName = creator['phoneNumber']?.toString() ?? creator['email']?.toString() ?? '';
      }
    } else if (creator != null) {
      creatorId = creator.toString();
    }

    final rawDetails = json['details'] as List<dynamic>? ?? [];
    final detailsList = rawDetails
        .map((item) => StockMovementDetailModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return StockMovementModel(
      id: json['_id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      movementType: json['movementType']?.toString() ?? 'EXPORT',
      status: json['status']?.toString() ?? 'DRAFT',
      fromSupplierId: json['fromSupplierId'] is Map
          ? (json['fromSupplierId'] as Map)['_id']?.toString()
          : json['fromSupplierId']?.toString(),
      supplierName: json['supplierName']?.toString() ??
          (json['fromSupplierId'] is Map ? (json['fromSupplierId'] as Map)['supplierName']?.toString() : null),
      fromLocationId: json['fromLocationId']?.toString(),
      fromLocationName: json['fromLocationName']?.toString(),
      fromLocationType: json['fromLocationType']?.toString(),
      toLocationId: json['toLocationId']?.toString() ?? '',
      toLocationName: json['toLocationName']?.toString() ?? json['toLocationId']?.toString() ?? '',
      toLocationType: json['toLocationType']?.toString() ?? 'branch',
      requestedBy: creatorId,
      requestedByName: creatorName,
      note: json['note']?.toString(),
      details: detailsList,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  int get totalQty => details.fold(0, (sum, d) => sum + d.quantity);

  double get totalValue => details.fold(0.0, (sum, d) => sum + d.totalPrice);

  int get totalReceivedQty => details.fold(0, (sum, d) => sum + d.receivedQuantity);

  String get statusLabel {
    switch (status) {
      case 'DRAFT':
        return 'Nháp / Cần xử lý';
      case 'OPENING':
        return 'Đang soạn';
      case 'CLOSED':
        return 'Đã chốt';
      case 'IN_TRANSIT':
        return 'Đang vận chuyển';
      case 'RECEIVED':
        return 'Đã nhận hàng';
      case 'CANCELLED':
        return 'Đã huỷ';
      case 'COMPLETED':
        return 'Đã hoàn tất';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'DRAFT':
        return Colors.orange;
      case 'OPENING':
        return Colors.amber.shade800;
      case 'CLOSED':
        return Colors.blue;
      case 'IN_TRANSIT':
        return Colors.indigo;
      case 'RECEIVED':
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  StockMovementModel copyWith({
    String? id,
    String? tenantId,
    String? movementType,
    String? status,
    String? fromSupplierId,
    String? supplierName,
    String? fromLocationId,
    String? fromLocationName,
    String? fromLocationType,
    String? toLocationId,
    String? toLocationName,
    String? toLocationType,
    String? requestedBy,
    String? requestedByName,
    String? note,
    List<StockMovementDetailModel>? details,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockMovementModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      movementType: movementType ?? this.movementType,
      status: status ?? this.status,
      fromSupplierId: fromSupplierId ?? this.fromSupplierId,
      supplierName: supplierName ?? this.supplierName,
      fromLocationId: fromLocationId ?? this.fromLocationId,
      fromLocationName: fromLocationName ?? this.fromLocationName,
      fromLocationType: fromLocationType ?? this.fromLocationType,
      toLocationId: toLocationId ?? this.toLocationId,
      toLocationName: toLocationName ?? this.toLocationName,
      toLocationType: toLocationType ?? this.toLocationType,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      note: note ?? this.note,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StockMovementLocationOption {
  final String id;
  final String name;
  final String type; // warehouse | branch

  const StockMovementLocationOption({
    required this.id,
    required this.name,
    required this.type,
  });

  factory StockMovementLocationOption.fromJson(Map<String, dynamic> json, String type) {
    return StockMovementLocationOption(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['_id']?.toString() ?? '',
      type: type,
    );
  }
}

class StockMovementProductItemOption {
  final String id;
  final String productId;
  final String name;
  final String sku;
  final double costPrice;
  final double? retailPrice;
  final int stock;
  final bool atLocation;

  const StockMovementProductItemOption({
    required this.id,
    required this.productId,
    required this.name,
    required this.sku,
    required this.costPrice,
    this.retailPrice,
    required this.stock,
    this.atLocation = false,
  });
}
