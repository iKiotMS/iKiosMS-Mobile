import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/dashboard_view_model.dart';
import '../widgets/cashflow_inventory.dart';
import '../widgets/metrics_overview.dart';
import '../widgets/revenue_breakdown.dart';
import '../widgets/revenue_by_staff.dart';
import '../widgets/sales_chart.dart';
import '../widgets/top_products.dart';

/// Branch revenue dashboard — "Dashboard doanh thu chi nhánh".
///
/// Mobile equivalent of the web app's `/dashboard` page (branch-scoped
/// mode only; this screen is only reachable by TENANT_OWNER/BRANCH_MANAGER,
/// so the web's separate "warehouse mode" layout is out of scope here).
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);
    final notifier = ref.read(dashboardViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan kinh doanh'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.errorMessage != null) ...[
              _ErrorBanner(message: state.errorMessage!, onRetry: notifier.refetch),
              const SizedBox(height: 12),
            ],
            const MetricsOverview(),
            const SizedBox(height: 16),
            const SalesChart(),
            const SizedBox(height: 16),
            const RevenueBreakdown(),
            const SizedBox(height: 16),
            const RevenueByStaffCard(),
            const SizedBox(height: 16),
            const TopProductsCard(),
            const SizedBox(height: 16),
            const CashflowInventoryCard(),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
