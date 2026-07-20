import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../stock_adjustment/shared/movement_labels.dart';

/// One row in the "Nhập hàng" list: status badge, code, supplier, receiving
/// location, item count, total value, creator and created date.
///
/// Mirrors `stock_adjustment/widgets/adjustment_tile.dart`.
class ImportTile extends StatelessWidget {
  final StockMovementModel request;
  final VoidCallback onTap;

  const ImportTile({super.key, required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final code = request.id.length >= 6 ? request.id.substring(request.id.length - 6).toUpperCase() : request.id.toUpperCase();
    final destinationLabel = '${request.toLocationName} (${locationTypeLabels[request.toLocationType] ?? request.toLocationType})';
    final dateStr = request.createdAt != null ? DateFormat('dd/MM/yyyy').format(request.createdAt!) : '—';

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
                _Badge(label: request.statusLabel, color: request.statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập từ ${request.supplierName ?? 'nhà cung cấp'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(destinationLabel, style: theme.textTheme.bodySmall)),
              ],
            ),
            if (request.note?.isNotEmpty ?? false) ...[
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(child: Text(request.note!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${request.details.length} mặt hàng',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(request.totalValue),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Người tạo: ${request.requestedByName ?? '—'}',
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
