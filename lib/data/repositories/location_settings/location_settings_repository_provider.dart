import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/location_settings_api_service.dart';
import 'location_settings_repository.dart';
import 'location_settings_repository_impl.dart';

part 'location_settings_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [LocationSettingsRepository].
@riverpod
LocationSettingsRepository locationSettingsRepository(Ref ref) {
  final apiService = ref.watch(locationSettingsApiServiceProvider);
  return LocationSettingsRepositoryImpl(apiService);
}
