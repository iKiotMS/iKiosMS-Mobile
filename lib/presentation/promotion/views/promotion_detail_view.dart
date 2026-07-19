import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../data/models/promotion_model.dart';
import '../../auth/viewmodels/user_profile_provider.dart';
import '../shared/promotion_labels.dart';
import '../shared/promotion_permissions.dart';
import '../viewmodels/promotion_detail_provider.dart';
import '../viewmodels/promotion_form_view_model.dart';
import '../viewmodels/promotion_list_view_model.dart';
import '../viewmodels/promotion_logs_provider.dart';
import 'promotion_form_view.dart';

/// Detail for one promotion — discount/eligibility info followed by its
/// usage-log history ("Lịch sử sử dụng"), plus Edit/Deactivate actions for
/// TENANT_OWNER/BRANCH_MANAGER (see `promotion_permissions.dart`).
///
/// Mirrors the web `promotions-expanded-panel.tsx`'s rendering, minus tabs
/// (a single dedicated mobile screen can just scroll).
class PromotionDetailView extends ConsumerWidget {
  final String promotionId;

  const PromotionDetailView({super.key, required this.promotionId});

  Future<void> _deactivate(BuildContext context, WidgetRef ref, PromotionModel promotion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tắt khuyến mãi?'),
        content: const Text('Khuyến mãi sẽ ngừng áp dụng nhưng vẫn được lưu lại.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Tắt')),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await ref.read(promotionFormViewModelProvider.notifier).deactivate(promotion.id);
    if (!context.mounted) return;
    if (success) {
      ref.invalidate(promotionDetailProvider(promotion.id));
      ref.invalidate(promotionListViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tắt khuyến mãi')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tắt khuyến mãi thất bại')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(promotionDetailProvider(promotionId));
    final role = ref.watch(userProfileProvider).value?.role;
    final canManage = canManagePromotions(role);
    final promotion = detailAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết khuyến mãi'),
        centerTitle: true,
        actions: (canManage && promotion != null)
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Sửa',
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => PromotionFormView(initial: promotion)),
                    );
                    if (updated == true) {
                      ref.invalidate(promotionDetailProvider(promotionId));
                      ref.invalidate(promotionListViewModelProvider);
                    }
                  },
                ),
                if (promotion.displayStatus != 'INACTIVE')
                  IconButton(
                    icon: const Icon(Icons.block_outlined),
                    tooltip: 'Tắt',
                    onPressed: () => _deactivate(context, ref, promotion),
                  ),
              ]
            : null,
      ),
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
                Text('Không tải được chi tiết khuyến mãi', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(promotionDetailProvider(promotionId)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (promotion) => _DetailBody(promotion: promotion),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final PromotionModel promotion;

  const _DetailBody({required this.promotion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final logsAsync = ref.watch(promotionLogsProvider(promotion.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                promotion.promoName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            _Badge(label: promotion.statusLabel, color: promotion.statusColor),
          ],
        ),
        const SizedBox(height: 4),
        Text(promotion.branchScopeLabel, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(icon: Icons.percent_rounded, label: 'Loại giảm giá', value: discountTypeLabel(promotion.discountType)),
              _InfoRow(icon: Icons.local_offer_outlined, label: 'Mức giảm', value: promotion.discountLabel),
              if (promotion.maxDiscountAmount != null)
                _InfoRow(icon: Icons.arrow_upward_rounded, label: 'Giảm tối đa', value: CurrencyUtils.formatVND(promotion.maxDiscountAmount!)),
              _InfoRow(icon: Icons.shopping_cart_outlined, label: 'Đơn tối thiểu', value: CurrencyUtils.formatVND(promotion.minOrderValue)),
              _InfoRow(icon: Icons.category_outlined, label: 'Áp dụng', value: promotion.applicableRuleLabel),
              _InfoRow(icon: Icons.low_priority_outlined, label: 'Độ ưu tiên', value: '${promotion.priority}'),
              _InfoRow(icon: Icons.layers_outlined, label: 'Cộng dồn', value: promotion.stackable ? 'Có' : 'Không'),
              _InfoRow(
                icon: Icons.date_range_outlined,
                label: 'Thời gian',
                value: '${dateFormat.format(promotion.startDate)} - ${dateFormat.format(promotion.endDate)}',
              ),
              _InfoRow(
                icon: Icons.repeat_rounded,
                label: 'Giới hạn dùng',
                value: promotion.usageLimit != null ? '${promotion.usageLimit} lượt (đã dùng ${promotion.usedCount})' : 'Không giới hạn (đã dùng ${promotion.usedCount})',
              ),
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Giới hạn / khách',
                value: promotion.usageLimitPerCustomer != null ? '${promotion.usageLimitPerCustomer} lượt' : 'Không giới hạn',
              ),
            ],
          ),
        ),
        if (promotion.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mô tả', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(promotion.description!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Lịch sử sử dụng', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        logsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Không tải được lịch sử sử dụng', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Chưa có lượt sử dụng nào',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              );
            }
            return Column(
              children: logs.map((log) => _LogTile(log: log)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  final PromotionLogModel log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.paymentReference ?? (log.orderId ?? 'Không rõ hoá đơn'),
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '-${CurrencyUtils.formatVND(log.discountAmount)}',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
          ),
        ],
      ),
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
          SizedBox(width: 110, child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 12)),
    );
  }
}
