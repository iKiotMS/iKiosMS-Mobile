import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/ai_api_service.dart';
import 'ai_repository.dart';
import 'ai_repository_impl.dart';

part 'ai_repository_provider.g.dart';

@riverpod
AIRepository aiRepository(Ref ref) {
  final apiService = ref.watch(aiApiServiceProvider);
  return AIRepositoryImpl(apiService);
}
