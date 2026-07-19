import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/stock_movement_model.dart';
import '../shared/movement_labels.dart';
import '../shared/adjustment_labels.dart';

/// One row in the "Điều chỉnh tồn kho" list: status badge, code, location,
/// item count, total quantity delta (colored ±), creator, and created date.
///
/// Mirrors the web `adjustments-columns.tsx` fields.
class AdjustmentTile extends StatelessWidget {
  final StockMovement adjustment;
  final VoidCallback onTap;

  const AdjustmentTile({super.key, required this.adjustment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusConfig = adjustmentStatusConfig(adjustment.status);
    final code = adjustment.id.length >= 6
        ? adjustment.id.substring(adjustment.id.length - 6).toUpperCase()
        : adjustment.id.toUpperCase();
    final locationLabel =
        '${adjustment.fromLocationName ?? '—'} (${locationTypeLabels[adjustment.fromLocationType] ?? adjustment.fromLocationType ?? ''})';
    final totalDelta = adjustment.details.fold<num>(0, (sum, d) => sum + (d.receivedQuantity - d.quantity));
    final deltaColor = totalDelta > 0
        ? Colors.green
        : totalDelta < 0
        ? Colors.red
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#$code',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontFamily: 'monospace'),
                ),
                const Spacer(),
                _Badge(label: statusConfig.label, color: statusConfig.color),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(locationLabel, style: theme.textTheme.bodySmall)),
              ],
            ),
            if (adjustment.note?.isNotEmpty ?? false) ...[
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(child: Text(adjustment.note!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${adjustment.totalItems} mặt hàng',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Text(
                  totalDelta > 0 ? '+$totalDelta' : '$totalDelta',
                  style: theme.textTheme.labelSmall?.copyWith(color: deltaColor, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy').format(adjustment.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Người tạo: ${adjustment.requestedByName}',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
