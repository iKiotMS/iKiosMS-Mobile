import 'package:flutter/material.dart';

import '../../core/utils/currency_utils.dart';

/// Aggregated income/expense totals for a period.
///
/// Maps to the backend `GET /stats/cashflow` payload
/// (`StatsService.getCashflow`): `{ income, expense, net, byType }`.
class CashFlowSummary {
  final num income;
  final num expense;
  final num net;

  const CashFlowSummary({
    required this.income,
    required this.expense,
    required this.net,
  });

  factory CashFlowSummary.fromJson(Map<String, dynamic> json) {
    final income = (json['income'] as num?) ?? 0;
    final expense = (json['expense'] as num?) ?? 0;
    return CashFlowSummary(
      income: income,
      expense: expense,
      net: (json['net'] as num?) ?? (income - expense),
    );
  }

  static const CashFlowSummary empty =
      CashFlowSummary(income: 0, expense: 0, net: 0);

  String get incomeLabel => CurrencyUtils.formatVnd(income);
  String get expenseLabel => CurrencyUtils.formatVnd(expense);
  String get netLabel => CurrencyUtils.formatSignedVnd(net, isIncome: net >= 0);
}

/// A single income/expense entry in the ledger ("sổ thu chi").
///
/// Maps to one item of the backend `GET /stats/cashflow/transactions` payload
/// (`StatsService.getCashflowList`).
class CashFlowEntry {
  final String id;
  final String flowType; // INCOME | EXPENSE
  final num amount;
  final String? paymentMethod; // CASH | BANK_TRANSFER | MOMO | VNPAY | SEPAY
  final String? description;
  final String? paymentReference;
  final String? locationName;
  final String? locationType; // branch | warehouse
  final String? supplierName;
  final String? createdByName;
  final String? orderId;
  final DateTime? createdAt;

  const CashFlowEntry({
    required this.id,
    required this.flowType,
    required this.amount,
    this.paymentMethod,
    this.description,
    this.paymentReference,
    this.locationName,
    this.locationType,
    this.supplierName,
    this.createdByName,
    this.orderId,
    this.createdAt,
  });

  factory CashFlowEntry.fromJson(Map<String, dynamic> json) {
    return CashFlowEntry(
      id: json['_id']?.toString() ?? '',
      flowType: json['flowType']?.toString() ?? 'INCOME',
      amount: (json['amount'] as num?) ?? 0,
      paymentMethod: json['paymentMethod']?.toString(),
      description: json['description']?.toString(),
      paymentReference: json['paymentReference']?.toString(),
      locationName: json['locationName']?.toString(),
      locationType: json['locationType']?.toString(),
      supplierName: json['supplierName']?.toString(),
      createdByName: json['createdByName']?.toString(),
      orderId: json['orderId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  bool get isIncome => flowType == 'INCOME';

  /// Signed amount label, e.g. "+50.000 ₫" or "-20.000 ₫".
  String get signedAmountLabel =>
      CurrencyUtils.formatSignedVnd(amount, isIncome: isIncome);

  /// Vietnamese label for the flow type.
  String get flowTypeLabel => isIncome ? 'Thu' : 'Chi';

  /// Color used for the amount / badge.
  Color get flowColor => isIncome ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

  /// Vietnamese label for the payment method, or null when unset.
  String? get paymentMethodLabel {
    switch (paymentMethod) {
      case 'CASH':
        return 'Tiền mặt';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản';
      case 'MOMO':
        return 'MoMo';
      case 'VNPAY':
        return 'VNPay';
      case 'SEPAY':
        return 'SePay';
      default:
        return paymentMethod;
    }
  }

  /// A human-friendly title for the entry, falling back through the fields the
  /// backend populated for this row.
  String get title {
    if (description != null && description!.trim().isNotEmpty) {
      return description!.trim();
    }
    if (supplierName != null && supplierName!.trim().isNotEmpty) {
      return supplierName!.trim();
    }
    if (orderId != null && orderId!.isNotEmpty) {
      return isIncome ? 'Doanh thu đơn hàng' : 'Hoàn tiền đơn hàng';
    }
    return isIncome ? 'Khoản thu' : 'Khoản chi';
  }
}

/// One page of ledger entries plus its pagination cursor.
class CashFlowPage {
  final List<CashFlowEntry> items;
  final int total;
  final int page;
  final int totalPages;

  const CashFlowPage({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}
