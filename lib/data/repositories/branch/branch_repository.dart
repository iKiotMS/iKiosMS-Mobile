import '../../models/branch_option.dart';

/// Abstract interface for the branch repository.
abstract class BranchRepository {
  /// Fetches the tenant's active branches for pickers/filters.
  Future<List<BranchOption>> getBranches();
}
