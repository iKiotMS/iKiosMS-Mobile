import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/category_api_service.dart';
import 'category_option_repository.dart';
import 'category_option_repository_impl.dart';

part 'category_option_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [CategoryOptionRepository].
@riverpod
CategoryOptionRepository categoryOptionRepository(Ref ref) {
  final apiService = ref.watch(categoryApiServiceProvider);
  return CategoryOptionRepositoryImpl(apiService);
}
