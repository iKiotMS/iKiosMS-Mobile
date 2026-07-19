import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/viewmodels/user_profile_provider.dart';
import '../viewmodels/branch_options_provider.dart';
import '../viewmodels/cash_flow_view_model.dart';
import '../widgets/cash_flow_branch_picker.dart';
import '../widgets/cash_flow_filter_bar.dart';
import '../widgets/cash_flow_summary_card.dart';
import '../widgets/cash_flow_tile.dart';

/// "Sổ thu chi" — a read-only income/expense ledger for Owner/Manager roles.
///
/// Reads from `GET /stats/cashflow` (summary) and
/// `GET /stats/cashflow/transactions` (paginated list) via [CashFlowViewModel].
class CashFlowView extends ConsumerWidget {
  const CashFlowView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashFlowViewModelProvider);
    final vm = ref.read(cashFlowViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ thu chi'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 240) {
              vm.loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildBranchPicker(context, ref, state),
                      CashFlowSummaryCard(summary: state.summary),
                      const SizedBox(height: 16),
                      CashFlowFilterBar(
                        range: state.range,
                        typeFilter: state.typeFilter,
                        onRangeChanged: vm.setRange,
                        onTypeChanged: vm.setTypeFilter,
                      ),
                    ],
                  ),
                ),
              ),
              ..._buildBody(context, ref, state),
            ],
          ),
        ),
      ),
    );
  }

  /// Branch dropdown, shown only for TENANT_OWNER (managers are branch-locked
  /// server-side). Renders nothing while branches load or if the fetch fails.
  Widget _buildBranchPicker(BuildContext context, WidgetRef ref, CashFlowState state) {
    final role = ref.watch(userProfileProvider).valueOrNull?.role;
    if (role != 'TENANT_OWNER') return const SizedBox.shrink();

    final branchesAsync = ref.watch(branchOptionsProvider);
    final branches = branchesAsync.valueOrNull ?? const [];
    if (branches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CashFlowBranchPicker(
        branches: branches,
        selectedBranchId: state.branchId,
        onChanged: ref.read(cashFlowViewModelProvider.notifier).setBranch,
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, WidgetRef ref, CashFlowState state) {
    if (state.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Padding(
            padding: EdgeInsets.only(bottom: 80),
            child: CircularProgressIndicator(),
          )),
        ),
      ];
    }

    if (state.errorMessage != null && state.entries.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageView(
            icon: Icons.error_outline_rounded,
            message: state.errorMessage!,
            onRetry: () => ref.read(cashFlowViewModelProvider.notifier).refresh(),
          ),
        ),
      ];
    }

    if (state.entries.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageView(
            icon: Icons.receipt_long_outlined,
            message: 'Không có giao dịch nào trong khoảng thời gian này.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: state.entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => CashFlowTile(entry: state.entries[index]),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: state.isLoadingMore
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (state.hasMore
                    ? const SizedBox.shrink()
                    : Text(
                        'Đã hiển thị tất cả',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      )),
          ),
        ),
      ),
    ];
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _MessageView({required this.icon, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
