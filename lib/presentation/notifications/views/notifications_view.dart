import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/notification_model.dart';
import '../viewmodels/notifications_view_model.dart';

/// The "Thông báo" tab — the user's in-app notification inbox.
class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsViewModelProvider);
    final vm = ref.read(notificationsViewModelProvider.notifier);
    final unread = state.valueOrNull?.unreadCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        centerTitle: true,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: vm.markAllRead,
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(onRetry: vm.refresh),
        data: (inbox) {
          if (inbox.items.isEmpty) {
            return _EmptyState(onRefresh: vm.refresh);
          }
          return RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView.separated(
              itemCount: inbox.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = inbox.items[index];
                return _NotificationTile(
                  item: item,
                  onTap: () => vm.markRead(item.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !item.isRead;

    return ListTile(
      onTap: onTap,
      tileColor:
          unread ? theme.colorScheme.primary.withValues(alpha: 0.05) : null,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: Icon(_iconFor(item.type), size: 20),
      ),
      title: Text(
        item.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: unread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(item.description),
          const SizedBox(height: 4),
          Text(
            _timeAgo(item.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: unread
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      isThreeLine: true,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Wrap in a scrollable so pull-to-refresh still works when empty.
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Icon(
            Icons.notifications_none_rounded,
            size: 72,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Chưa có thông báo nào',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Không thể tải thông báo',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pick an icon from the notification type family.
IconData _iconFor(String type) {
  if (type.startsWith('LEAVE_REQUEST')) return Icons.event_busy_rounded;
  if (type.startsWith('STOCK_MOVEMENT')) return Icons.swap_horiz_rounded;
  if (type.startsWith('INVENTORY')) return Icons.inventory_2_outlined;
  if (type.startsWith('ORDER')) return Icons.receipt_long_rounded;
  if (type.startsWith('SUBSCRIPTION')) return Icons.workspace_premium_outlined;
  if (type.startsWith('SCHEDULE')) return Icons.calendar_month_rounded;
  if (type.startsWith('PAYSLIP')) return Icons.payments_outlined;
  if (type.startsWith('STAFF')) return Icons.badge_outlined;
  if (type.startsWith('TICKET')) return Icons.support_agent_rounded;
  return Icons.notifications_rounded;
}

/// Short Vietnamese "time ago" label.
String _timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}
