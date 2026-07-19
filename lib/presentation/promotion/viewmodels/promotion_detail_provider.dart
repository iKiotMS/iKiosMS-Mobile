import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/promotion_model.dart';
import '../../../data/repositories/promotion/promotion_repository_provider.dart';

part 'promotion_detail_provider.g.dart';

/// Fetches a single promotion's full detail.
@riverpod
Future<PromotionModel> promotionDetail(Ref ref, String id) {
  final repository = ref.watch(promotionRepositoryProvider);
  return repository.getDetail(id);
}
