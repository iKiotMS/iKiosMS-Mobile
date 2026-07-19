import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/stats_api_service.dart';
import 'stats_repository.dart';
import 'stats_repository_impl.dart';

part 'stats_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [StatsRepository].
@riverpod
StatsRepository statsRepository(Ref ref) {
  final apiService = ref.watch(statsApiServiceProvider);
  return StatsRepositoryImpl(apiService);
}
