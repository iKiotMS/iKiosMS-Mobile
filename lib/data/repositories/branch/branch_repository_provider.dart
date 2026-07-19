import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/branch_api_service.dart';
import 'branch_repository.dart';
import 'branch_repository_impl.dart';

part 'branch_repository_provider.g.dart';

/// Riverpod-generated provider that exposes [BranchRepository].
@riverpod
BranchRepository branchRepository(Ref ref) {
  final apiService = ref.watch(branchApiServiceProvider);
  return BranchRepositoryImpl(apiService);
}
