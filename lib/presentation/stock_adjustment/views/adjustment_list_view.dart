import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/widgets/dashboard_skeleton.dart';
import '../shared/adjustment_labels.dart';
import '../viewmodels/adjustment_list_view_model.dart';
import '../widgets/adjustment_tile.dart';
import 'adjustment_create_view.dart';
import 'adjustment_detail_view.dart';

/// "Điều chỉnh tồn kho" — list of stock-count adjustment requests (create
/// new ones via the FAB; tap a row to view detail and approve/cancel).
///
/// Mobile equivalent of the web app's `/exchange/adjustments` page.
class AdjustmentListView extends ConsumerWidget {
  const AdjustmentListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(adjustmentListViewModelProvider);
    final notifier = ref.read(adjustmentListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều chỉnh tồn kho'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdjustmentCreateView()),
          );
          if (created == true) notifier.refetch();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo điều chỉnh'),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refetch,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (state.errorMessage != null) ...[
              _ErrorBanner(message: state.errorMessage!, onRetry: notifier.refetch),
              const SizedBox(height: 12),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusChip(label: 'Tất cả', selected: state.statusFilter == null, onTap: () => notifier.setStatusFilter(null)),
                  for (final status in adjustmentStatusFilterOptions) ...[
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: adjustmentStatusConfig(status).label,
                      selected: state.statusFilter == status,
                      onTap: () => notifier.setStatusFilter(status),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (state.isLoading && state.adjustments.isEmpty)
              Column(
                children: List.generate(
                  4,
                  (i) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: DashboardSkeleton(height: 110),
                  ),
                ),
              )
            else if (state.adjustments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.fact_check_outlined, size: 32, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có phiếu điều chỉnh tồn kho nào',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ...state.adjustments.map(
                (adjustment) => AdjustmentTile(
                  adjustment: adjustment,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AdjustmentDetailView(adjustmentId: adjustment.id)),
                    );
                    notifier.refetch();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
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
          Expanded(child: Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
