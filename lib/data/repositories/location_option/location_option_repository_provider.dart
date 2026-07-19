import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/location_option_api_service.dart';
import 'location_option_repository.dart';
import 'location_option_repository_impl.dart';

part 'location_option_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [LocationOptionRepository].
@riverpod
LocationOptionRepository locationOptionRepository(Ref ref) {
  final apiService = ref.watch(locationOptionApiServiceProvider);
  return LocationOptionRepositoryImpl(apiService);
}
