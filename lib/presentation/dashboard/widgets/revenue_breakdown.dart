import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../data/models/dashboard_stats_model.dart';
import '../viewmodels/dashboard_view_model.dart';
import 'dashboard_skeleton.dart';

const List<Color> _chartColors = [
  Color(0xFF2563EB), // blue
  Color(0xFF16A34A), // green
  Color(0xFFF59E0B), // amber
  Color(0xFFDB2777), // pink
  Color(0xFF7C3AED), // violet
];

class _BreakdownEntry {
  final String method;
  final String label;
  final num amount;
  final int orderCount;
  final int percent;
  final Color color;

  const _BreakdownEntry({
    required this.method,
    required this.label,
    required this.amount,
    required this.orderCount,
    required this.percent,
    required this.color,
  });
}

/// Donut chart of revenue by payment method, with a tappable legend.
///
/// Mirrors the web dashboard's `RevenueBreakdown` component.
class RevenueBreakdown extends ConsumerStatefulWidget {
  const RevenueBreakdown({super.key});

  @override
  ConsumerState<RevenueBreakdown> createState() => _RevenueBreakdownState();
}

class _RevenueBreakdownState extends ConsumerState<RevenueBreakdown> {
  String? _activeMethod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(dashboardViewModelProvider);
    final breakdown = state.revenueByPaymentMethod?.breakdown ?? const <RevenueByPaymentMethodItem>[];
    final totalRevenue = breakdown.fold<num>(0, (sum, item) => sum + item.revenue);

    final entries = <_BreakdownEntry>[
      for (var i = 0; i < breakdown.length; i++)
        _BreakdownEntry(
          method: breakdown[i].paymentMethod,
          label: paymentMethodLabels[breakdown[i].paymentMethod] ?? breakdown[i].paymentMethod,
          amount: breakdown[i].revenue,
          orderCount: breakdown[i].orderCount,
          percent: totalRevenue > 0 ? ((breakdown[i].revenue / totalRevenue) * 100).round() : 0,
          color: _chartColors[i % _chartColors.length],
        ),
    ];

    final activeIndex = entries.isEmpty
        ? 0
        : (entries.indexWhere((e) => e.method == _activeMethod) == -1
            ? 0
            : entries.indexWhere((e) => e.method == _activeMethod));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cơ cấu doanh thu', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              'Doanh thu theo phương thức thanh toán',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.revenueByPaymentMethod == null)
              const DashboardSkeleton(height: 260)
            else if (entries.isEmpty)
              SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'Chưa có dữ liệu doanh thu trong khoảng thời gian này',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 55,
                        sections: [
                          for (var i = 0; i < entries.length; i++)
                            PieChartSectionData(
                              value: entries[i].amount.toDouble(),
                              color: entries[i].color,
                              radius: i == activeIndex ? 42 : 36,
                              showTitle: false,
                            ),
                        ],
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            final index = response?.touchedSection?.touchedSectionIndex;
                            if (index != null && index >= 0 && index < entries.length && event.isInterestedForInteractions) {
                              setState(() => _activeMethod = entries[index].method);
                            }
                          },
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyUtils.formatCompactVND(entries[activeIndex].amount),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          entries[activeIndex].label,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...entries.asMap().entries.map((e) {
                final index = e.key;
                final item = e.value;
                final isActive = index == activeIndex;
                return InkWell(
                  onTap: () => setState(() => _activeMethod = item.method),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyUtils.formatCompactVND(item.amount),
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text('${item.percent}%', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
