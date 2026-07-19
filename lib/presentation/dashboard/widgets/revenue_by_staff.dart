import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_utils.dart';
import '../viewmodels/dashboard_view_model.dart';
import 'dashboard_skeleton.dart';

String _initialsOf(String name) {
  final parts = name.split(' ').where((p) => p.isNotEmpty).take(2).toList();
  return parts.map((p) => p[0].toUpperCase()).join();
}

/// Staff revenue ranking list.
///
/// Mirrors the web dashboard's `RevenueByStaff` component
/// (`recent-transactions.tsx` on web — legacy filename there).
class RevenueByStaffCard extends ConsumerWidget {
  const RevenueByStaffCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(dashboardViewModelProvider);
    final staff = state.revenueByStaff?.staff ?? const [];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doanh thu theo nhân viên', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              'Xếp hạng theo doanh thu đơn hàng đã hoàn tất',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (state.isLoading && state.revenueByStaff == null)
              Column(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DashboardSkeleton(height: 64),
                  ),
                ),
              )
            else if (staff.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.people_outline_rounded, size: 32, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có doanh thu nhân viên trong khoảng thời gian này',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ...staff.map((member) {
                final displayName = member.staffName ?? member.userId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(_initialsOf(displayName), style: theme.textTheme.labelSmall),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                            Text(
                              '${CurrencyUtils.formatNumber(member.orderCount)} đơn · TB ${CurrencyUtils.formatVND(member.aov)}/đơn',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(CurrencyUtils.formatVND(member.revenue), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
