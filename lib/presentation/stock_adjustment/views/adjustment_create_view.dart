import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/movement_labels.dart' show locationTypeLabels;
import '../viewmodels/adjustment_create_view_model.dart';
import '../widgets/product_picker_sheet.dart';

/// "Tạo điều chỉnh tồn kho" — pick a location (auto for BRANCH_MANAGER/
/// WAREHOUSE_MANAGER, a picker for TENANT_OWNER), add products with a
/// counted quantity, and submit as a PENDING adjustment request.
///
/// Mirrors the web `adjustments-create-dialog.tsx`'s fields, minus the
/// server-populated system-stock refresh (this app snapshots stock from the
/// product picker at add-time — same tradeoff the backend itself accepts by
/// re-deriving `quantity` from live `Inventory.stock` at submit time).
class AdjustmentCreateView extends ConsumerWidget {
  const AdjustmentCreateView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(adjustmentCreateViewModelProvider);
    final notifier = ref.read(adjustmentCreateViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo điều chỉnh tồn kho'), centerTitle: true),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                if (state.errorMessage != null) ...[
                  _ErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 12),
                ],
                _LocationSection(state: state, notifier: notifier),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Sản phẩm', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: state.hasLocation
                          ? () async {
                              final item = await ProductPickerSheet.show(
                                context,
                                locationId: state.locationId!,
                                locationType: state.locationType!,
                              );
                              if (item != null) notifier.addOrUpdateProduct(item);
                            }
                          : null,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Thêm sản phẩm'),
                    ),
                  ],
                ),
                if (state.lines.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      state.hasLocation ? 'Chưa có sản phẩm nào được thêm' : 'Chọn vị trí trước khi thêm sản phẩm',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  ...state.lines.map(
                    (line) => _DraftLineCard(
                      key: ValueKey(line.productItemId),
                      line: line,
                      onQuantityChanged: (value) => notifier.updateCountedQuantity(line.productItemId, value),
                      onNoteChanged: (value) => notifier.updateLineNote(line.productItemId, value),
                      onRemove: () => notifier.removeLine(line.productItemId),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Lý do điều chỉnh (tuỳ chọn)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: state.note,
                  maxLines: 3,
                  onChanged: notifier.setNote,
                  decoration: const InputDecoration(
                    hintText: 'VD: Kiểm kê định kỳ cuối tháng',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: state.canSubmit
                ? () async {
                    final id = await notifier.submit();
                    if (!context.mounted) return;
                    if (id != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tạo phiếu điều chỉnh thành công, đang chờ duyệt')),
                      );
                      Navigator.of(context).pop(true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ref.read(adjustmentCreateViewModelProvider).errorMessage ?? 'Tạo phiếu thất bại')),
                      );
                    }
                  }
                : null,
            child: state.isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Tạo phiếu điều chỉnh'),
          ),
        ),
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final AdjustmentCreateState state;
  final AdjustmentCreateViewModel notifier;

  const _LocationSection({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!state.requiresLocationPicker) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.place_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(state.locationLabel ?? '—', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: state.locationId,
      decoration: const InputDecoration(
        labelText: 'Chi nhánh / Kho',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final option in state.locationOptions)
          DropdownMenuItem(
            value: option.id,
            child: Text('${option.name} (${locationTypeLabels[option.type] ?? option.type})'),
          ),
      ],
      onChanged: (id) {
        if (id == null) return;
        final option = state.locationOptions.firstWhere((o) => o.id == id);
        notifier.selectLocation(option);
      },
    );
  }
}

class _DraftLineCard extends StatelessWidget {
  final AdjustmentDraftLine line;
  final ValueChanged<num> onQuantityChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onRemove;

  const _DraftLineCard({
    super.key,
    required this.line,
    required this.onQuantityChanged,
    required this.onNoteChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = line.diff;
    final diffColor = diff > 0
        ? Colors.green
        : diff < 0
        ? Colors.red
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(top: 8),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.productName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (line.sku != null)
                      Text(line.sku!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ReadOnlyField(label: 'Tồn hệ thống', value: '${line.systemStock}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey('${line.productItemId}-${line.countedQuantity}'),
                  initialValue: '${line.countedQuantity}',
                  keyboardType: const TextInputType.numberWithOptions(),
                  decoration: const InputDecoration(labelText: 'Tồn thực tế', isDense: true, border: OutlineInputBorder()),
                  onChanged: (value) => onQuantityChanged(num.tryParse(value) ?? line.systemStock),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReadOnlyField(
                  label: 'Chênh lệch',
                  value: diff > 0 ? '+$diff' : '$diff',
                  valueColor: diffColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: line.note,
            decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)', isDense: true, border: OutlineInputBorder()),
            onChanged: onNoteChanged,
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReadOnlyField({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
        ],
      ),
    );
  }
}
