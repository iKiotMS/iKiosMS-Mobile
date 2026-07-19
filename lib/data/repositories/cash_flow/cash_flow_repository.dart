import '../../models/cash_flow_model.dart';

/// Abstract interface for the cashflow (sổ thu chi) repository.
///
/// The ViewModel depends on this interface, not the concrete implementation.
abstract class CashFlowRepository {
  /// Fetches aggregated income/expense totals for the range.
  Future<CashFlowSummary> getSummary({
    required DateTime fromDate,
    required DateTime toDate,
    String? flowType,
    String? branchId,
  });

  /// Fetches one page of ledger entries for the range.
  Future<CashFlowPage> getTransactions({
    required DateTime fromDate,
    required DateTime toDate,
    String? flowType,
    String? paymentMethod,
    String? branchId,
    int page = 1,
    int limit = 20,
  });
}
