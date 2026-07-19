import 'package:flutter/material.dart';

import 'movement_labels.dart';

/// ADJUST-specific status vocabulary. The shared `movementStatusMap` in
/// `stock_adjustment/shared/movement_labels.dart` labels `PENDING` as
/// "Chờ giao hàng" (a delivery-flow phrase for IMPORT/EXPORT) — inaccurate
/// for an adjustment, which is awaiting approval, not delivery. `ADJUST`
/// only ever uses PENDING/COMPLETED/CANCELLED (see `StockMovementRequest`
/// model + `StockMovementService.approveAdjust`).
const Map<String, MovementStatusConfig> adjustmentStatusMap = {
  'PENDING': MovementStatusConfig('Chờ duyệt', Colors.amber),
  'COMPLETED': MovementStatusConfig('Đã duyệt', Colors.green),
  'CANCELLED': MovementStatusConfig('Đã huỷ', Colors.grey),
};

MovementStatusConfig adjustmentStatusConfig(String status) {
  return adjustmentStatusMap[status] ?? MovementStatusConfig(status, Colors.grey);
}

const List<String> adjustmentStatusFilterOptions = ['PENDING', 'COMPLETED', 'CANCELLED'];
