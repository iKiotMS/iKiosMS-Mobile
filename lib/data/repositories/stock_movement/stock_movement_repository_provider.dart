import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/stock_movement_api_service.dart';
import 'stock_movement_repository.dart';
import 'stock_movement_repository_impl.dart';

part 'stock_movement_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [StockMovementRepository].
@riverpod
StockMovementRepository stockMovementRepository(Ref ref) {
  final apiService = ref.watch(stockMovementApiServiceProvider);
  return StockMovementRepositoryImpl(apiService);
}
