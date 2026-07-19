import '../../../data/models/stock_movement_model.dart';

/// Whether the signed-in user is allowed to approve/cancel [adjustment].
///
/// Mirrors the backend's `_checkLocationAuth` check used by both
/// `approveAdjust` and `cancel` (`StockMovementService`): TENANT_OWNER can
/// always act; BRANCH_MANAGER/WAREHOUSE_MANAGER only on a PENDING request
/// whose `fromLocationId`/`fromLocationType` matches their own branch/
/// warehouse. Hiding the buttons client-side when this is false avoids a
/// confusing 403 — the backend still enforces it independently.
bool canActOnAdjustment({
  required String? role,
  required String? userBranchId,
  required String? userWarehouseId,
  required StockMovement adjustment,
}) {
  if (adjustment.status != 'PENDING') return false;
  if (role == 'TENANT_OWNER') return true;
  if (role == 'BRANCH_MANAGER') {
    return adjustment.fromLocationType == 'branch' && adjustment.fromLocationId == userBranchId;
  }
  if (role == 'WAREHOUSE_MANAGER') {
    return adjustment.fromLocationType == 'warehouse' && adjustment.fromLocationId == userWarehouseId;
  }
  return false;
}
