import 'package:flutter/material.dart';

/// Vietnamese labels + colors for movement status/type, mirroring the web
/// app's `exchange/shared/movement-labels.ts` (`MOVEMENT_STATUS_MAP`,
/// `MOVEMENT_TYPE_MAP`).
class MovementStatusConfig {
  final String label;
  final Color color;

  const MovementStatusConfig(this.label, this.color);
}

const Map<String, MovementStatusConfig> movementStatusMap = {
  'DRAFT': MovementStatusConfig('Nháp', Colors.grey),
  'OPENING': MovementStatusConfig('Đang soạn', Colors.amber),
  'CLOSED': MovementStatusConfig('Đã chốt', Colors.blue),
  'PENDING': MovementStatusConfig('Chờ giao hàng', Colors.amber),
  'IN_TRANSIT': MovementStatusConfig('Đang vận chuyển', Colors.blue),
  'RECEIVED': MovementStatusConfig('Đã nhận hàng', Colors.green),
  'CANCELLED': MovementStatusConfig('Đã huỷ', Colors.grey),
  'COMPLETED': MovementStatusConfig('Hoàn tất', Colors.green),
};

MovementStatusConfig movementStatusConfig(String status) {
  return movementStatusMap[status] ?? MovementStatusConfig(status, Colors.grey);
}

class MovementTypeConfig {
  final String label;
  final Color color;

  const MovementTypeConfig(this.label, this.color);
}

const Map<String, MovementTypeConfig> movementTypeMap = {
  'IMPORT': MovementTypeConfig('Nhập hàng', Colors.blue),
  'EXPORT': MovementTypeConfig('Xuất kho', Colors.orange),
  'RETURN': MovementTypeConfig('Trả kho', Color(0xFFB45309)),
  'ADJUST': MovementTypeConfig('Điều chỉnh', Colors.purple),
};

MovementTypeConfig movementTypeConfig(String movementType) {
  return movementTypeMap[movementType] ?? MovementTypeConfig(movementType, Colors.grey);
}

const Map<String, String> locationTypeLabels = {
  'branch': 'Chi nhánh',
  'warehouse': 'Kho',
};

/// Status filter options shown for the history screen — the union of
/// statuses IMPORT/EXPORT/RETURN movements actually use (excludes ADJUST's
/// own vocabulary, since ADJUST is out of scope here).
const List<String> movementStatusFilterOptions = [
  'DRAFT',
  'OPENING',
  'CLOSED',
  'PENDING',
  'IN_TRANSIT',
  'RECEIVED',
  'CANCELLED',
  'COMPLETED',
];
