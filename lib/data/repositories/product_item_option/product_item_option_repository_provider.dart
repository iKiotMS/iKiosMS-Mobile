import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/product_item_api_service.dart';
import 'product_item_option_repository.dart';
import 'product_item_option_repository_impl.dart';

part 'product_item_option_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [ProductItemOptionRepository].
@riverpod
ProductItemOptionRepository productItemOptionRepository(Ref ref) {
  final apiService = ref.watch(productItemApiServiceProvider);
  return ProductItemOptionRepositoryImpl(apiService);
}
