import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/stock_movement_model.dart';
import '../../auth/viewmodels/user_profile_provider.dart';
import '../../stock_movement_history/shared/movement_labels.dart' show locationTypeLabels;
import '../shared/adjustment_labels.dart';
import '../shared/adjustment_permissions.dart';
import '../viewmodels/adjustment_detail_view_model.dart';

/// Detail of one ADJUST request: header, location, note, line items (system
/// stock vs counted quantity vs diff), and — only for an authorized user on
/// a PENDING request — Approve/Cancel actions.
///
/// Mirrors the web `adjustments-expanded-panel.tsx`'s read view plus its
/// approve/cancel actions; editing line items before approval (the web
/// panel's third action) is not implemented here — cancel and recreate the
/// request instead.
class AdjustmentDetailView extends ConsumerWidget {
  final String adjustmentId;

  const AdjustmentDetailView({super.key, required this.adjustmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(adjustmentDetailViewModelProvider(adjustmentId));
    final notifier = ref.read(adjustmentDetailViewModelProvider(adjustmentId).notifier);
    final profile = ref.watch(userProfileProvider).value;

    final adjustment = state.adjustment;
    final canAct = adjustment != null &&
        canActOnAdjustment(
          role: profile?.role,
          userBranchId: profile?.branchId,
          userWarehouseId: profile?.warehouseId,
          adjustment: adjustment,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết điều chỉnh'), centerTitle: true),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adjustment == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 32, color: theme.colorScheme.error),
                        const SizedBox(height: 8),
                        Text(state.errorMessage ?? 'Không tải được chi tiết phiếu', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: notifier.refetch, child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                )
              : _DetailBody(adjustment: adjustment, errorMessage: state.errorMessage),
      bottomNavigationBar: (canAct && !state.isLoading)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isProcessing ? null : () => _confirmCancel(context, ref, notifier),
                        style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                        child: const Text('Huỷ phiếu'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: state.isProcessing ? null : () => _confirmApprove(context, ref, notifier),
                        child: state.isProcessing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Duyệt'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _confirmApprove(BuildContext context, WidgetRef ref, AdjustmentDetailViewModel notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Duyệt phiếu điều chỉnh?'),
        content: const Text('Tồn kho sẽ được cập nhật ngay theo số lượng thực tế đã nhập. Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Duyệt')),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await notifier.approve();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Đã duyệt điều chỉnh, tồn kho đã được cập nhật' : 'Duyệt phiếu điều chỉnh thất bại')),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref, AdjustmentDetailViewModel notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Huỷ phiếu điều chỉnh?'),
        content: const Text('Phiếu sẽ chuyển sang trạng thái đã huỷ và không thể duyệt lại.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Không')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Huỷ phiếu')),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await notifier.cancel();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Đã huỷ phiếu điều chỉnh' : 'Huỷ phiếu điều chỉnh thất bại')),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final StockMovement adjustment;
  final String? errorMessage;

  const _DetailBody({required this.adjustment, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusConfig = adjustmentStatusConfig(adjustment.status);
    final code = adjustment.id.length >= 6 ? adjustment.id.substring(adjustment.id.length - 6).toUpperCase() : adjustment.id.toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (errorMessage != null) ...[
          _ErrorBanner(message: errorMessage!),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
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
              _InfoRow(
                icon: Icons.place_outlined,
                label: 'Vị trí',
                value: '${adjustment.fromLocationName ?? '—'} (${locationTypeLabels[adjustment.fromLocationType] ?? adjustment.fromLocationType ?? ''})',
              ),
              _InfoRow(icon: Icons.person_outline_rounded, label: 'Người tạo', value: adjustment.requestedByName),
              _InfoRow(icon: Icons.event_outlined, label: 'Ngày tạo', value: DateFormat('dd/MM/yyyy HH:mm').format(adjustment.createdAt)),
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
              Text('Lý do điều chỉnh', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text((adjustment.note?.isNotEmpty ?? false) ? adjustment.note! : 'Không có ghi chú', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Danh sách hàng hoá (${adjustment.totalItems})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...adjustment.details.map((line) => _LineItemTile(line: line)),
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
    final diff = line.receivedQuantity - line.quantity;
    final diffColor = diff > 0
        ? Colors.green
        : diff < 0
        ? Colors.red
        : theme.colorScheme.onSurfaceVariant;

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
              Expanded(child: _MiniField(label: 'Tồn hệ thống', value: '${line.quantity}')),
              Expanded(child: _MiniField(label: 'Tồn thực tế', value: '${line.receivedQuantity}')),
              Expanded(child: _MiniField(label: 'Chênh lệch', value: diff > 0 ? '+$diff' : '$diff', valueColor: diffColor)),
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
  final Color? valueColor;

  const _MiniField({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: valueColor)),
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
