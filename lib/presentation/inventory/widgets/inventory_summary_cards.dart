import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_utils.dart';
import '../../dashboard/viewmodels/dashboard_view_model.dart' show lowStockThresholdOptions;
import '../../dashboard/widgets/dashboard_skeleton.dart';
import '../viewmodels/inventory_dashboard_view_model.dart';

/// Stock value / total units / SKU count / out-of-stock summary cards.
///
/// Backed by `GET /stats/inventory`, which is already scoped server-side to
/// the caller's own branch/warehouse — same source data as the "Tồn kho"
/// tab of the branch dashboard built for "Dashboard doanh thu chi nhánh".
class InventorySummaryCards extends ConsumerWidget {
  const InventorySummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(inventoryDashboardViewModelProvider);
    final notifier = ref.read(inventoryDashboardViewModelProvider.notifier);
    final summary = state.summary;

    if (state.isLoadingSummary && summary == null) {
      return const DashboardSkeleton(height: 160);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            _StatCard(label: 'Giá trị tồn kho', value: CurrencyUtils.formatVND(summary?.stockValue ?? 0)),
            _StatCard(label: 'Tổng số lượng', value: CurrencyUtils.formatNumber(summary?.totalUnits ?? 0)),
            _StatCard(label: 'Số SKU', value: CurrencyUtils.formatNumber(summary?.skuCount ?? 0)),
            _StatCard(
              label: 'Hết hàng',
              value: CurrencyUtils.formatNumber(summary?.outOfStock ?? 0),
              valueColor: Colors.red.shade700,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: DropdownButton<int>(
            value: state.lowStockThreshold,
            underline: const SizedBox.shrink(),
            isDense: true,
            onChanged: (value) {
              if (value != null) notifier.setLowStockThreshold(value);
            },
            items: lowStockThresholdOptions
                .map((t) => DropdownMenuItem(value: t, child: Text('Ngưỡng cảnh báo ≤ $t', style: theme.textTheme.bodySmall)))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}
