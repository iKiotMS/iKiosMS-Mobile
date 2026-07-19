import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/promotion_model.dart';
import '../../../data/repositories/promotion/promotion_repository_provider.dart';

part 'promotion_logs_provider.g.dart';

const int _logsLimit = 50;

/// Fetches a promotion's usage-log history (first page, matches the web
/// panel's default `recordPerPage: 50`).
@riverpod
Future<List<PromotionLogModel>> promotionLogs(Ref ref, String id) {
  final repository = ref.watch(promotionRepositoryProvider);
  return repository.getLogs(id, page: 1, limit: _logsLimit);
}
