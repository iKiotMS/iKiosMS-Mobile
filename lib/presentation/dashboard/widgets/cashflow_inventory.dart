import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_utils.dart';
import '../viewmodels/dashboard_view_model.dart';
import 'dashboard_skeleton.dart';

/// Fallback label shown for a low-stock row's location when the actual
/// branch/warehouse name can't be resolved (no branch/warehouse lookup API
/// exists in the mobile app yet — this mirrors the web dashboard's own
/// fallback path, `LOCATION_TYPE_LABELS[locationType] ?? locationType`).
const Map<String, String> _locationTypeLabels = {
  'branch': 'Chi nhánh',
  'warehouse': 'Kho',
};

/// Cashflow (income/expense/net) + inventory (stock value, low-stock table)
/// in a two-tab card.
///
/// Mirrors the web dashboard's `CashflowInventory` component
/// (`customer-insights.tsx` on web — legacy filename there). This dashboard
/// is only ever shown in branch mode (TENANT_OWNER/BRANCH_MANAGER), so the
/// warehouse-mode label variants from web are not needed here.
class CashflowInventoryCard extends ConsumerStatefulWidget {
  const CashflowInventoryCard({super.key});

  @override
  ConsumerState<CashflowInventoryCard> createState() => _CashflowInventoryCardState();
}

class _CashflowInventoryCardState extends ConsumerState<CashflowInventoryCard> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(dashboardViewModelProvider);
    final notifier = ref.read(dashboardViewModelProvider.notifier);

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
            Text('Dòng tiền & Tồn kho', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              'Thu chi bán hàng và tình trạng tồn kho hiện tại',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Dòng tiền'), icon: Icon(Icons.account_balance_wallet_outlined, size: 16)),
                ButtonSegment(value: 1, label: Text('Tồn kho'), icon: Icon(Icons.inventory_outlined, size: 16)),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (selection) => setState(() => _tabIndex = selection.first),
            ),
            const SizedBox(height: 16),
            if (_tabIndex == 0) _CashflowTab(state: state) else _InventoryTab(state: state, notifier: notifier),
          ],
        ),
      ),
    );
  }
}

class _CashflowTab extends StatelessWidget {
  final DashboardState state;

  const _CashflowTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cashflow = state.cashflow;

    if (state.isLoading && cashflow == null) {
      return const DashboardSkeleton(height: 140);
    }

    final incomeCount = cashflow?.countFor('INCOME') ?? 0;
    final expenseCount = cashflow?.countFor('EXPENSE') ?? 0;

    return Column(
      children: [
        _StatTile(
          icon: Icons.arrow_upward_rounded,
          iconColor: Colors.green.shade700,
          label: 'Thu (bán hàng)',
          value: CurrencyUtils.formatVND(cashflow?.income ?? 0),
          subtitle: '${CurrencyUtils.formatNumber(incomeCount)} giao dịch',
        ),
        const SizedBox(height: 10),
        _StatTile(
          icon: Icons.arrow_downward_rounded,
          iconColor: Colors.red.shade700,
          label: 'Chi (hoàn trả)',
          value: CurrencyUtils.formatVND(cashflow?.expense ?? 0),
          subtitle: '${CurrencyUtils.formatNumber(expenseCount)} giao dịch',
        ),
        const SizedBox(height: 10),
        _StatTile(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: theme.colorScheme.primary,
          label: 'Dòng tiền ròng',
          value: CurrencyUtils.formatVND(cashflow?.net ?? 0),
        ),
      ],
    );
  }
}

class _InventoryTab extends StatelessWidget {
  final DashboardState state;
  final DashboardViewModel notifier;

  const _InventoryTab({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventory = state.inventory;

    if (state.isLoading && inventory == null) {
      return const DashboardSkeleton(height: 260);
    }

    final lowStock = (inventory?.lowStock ?? const []).take(10).toList();

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
            _MiniStat(label: 'Giá trị tồn kho', value: CurrencyUtils.formatVND(inventory?.stockValue ?? 0)),
            _MiniStat(label: 'Tổng số lượng', value: CurrencyUtils.formatNumber(inventory?.totalUnits ?? 0)),
            _MiniStat(label: 'Số SKU', value: CurrencyUtils.formatNumber(inventory?.skuCount ?? 0)),
            _MiniStat(
              label: 'Hết hàng',
              value: CurrencyUtils.formatNumber(inventory?.outOfStock ?? 0),
              valueColor: Colors.red.shade700,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sản phẩm sắp hết hàng',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            DropdownButton<int>(
              value: state.lowStockThreshold,
              underline: const SizedBox.shrink(),
              isDense: true,
              onChanged: (value) {
                if (value != null) notifier.setLowStockThreshold(value);
              },
              items: lowStockThresholdOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text('Ngưỡng ≤ $t', style: theme.textTheme.bodySmall)))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (lowStock.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Không có sản phẩm sắp hết hàng',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: lowStock.asMap().entries.map((e) {
                final isLast = e.key == lowStock.length - 1;
                final item = e.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: isLast ? null : Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                            Text(item.sku, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _locationTypeLabels[item.locationType] ?? item.locationType,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyUtils.formatNumber(item.stock),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: item.stock <= 0 ? Colors.red.shade700 : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MiniStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
