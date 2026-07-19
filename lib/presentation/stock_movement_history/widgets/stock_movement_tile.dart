import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../data/models/stock_movement_model.dart';
import '../shared/movement_labels.dart';

/// One row in the history list: type + status badges, code, route
/// (supplier→destination for IMPORT, from→to for EXPORT/RETURN), item/qty
/// counts, and created date. Tap to view full detail.
///
/// Mirrors the web `transfers-columns.tsx`/`imports-columns.tsx` fields,
/// minus product names (list endpoint doesn't populate them — matches web).
class StockMovementTile extends StatelessWidget {
  final StockMovement movement;
  final VoidCallback onTap;

  const StockMovementTile({super.key, required this.movement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeConfig = movementTypeConfig(movement.movementType);
    final statusConfig = movementStatusConfig(movement.status);
    final code = movement.id.length >= 6 ? movement.id.substring(movement.id.length - 6).toUpperCase() : movement.id.toUpperCase();

    final isImport = movement.movementType == 'IMPORT';
    final fromLabel = isImport
        ? (movement.supplierName ?? 'Nhà cung cấp')
        : '${movement.fromLocationName ?? '—'} (${locationTypeLabels[movement.fromLocationType] ?? movement.fromLocationType ?? ''})';
    final toLabel = '${movement.toLocationName ?? '—'} (${locationTypeLabels[movement.toLocationType] ?? movement.toLocationType})';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Badge(label: typeConfig.label, color: typeConfig.color),
                const SizedBox(width: 6),
                Text('#$code', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontFamily: 'monospace')),
                const Spacer(),
                _Badge(label: statusConfig.label, color: statusConfig.color),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.trip_origin, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(fromLabel, style: theme.textTheme.bodySmall)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(toLabel, style: theme.textTheme.bodySmall)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${movement.totalItems} mặt hàng · ${CurrencyUtils.formatNumber(movement.totalQuantity)} SP',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy').format(movement.createdAt),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
