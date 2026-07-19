import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/inventory_api_service.dart';
import 'inventory_repository.dart';
import 'inventory_repository_impl.dart';

part 'inventory_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [InventoryRepository].
@riverpod
InventoryRepository inventoryRepository(Ref ref) {
  final apiService = ref.watch(inventoryApiServiceProvider);
  return InventoryRepositoryImpl(apiService);
}
