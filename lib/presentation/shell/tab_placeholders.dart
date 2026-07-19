// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/viewmodels/user_profile_provider.dart';
import '../dashboard/viewmodels/dashboard_view_model.dart';
import '../dashboard/widgets/cashflow_inventory.dart';
import '../dashboard/widgets/metrics_overview.dart';
import '../dashboard/widgets/revenue_breakdown.dart';
import '../dashboard/widgets/revenue_by_staff.dart';
import '../dashboard/widgets/sales_chart.dart';
import '../dashboard/widgets/top_products.dart';

/// Home tab. Shows the branch revenue dashboard (mobile equivalent of the
/// web app's `/dashboard` page, branch-scoped mode only) for
/// TENANT_OWNER/BRANCH_MANAGER, and a generic welcome screen for other roles.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userProfileProvider).value?.role;
    final showRevenueDashboard = role == 'TENANT_OWNER' || role == 'BRANCH_MANAGER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        centerTitle: true,
      ),
      body: showRevenueDashboard ? const _RevenueDashboardBody() : const _WelcomeBody(),
    );
  }
}

class _RevenueDashboardBody extends ConsumerWidget {
  const _RevenueDashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);
    final notifier = ref.read(dashboardViewModelProvider.notifier);

    return RefreshIndicator(
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

class _WelcomeBody extends StatelessWidget {
  const _WelcomeBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chào mừng bạn trở lại!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tính năng sẽ được cập nhật trong tương lai. Hãy quay lại sau nhé!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

