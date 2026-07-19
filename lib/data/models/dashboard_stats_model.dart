/// Models for the `/stats/*` dashboard endpoints.
///
/// Mirrors the response shapes defined in the web app's
/// `src/lib/api/stats.ts` (types `StatsOverview`, `RevenueSeries`,
/// `RevenueByPaymentMethod`, `RevenueByStaff`, `Cashflow`, `TopProducts`,
/// `InventoryStats`).
library;

num _numOrZero(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

double? _nullableDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

// ── Overview ──────────────────────────────────────────────────────────────

class DashboardChangePct {
  final double? revenue;
  final double? orderCount;
  final double? customerCount;
  final double? aov;

  const DashboardChangePct({
    this.revenue,
    this.orderCount,
    this.customerCount,
    this.aov,
  });

  factory DashboardChangePct.fromJson(Map<String, dynamic> json) {
    return DashboardChangePct(
      revenue: _nullableDouble(json['revenue']),
      orderCount: _nullableDouble(json['orderCount']),
      customerCount: _nullableDouble(json['customerCount']),
      aov: _nullableDouble(json['aov']),
    );
  }
}

class DashboardOverview {
  final num revenue;
  final int orderCount;
  final int customerCount;
  final num aov;
  final DashboardChangePct changePct;

  const DashboardOverview({
    required this.revenue,
    required this.orderCount,
    required this.customerCount,
    required this.aov,
    required this.changePct,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      revenue: _numOrZero(json['revenue']),
      orderCount: (_numOrZero(json['orderCount'])).toInt(),
      customerCount: (_numOrZero(json['customerCount'])).toInt(),
      aov: _numOrZero(json['aov']),
      changePct: DashboardChangePct.fromJson(
        json['changePct'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

// ── Revenue series (sales chart) ─────────────────────────────────────────

class RevenueSeriesPoint {
  final String bucket;
  final num revenue;
  final int orderCount;

  const RevenueSeriesPoint({
    required this.bucket,
    required this.revenue,
    required this.orderCount,
  });

  factory RevenueSeriesPoint.fromJson(Map<String, dynamic> json) {
    return RevenueSeriesPoint(
      bucket: json['bucket']?.toString() ?? '',
      revenue: _numOrZero(json['revenue']),
      orderCount: (_numOrZero(json['orderCount'])).toInt(),
    );
  }
}

class RevenueSeries {
  final String groupBy; // 'day' | 'month'
  final List<RevenueSeriesPoint> series;

  const RevenueSeries({required this.groupBy, required this.series});

  factory RevenueSeries.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'] as List? ?? const [];
    return RevenueSeries(
      groupBy: json['groupBy']?.toString() ?? 'day',
      series: rawSeries
          .map((e) => RevenueSeriesPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Revenue by payment method ────────────────────────────────────────────

class RevenueByPaymentMethodItem {
  final String paymentMethod;
  final num revenue;
  final int orderCount;

  const RevenueByPaymentMethodItem({
    required this.paymentMethod,
    required this.revenue,
    required this.orderCount,
  });

  factory RevenueByPaymentMethodItem.fromJson(Map<String, dynamic> json) {
    return RevenueByPaymentMethodItem(
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      revenue: _numOrZero(json['revenue']),
      orderCount: (_numOrZero(json['orderCount'])).toInt(),
    );
  }
}

class RevenueByPaymentMethod {
  final List<RevenueByPaymentMethodItem> breakdown;

  const RevenueByPaymentMethod({required this.breakdown});

  factory RevenueByPaymentMethod.fromJson(Map<String, dynamic> json) {
    final raw = json['breakdown'] as List? ?? const [];
    return RevenueByPaymentMethod(
      breakdown: raw
          .map((e) => RevenueByPaymentMethodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Vietnamese labels for payment methods, matching `PAYMENT_METHOD_LABELS` on web.
const Map<String, String> paymentMethodLabels = {
  'CASH': 'Tiền mặt',
  'BANK_TRANSFER': 'Chuyển khoản',
  'MOMO': 'MoMo',
  'VNPAY': 'VNPay',
  'SEPAY': 'SePay',
};

// ── Revenue by staff ──────────────────────────────────────────────────────

class RevenueByStaffItem {
  final String userId;
  final String? staffName;
  final num revenue;
  final int orderCount;
  final num aov;

  const RevenueByStaffItem({
    required this.userId,
    this.staffName,
    required this.revenue,
    required this.orderCount,
    required this.aov,
  });

  factory RevenueByStaffItem.fromJson(Map<String, dynamic> json) {
    return RevenueByStaffItem(
      userId: json['userId']?.toString() ?? '',
      staffName: json['staffName']?.toString(),
      revenue: _numOrZero(json['revenue']),
      orderCount: (_numOrZero(json['orderCount'])).toInt(),
      aov: _numOrZero(json['aov']),
    );
  }
}

class RevenueByStaff {
  final List<RevenueByStaffItem> staff;

  const RevenueByStaff({required this.staff});

  factory RevenueByStaff.fromJson(Map<String, dynamic> json) {
    final raw = json['staff'] as List? ?? const [];
    return RevenueByStaff(
      staff: raw
          .map((e) => RevenueByStaffItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Cashflow ──────────────────────────────────────────────────────────────

class CashflowByType {
  final String flowType; // 'INCOME' | 'EXPENSE'
  final num total;
  final int count;

  const CashflowByType({
    required this.flowType,
    required this.total,
    required this.count,
  });

  factory CashflowByType.fromJson(Map<String, dynamic> json) {
    return CashflowByType(
      flowType: json['flowType']?.toString() ?? '',
      total: _numOrZero(json['total']),
      count: (_numOrZero(json['count'])).toInt(),
    );
  }
}

class DashboardCashflow {
  final num income;
  final num expense;
  final num net;
  final List<CashflowByType> byType;

  const DashboardCashflow({
    required this.income,
    required this.expense,
    required this.net,
    required this.byType,
  });

  factory DashboardCashflow.fromJson(Map<String, dynamic> json) {
    final raw = json['byType'] as List? ?? const [];
    return DashboardCashflow(
      income: _numOrZero(json['income']),
      expense: _numOrZero(json['expense']),
      net: _numOrZero(json['net']),
      byType: raw
          .map((e) => CashflowByType.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int countFor(String flowType) {
    return byType
        .firstWhere(
          (t) => t.flowType == flowType,
          orElse: () => const CashflowByType(flowType: '', total: 0, count: 0),
        )
        .count;
  }
}

// ── Top products ──────────────────────────────────────────────────────────

class TopProductItem {
  final String productItemId;
  final String productName;
  final num quantity;
  final num revenue;

  const TopProductItem({
    required this.productItemId,
    required this.productName,
    required this.quantity,
    required this.revenue,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> json) {
    return TopProductItem(
      productItemId: json['productItemId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      quantity: _numOrZero(json['quantity']),
      revenue: _numOrZero(json['revenue']),
    );
  }
}

class TopProducts {
  final String sortBy; // 'quantity' | 'revenue'
  final List<TopProductItem> products;

  const TopProducts({required this.sortBy, required this.products});

  factory TopProducts.fromJson(Map<String, dynamic> json) {
    final raw = json['products'] as List? ?? const [];
    return TopProducts(
      sortBy: json['sortBy']?.toString() ?? 'quantity',
      products: raw
          .map((e) => TopProductItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Inventory ─────────────────────────────────────────────────────────────

class LowStockItem {
  final String productItemId;
  final String productName;
  final String sku;
  final String locationId;
  final String locationType; // 'branch' | 'warehouse'
  final num stock;

  const LowStockItem({
    required this.productItemId,
    required this.productName,
    required this.sku,
    required this.locationId,
    required this.locationType,
    required this.stock,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      productItemId: json['productItemId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      locationId: json['locationId']?.toString() ?? '',
      locationType: json['locationType']?.toString() ?? '',
      stock: _numOrZero(json['stock']),
    );
  }
}

class InventoryStats {
  final num stockValue;
  final num totalUnits;
  final int skuCount;
  final int outOfStock;
  final int lowStockThreshold;
  final List<LowStockItem> lowStock;

  const InventoryStats({
    required this.stockValue,
    required this.totalUnits,
    required this.skuCount,
    required this.outOfStock,
    required this.lowStockThreshold,
    required this.lowStock,
  });

  factory InventoryStats.fromJson(Map<String, dynamic> json) {
    final raw = json['lowStock'] as List? ?? const [];
    return InventoryStats(
      stockValue: _numOrZero(json['stockValue']),
      totalUnits: _numOrZero(json['totalUnits']),
      skuCount: (_numOrZero(json['skuCount'])).toInt(),
      outOfStock: (_numOrZero(json['outOfStock'])).toInt(),
      lowStockThreshold: (_numOrZero(json['lowStockThreshold'])).toInt(),
      lowStock: raw
          .map((e) => LowStockItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
