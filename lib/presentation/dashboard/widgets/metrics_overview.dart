import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_utils.dart';
import '../viewmodels/dashboard_view_model.dart';
import 'dashboard_skeleton.dart';

class _Metric {
  final String title;
  final String value;
  final double? changePct;
  final IconData icon;
  final String footer;

  const _Metric({
    required this.title,
    required this.value,
    required this.changePct,
    required this.icon,
    required this.footer,
  });

  bool get isUp => (changePct ?? 0) >= 0;
}

/// 4 KPI cards: Tổng doanh thu, Khách hàng, Tổng đơn hàng, Giá trị đơn trung bình.
///
/// Mirrors the web dashboard's `MetricsOverview` component.
class MetricsOverview extends ConsumerWidget {
  const MetricsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);
    final overview = state.overview;

    if (state.isLoading && overview == null) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: List.generate(4, (_) => const DashboardSkeleton(height: double.infinity)),
      );
    }

    if (overview == null) return const SizedBox.shrink();

    final metrics = [
      _Metric(
        title: 'Tổng doanh thu',
        value: CurrencyUtils.formatVND(overview.revenue),
        changePct: overview.changePct.revenue,
        icon: Icons.attach_money_rounded,
        footer: 'Doanh thu trong kỳ',
      ),
      _Metric(
        title: 'Khách hàng',
        value: CurrencyUtils.formatNumber(overview.customerCount),
        changePct: overview.changePct.customerCount,
        icon: Icons.people_outline_rounded,
        footer: 'Khách hàng có phát sinh đơn',
      ),
      _Metric(
        title: 'Tổng đơn hàng',
        value: CurrencyUtils.formatNumber(overview.orderCount),
        changePct: overview.changePct.orderCount,
        icon: Icons.shopping_cart_outlined,
        footer: 'Đơn hàng đã hoàn tất',
      ),
      _Metric(
        title: 'Giá trị đơn TB',
        value: CurrencyUtils.formatVND(overview.aov),
        changePct: overview.changePct.aov,
        icon: Icons.bar_chart_rounded,
        footer: 'Doanh thu / số đơn',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: metrics.map((m) => _MetricCard(metric: m)).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor = metric.isUp ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(metric.icon, size: 18, color: theme.colorScheme.primary),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        metric.isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 12,
                        color: trendColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        CurrencyUtils.formatPercent(metric.changePct),
                        style: theme.textTheme.labelSmall?.copyWith(color: trendColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.title,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.footer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
