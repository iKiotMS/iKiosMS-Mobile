import '../../models/stock_movement_model.dart';

/// Abstract interface for the stock movement repository: read (history +
/// ADJUST list/detail) plus the ADJUST create/approve/cancel actions.
abstract class StockMovementRepository {
  Future<List<StockMovement>> getList({
    required String movementType,
    String? status,
    required int page,
    required int limit,
  });

  Future<StockMovement> getDetail(String id);

  Future<StockMovement> createAdjustment({
    required String locationId,
    required String locationType,
    String? note,
    required List<AdjustmentDetailInput> details,
  });

  Future<StockMovement> approveAdjust(String id);

  Future<StockMovement> cancel(String id);
}
