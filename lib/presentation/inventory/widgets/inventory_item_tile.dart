import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../data/models/inventory_item_model.dart';
import '../viewmodels/inventory_dashboard_view_model.dart';

/// One product row: thumbnail, name/SKU, stock vs. threshold, and — subject
/// to [canEditMinStock]/[canRemove] independently (they map to two different
/// backend permissions; BRANCH_MANAGER has the former but not the latter) —
/// actions to edit the low-stock threshold or remove the item from this
/// location.
class InventoryItemTile extends ConsumerWidget {
  final InventoryItemModel item;
  final bool canEditMinStock;
  final bool canRemove;

  const InventoryItemTile({
    super.key,
    required this.item,
    required this.canEditMinStock,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: item.thumbnailUrl != null
                  ? Image.network(
                      item.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => _placeholderThumb(theme),
                    )
                  : _placeholderThumb(theme),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text(item.sku, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Tồn: ${CurrencyUtils.formatNumber(item.stock)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: item.stock <= 0
                            ? Colors.red.shade700
                            : (item.isLowStock ? Colors.orange.shade800 : null),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.minStock > 0 ? 'Ngưỡng: ${CurrencyUtils.formatNumber(item.minStock)}' : 'Không cảnh báo',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canEditMinStock || canRemove)
            Column(
              children: [
                if (canEditMinStock)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    tooltip: 'Sửa ngưỡng cảnh báo',
                    onPressed: () => _showEditThresholdDialog(context, ref),
                  ),
                if (canRemove)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline_rounded, size: 20, color: item.stock <= 0 ? Colors.red.shade700 : theme.disabledColor),
                    tooltip: item.stock <= 0 ? 'Xoá khỏi vị trí này' : 'Chỉ xoá được khi tồn kho = 0',
                    onPressed: item.stock <= 0 ? () => _showRemoveConfirmDialog(context, ref) : null,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _placeholderThumb(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.inventory_2_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
    );
  }

  Future<void> _showEditThresholdDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: item.minStock.toInt().toString());
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ngưỡng cảnh báo tồn kho thấp'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Ngưỡng (0 = tắt cảnh báo)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Huỷ')),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.of(dialogContext).pop(value != null && value >= 0 ? value : null);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) return;
    final error = await ref.read(inventoryDashboardViewModelProvider.notifier).updateMinStock(item.id, result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Đã cập nhật ngưỡng cảnh báo')),
    );
  }

  Future<void> _showRemoveConfirmDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xoá khỏi vị trí này?'),
        content: Text('"${item.productName}" sẽ không còn được theo dõi tồn kho tại vị trí này.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final error = await ref.read(inventoryDashboardViewModelProvider.notifier).removeFromLocation(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Đã xoá khỏi vị trí này')),
    );
  }
}
