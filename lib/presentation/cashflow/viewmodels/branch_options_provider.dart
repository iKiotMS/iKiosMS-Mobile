import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/branch_option.dart';
import '../../../data/repositories/branch/branch_repository_provider.dart';

part 'branch_options_provider.g.dart';

/// Loads the tenant's active branches for the cashflow branch picker.
///
/// Only watched for TENANT_OWNER (branch managers are locked to their branch
/// server-side, so the picker isn't shown for them).
@riverpod
Future<List<BranchOption>> branchOptions(Ref ref) {
  return ref.watch(branchRepositoryProvider).getBranches();
}
