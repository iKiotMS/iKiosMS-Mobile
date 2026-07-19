import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_time_utils.dart';
import '../viewmodels/dashboard_view_model.dart';
import 'dashboard_skeleton.dart';

String _shortBucketLabel(String bucket, String groupBy) {
  final parts = bucket.split('-');
  if (groupBy == 'month' && parts.length == 2) {
    return '${parts[1]}/${parts[0]}';
  }
  if (parts.length == 3) {
    return '${parts[2]}/${parts[1]}';
  }
  return bucket;
}

/// Revenue-over-time area chart with a period selector (7d/30d/90d/12m).
///
/// Mirrors the web dashboard's `SalesChart` component.
class SalesChart extends ConsumerWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final theme = Theme.of(context);
    final groupBy = state.range.groupBy;

    final buckets = DateTimeUtils.generateDateBuckets(
      state.fromDate,
      state.toDate,
      groupBy,
    );
    final seriesByBucket = <String, num>{
      for (final p in state.revenue?.series ?? const []) p.bucket: p.revenue,
    };
    final spots = <FlSpot>[
      for (var i = 0; i < buckets.length; i++)
        FlSpot(i.toDouble(), (seriesByBucket[buckets[i]] ?? 0).toDouble()),
    ];
    final rawMaxY = spots.isEmpty ? 0.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxY = rawMaxY > 0 ? rawMaxY * 1.2 : 100.0;

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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doanh thu theo thời gian',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Doanh thu đơn hàng đã hoàn tất',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                DropdownButton<DashboardRange>(
                  value: state.range,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  onChanged: (range) {
                    if (range != null) notifier.setRange(range);
                  },
                  items: DashboardRange.values
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.label, style: theme.textTheme.bodySmall),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isLoading && state.revenue == null)
              const DashboardSkeleton(height: 240)
            else if (spots.isEmpty)
              SizedBox(
                height: 240,
                child: Center(
                  child: Text(
                    'Chưa có dữ liệu doanh thu trong khoảng thời gian này',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              SizedBox(
                height: 240,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: (buckets.length / 4).ceilToDouble().clamp(1, double.infinity),
                          getTitlesWidget: (value, meta) {
                            final index = value.round();
                            if (index < 0 || index >= buckets.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _shortBucketLabel(buckets[index], groupBy),
                                style: theme.textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                          final index = s.x.round();
                          final label = index >= 0 && index < buckets.length
                              ? _shortBucketLabel(buckets[index], groupBy)
                              : '';
                          return LineTooltipItem(
                            '$label\n${CurrencyUtils.formatVND(s.y)}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.35),
                              theme.colorScheme.primary.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
