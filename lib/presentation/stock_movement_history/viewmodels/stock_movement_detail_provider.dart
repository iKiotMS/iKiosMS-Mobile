import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../../data/repositories/stock_movement/stock_movement_repository_provider.dart';

part 'stock_movement_detail_provider.g.dart';

/// Fetches a single movement's full detail (line items populated with
/// product name/sku — the list endpoint intentionally omits these).
@riverpod
Future<StockMovement> stockMovementDetail(Ref ref, String id) {
  final repository = ref.watch(stockMovementRepositoryProvider);
  return repository.getDetail(id);
}
