import '../../models/stock_movement_model.dart';

/// Abstract interface for the (read-only) stock movement repository.
abstract class StockMovementRepository {
  Future<List<StockMovement>> getList({
    required String movementType,
    String? status,
    required int page,
    required int limit,
  });

  Future<StockMovement> getDetail(String id);
}
