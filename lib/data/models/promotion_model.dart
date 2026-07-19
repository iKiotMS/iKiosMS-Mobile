/// Models for `GET /promotions` (list), `GET /promotions/:id` (detail) and
/// `GET /promotions/:id/logs` (usage history). Mirrors the web app's
/// `src/types/promotion.ts`. Mobile is view-only for this feature, so no
/// create/update payload types are needed here.
library;

import 'package:flutter/material.dart';

import '../../core/utils/currency_utils.dart';

class ApplicableRule {
  final String type; // all | category | product
  final List<String> categoryIds;
  final List<String> productItemIds;

  const ApplicableRule({
    required this.type,
    this.categoryIds = const [],
    this.productItemIds = const [],
  });

  factory ApplicableRule.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ApplicableRule(type: 'all');
    return ApplicableRule(
      type: json['type']?.toString() ?? 'all',
      categoryIds: (json['categoryIds'] as List? ?? const [])
          .map((e) => e is Map ? (e['_id']?.toString() ?? '') : e.toString())
          .toList(),
      productItemIds: (json['productItemIds'] as List? ?? const [])
          .map((e) => e is Map ? (e['_id']?.toString() ?? '') : e.toString())
          .toList(),
    );
  }
}

class PromotionModel {
  final String id;
  final List<String> branchIds;
  final String promoName;
  final String? description;
  final String discountType; // PERCENT | FIXED_AMOUNT
  final num discountValue;
  final num? maxDiscountAmount;
  final num minOrderValue;
  final ApplicableRule applicableRule;
  final DateTime startDate;
  final DateTime endDate;
  final int priority;
  final bool stackable;
  final int? usageLimit;
  final int? usageLimitPerCustomer;
  final int usedCount;
  final String status; // ACTIVE | INACTIVE

  const PromotionModel({
    required this.id,
    required this.branchIds,
    required this.promoName,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    required this.minOrderValue,
    required this.applicableRule,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.stackable,
    this.usageLimit,
    this.usageLimitPerCustomer,
    required this.usedCount,
    required this.status,
  });

  bool get isBranchWide => branchIds.isEmpty;

  /// ACTIVE | INACTIVE | EXPIRED — mirrors the web table's
  /// `getPromotionDisplayStatus`: still ACTIVE in DB but past `endDate` shows
  /// as expired rather than running.
  String get displayStatus {
    if (status == 'ACTIVE' && endDate.isBefore(DateTime.now())) return 'EXPIRED';
    return status;
  }

  String get statusLabel {
    switch (displayStatus) {
      case 'ACTIVE':
        return 'Đang chạy';
      case 'EXPIRED':
        return 'Hết hạn';
      case 'INACTIVE':
        return 'Đã tắt';
      default:
        return displayStatus;
    }
  }

  Color get statusColor {
    switch (displayStatus) {
      case 'ACTIVE':
        return Colors.green;
      case 'EXPIRED':
        return Colors.red;
      case 'INACTIVE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String get discountLabel {
    if (discountType == 'PERCENT') {
      return '-${CurrencyUtils.formatNumber(discountValue)}%';
    }
    return '-${CurrencyUtils.formatVND(discountValue)}';
  }

  String get branchScopeLabel =>
      isBranchWide ? 'Toàn hệ thống' : 'Theo chi nhánh (${branchIds.length})';

  String get applicableRuleLabel {
    switch (applicableRule.type) {
      case 'category':
        return 'Theo danh mục (${applicableRule.categoryIds.length})';
      case 'product':
        return 'Theo sản phẩm (${applicableRule.productItemIds.length})';
      default:
        return 'Tất cả sản phẩm';
    }
  }

  String get usageLabel =>
      usageLimit != null ? '$usedCount/$usageLimit' : '$usedCount';

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      branchIds: (json['branchIds'] as List? ?? const [])
          .map((e) => e is Map ? (e['_id']?.toString() ?? '') : e.toString())
          .toList(),
      promoName: json['promoName']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discountType']?.toString() ?? 'PERCENT',
      discountValue: (json['discountValue'] as num?) ?? 0,
      maxDiscountAmount: json['maxDiscountAmount'] as num?,
      minOrderValue: (json['minOrderValue'] as num?) ?? 0,
      applicableRule: ApplicableRule.fromJson(
        json['applicableRule'] as Map<String, dynamic>?,
      ),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      stackable: json['stackable'] as bool? ?? false,
      usageLimit: (json['usageLimit'] as num?)?.toInt(),
      usageLimitPerCustomer: (json['usageLimitPerCustomer'] as num?)?.toInt(),
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class PromotionLogModel {
  final String id;
  final String promotionId;
  final String? orderId;
  final String? paymentReference;
  final num discountAmount;
  final String? description;
  final DateTime createdAt;

  const PromotionLogModel({
    required this.id,
    required this.promotionId,
    this.orderId,
    this.paymentReference,
    required this.discountAmount,
    this.description,
    required this.createdAt,
  });

  factory PromotionLogModel.fromJson(Map<String, dynamic> json) {
    return PromotionLogModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      promotionId: json['promotionId']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      paymentReference: json['paymentReference']?.toString(),
      discountAmount: (json['discountAmount'] as num?) ?? 0,
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class PromotionPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PromotionPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PromotionPagination.fromJson(Map<String, dynamic> json) {
    return PromotionPagination(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Request body for `POST /promotions` (create) and `PATCH /promotions/:id`
/// (update). Mirrors the BE DTO validation: `maxDiscountAmount` is only
/// meaningful/sent for PERCENT, and `status` is only sent when editing
/// (create always defaults to ACTIVE server-side).
class PromotionFormPayload {
  final List<String> branchIds;
  final String promoName;
  final String? description;
  final String discountType;
  final num discountValue;
  final num? maxDiscountAmount;
  final num minOrderValue;
  final ApplicableRule applicableRule;
  final DateTime startDate;
  final DateTime endDate;
  final int priority;
  final bool stackable;
  final int? usageLimit;
  final int? usageLimitPerCustomer;
  final String? status;

  const PromotionFormPayload({
    required this.branchIds,
    required this.promoName,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    required this.minOrderValue,
    required this.applicableRule,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.stackable,
    this.usageLimit,
    this.usageLimitPerCustomer,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchIds': branchIds,
      'promoName': promoName,
      if (description != null && description!.isNotEmpty) 'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      if (discountType == 'PERCENT' && maxDiscountAmount != null) 'maxDiscountAmount': maxDiscountAmount,
      'minOrderValue': minOrderValue,
      'applicableRule': {
        'type': applicableRule.type,
        if (applicableRule.type == 'category') 'categoryIds': applicableRule.categoryIds,
        if (applicableRule.type == 'product') 'productItemIds': applicableRule.productItemIds,
      },
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'priority': priority,
      'stackable': stackable,
      'usageLimit': usageLimit,
      'usageLimitPerCustomer': usageLimitPerCustomer,
      if (status != null) 'status': status,
    };
  }
}
