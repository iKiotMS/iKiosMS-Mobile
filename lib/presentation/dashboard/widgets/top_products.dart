import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_utils.dart';
import '../viewmodels/dashboard_view_model.dart';
import 'dashboard_skeleton.dart';

/// Best-selling products list with a sort selector (Doanh thu / Số lượng).
///
/// Mirrors the web dashboard's `TopProducts` component.
class TopProductsCard extends ConsumerWidget {
  const TopProductsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(dashboardViewModelProvider);
    final notifier = ref.read(dashboardViewModelProvider.notifier);
    final products = state.topProducts?.products ?? const [];
    final sortBy = state.topProductsSortBy;

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
                      Text('Sản phẩm bán chạy', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        'Xếp hạng theo ${sortBy == "revenue" ? "doanh thu" : "số lượng"} trong kỳ',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  value: sortBy,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  onChanged: (value) {
                    if (value != null) notifier.setTopProductsSortBy(value);
                  },
                  items: const [
                    DropdownMenuItem(value: 'revenue', child: Text('Doanh thu')),
                    DropdownMenuItem(value: 'quantity', child: Text('Số lượng')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isLoading && state.topProducts == null)
              Column(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DashboardSkeleton(height: 64),
                  ),
                ),
              )
            else if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 32, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có sản phẩm bán ra trong khoảng thời gian này',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ...products.asMap().entries.map((e) {
                final index = e.key;
                final product = e.value;
                final primary = sortBy == 'revenue'
                    ? CurrencyUtils.formatVND(product.revenue)
                    : '${CurrencyUtils.formatNumber(product.quantity)} sản phẩm';
                final secondary = sortBy == 'revenue'
                    ? '${CurrencyUtils.formatNumber(product.quantity)} sản phẩm đã bán'
                    : CurrencyUtils.formatVND(product.revenue);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                            Text(secondary, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(primary, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
