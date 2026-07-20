import '../../../data/models/stock_movement_model.dart';

/// Whether [role] is allowed to create an IMPORT ("Nhập hàng") request.
///
/// Mirrors `StockMovementService.create`: TENANT_OWNER and WAREHOUSE_MANAGER
/// only — BRANCH_MANAGER is explicitly rejected server-side for IMPORT, and
/// STAFF has no `stock_movement` permission at all (nor via a managed
/// working-schedule grant, which excludes IMPORT).
bool canCreateImport(String? role) {
  return role == 'TENANT_OWNER' || role == 'WAREHOUSE_MANAGER';
}

/// Which lifecycle actions the signed-in user may take on an IMPORT request,
/// derived from its status and whether the user "acts as" its from/to
/// location. Mirrors the web app's `movement-expanded-panel.tsx` gates
/// (`canEditOpening`/`canShipImportPending`/`canReceiveTransit`/`canCancel`
/// for `mode==="import"`), which were themselves reverse-engineered from
/// `StockMovementService`'s `_checkLocationAuth` checks.
///
/// Note: the create flow deliberately sets `fromLocationId`/`fromLocationType`
/// equal to `toLocationId`/`toLocationType`, so "acts as from" and "acts as
/// to" resolve to the same actor for a request created through this app —
/// that's what lets the destination warehouse manager both ship and receive.
class ImportActionFlags {
  final bool canEditDetails;
  final bool canShip;
  final bool canReceive;
  final bool canCancel;

  const ImportActionFlags({
    required this.canEditDetails,
    required this.canShip,
    required this.canReceive,
    required this.canCancel,
  });

  static const none = ImportActionFlags(
    canEditDetails: false,
    canShip: false,
    canReceive: false,
    canCancel: false,
  );
}

bool _actsAsLocation({
  required String? role,
  required String? userWarehouseId,
  required String? locationId,
  required String? locationType,
}) {
  if (role == 'TENANT_OWNER') return true;
  if (role == 'WAREHOUSE_MANAGER') {
    return locationType == 'warehouse' && userWarehouseId != null && locationId == userWarehouseId;
  }
  return false;
}

ImportActionFlags computeImportActionFlags({
  required String? role,
  required String? userWarehouseId,
  required StockMovementModel movement,
}) {
  final actsAsFrom = _actsAsLocation(
    role: role,
    userWarehouseId: userWarehouseId,
    locationId: movement.fromLocationId,
    locationType: movement.fromLocationType,
  );
  final actsAsTo = _actsAsLocation(
    role: role,
    userWarehouseId: userWarehouseId,
    locationId: movement.toLocationId,
    locationType: movement.toLocationType,
  );

  final isPending = movement.status == 'PENDING';
  final isInTransit = movement.status == 'IN_TRANSIT';
  final isReceived = movement.status == 'RECEIVED';
  final isTerminal = movement.status == 'COMPLETED' || movement.status == 'CANCELLED';

  final canShip = isPending && actsAsFrom;
  final canEditDetails = isPending && actsAsTo;
  final canReceive = actsAsTo && (isInTransit || (isPending && !canShip));
  final canCancel = actsAsFrom && !isReceived && !isTerminal;

  return ImportActionFlags(
    canEditDetails: canEditDetails,
    canShip: canShip,
    canReceive: canReceive,
    canCancel: canCancel,
  );
}
