import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/promotion_api_service.dart';
import 'promotion_repository.dart';
import 'promotion_repository_impl.dart';

part 'promotion_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [PromotionRepository].
@riverpod
PromotionRepository promotionRepository(Ref ref) {
  final apiService = ref.watch(promotionApiServiceProvider);
  return PromotionRepositoryImpl(apiService);
}
