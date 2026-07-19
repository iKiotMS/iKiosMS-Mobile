import '../../models/promotion_model.dart';

/// Abstract interface for the (view-only) promotion repository.
abstract class PromotionRepository {
  Future<List<PromotionModel>> getList({
    String? search,
    String? status,
    required int page,
    required int limit,
  });

  Future<PromotionModel> getDetail(String id);

  Future<List<PromotionLogModel>> getLogs(
    String id, {
    required int page,
    required int limit,
  });

  Future<PromotionModel> create(PromotionFormPayload payload);

  Future<PromotionModel> update(String id, PromotionFormPayload payload);

  /// Soft-deactivate (`DELETE /promotions/:id` sets `status: INACTIVE`,
  /// never hard-deletes).
  Future<PromotionModel> remove(String id);
}
