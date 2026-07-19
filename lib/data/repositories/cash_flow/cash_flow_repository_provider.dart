import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/cash_flow_api_service.dart';
import 'cash_flow_repository.dart';
import 'cash_flow_repository_impl.dart';

part 'cash_flow_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [CashFlowRepository].
///
/// ViewModels use `ref.watch(cashFlowRepositoryProvider)`. Swap the concrete
/// implementation (e.g. a mock for testing) only here.
@riverpod
CashFlowRepository cashFlowRepository(Ref ref) {
  final apiService = ref.watch(cashFlowApiServiceProvider);
  return CashFlowRepositoryImpl(apiService);
}
