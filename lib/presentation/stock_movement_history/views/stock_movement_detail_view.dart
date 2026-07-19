import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../data/models/stock_movement_model.dart';
import '../shared/movement_labels.dart';
import '../viewmodels/stock_movement_detail_provider.dart';

/// Read-only detail for one stock movement — header, from/to (or
/// supplier→destination) info, order note, and the full line-items table
/// with product name/SKU (populated only on the detail endpoint).
///
/// Mirrors the web `movement-expanded-panel.tsx`'s read-only rendering.
class StockMovementDetailView extends ConsumerWidget {
  final String movementId;

  const StockMovementDetailView({super.key, required this.movementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(stockMovementDetailProvider(movementId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phiếu'), centerTitle: true),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 32, color: theme.colorScheme.error),
                const SizedBox(height: 8),
                Text('Không tải được chi tiết phiếu', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(stockMovementDetailProvider(movementId)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (movement) => _DetailBody(movement: movement),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final StockMovement movement;

  const _DetailBody({required this.movement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeConfig = movementTypeConfig(movement.movementType);
    final statusConfig = movementStatusConfig(movement.status);
    final code = movement.id.length >= 6 ? movement.id.substring(movement.id.length - 6).toUpperCase() : movement.id.toUpperCase();
    final isImport = movement.movementType == 'IMPORT';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _Badge(label: typeConfig.label, color: typeConfig.color),
            const SizedBox(width: 8),
            _Badge(label: statusConfig.label, color: statusConfig.color),
            const Spacer(),
            Text('#$code', style: theme.textTheme.labelMedium?.copyWith(fontFamily: 'monospace', color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isImport) ...[
                _InfoRow(icon: Icons.local_shipping_outlined, label: 'Nhà cung cấp', value: movement.supplierName ?? '—'),
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Nơi nhận',
                  value: '${movement.toLocationName ?? '—'} (${locationTypeLabels[movement.toLocationType] ?? movement.toLocationType})',
                ),
              ] else ...[
                _InfoRow(
                  icon: Icons.trip_origin,
                  label: 'Từ',
                  value: '${movement.fromLocationName ?? '—'} (${locationTypeLabels[movement.fromLocationType] ?? movement.fromLocationType ?? ''})',
                ),
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Đến',
                  value: '${movement.toLocationName ?? '—'} (${locationTypeLabels[movement.toLocationType] ?? movement.toLocationType})',
                ),
              ],
              _InfoRow(icon: Icons.person_outline_rounded, label: 'Người tạo', value: movement.requestedByName),
              _InfoRow(icon: Icons.event_outlined, label: 'Ngày tạo', value: DateFormat('dd/MM/yyyy HH:mm').format(movement.createdAt)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ghi chú đơn', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(
                (movement.note?.isNotEmpty ?? false) ? movement.note! : 'Không có ghi chú đơn',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Danh sách hàng hoá (${movement.totalItems})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...movement.details.map((line) => _LineItemTile(line: line)),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tổng giá trị đơn', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              CurrencyUtils.formatVND(movement.totalValue),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ],
    );
  }
}

class _LineItemTile extends StatelessWidget {
  final StockMovementLine line;

  const _LineItemTile({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line.productName ?? line.productItemId, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          if (line.sku != null) Text(line.sku!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _MiniField(label: 'SL yêu cầu', value: CurrencyUtils.formatNumber(line.quantity))),
              Expanded(child: _MiniField(label: 'SL thực nhận', value: CurrencyUtils.formatNumber(line.receivedQuantity))),
              Expanded(child: _MiniField(label: 'Giá nhập', value: CurrencyUtils.formatVND(line.importPrice))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thành tiền', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(CurrencyUtils.formatVND(line.lineTotal), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          if (line.note?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text('Ghi chú: ${line.note}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final String label;
  final String value;

  const _MiniField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 12)),
    );
  }
}
