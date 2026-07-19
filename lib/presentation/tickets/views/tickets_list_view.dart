import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../viewmodels/tickets_view_model.dart';
import 'create_ticket_dialog.dart';
import 'ticket_detail_view.dart';

class TicketsListView extends ConsumerWidget {
  const TicketsListView({super.key});

  static Future<void> navigate(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TicketsListView(),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm dd/MM/yyyy').format(dt);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, dynamic ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Xác nhận xóa'),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa phiếu phản ánh "${ticket.title}" (${ticket.ticketId})?\nHành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xóa vĩnh viễn'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(ticketsViewModelProvider.notifier).deleteTicket(ticket.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa phiếu phản ánh thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xóa phiếu phản ánh thất bại: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ticketsAsync = ref.watch(ticketsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phản ánh & Hỗ trợ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ticketsViewModelProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await CreateTicketDialog.show(context);
          if (res == true) {
            ref.read(ticketsViewModelProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Gửi phản ánh'),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Không thể tải danh sách phản ánh.',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.read(ticketsViewModelProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(ticketsViewModelProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.support_agent_rounded,
                          size: 64,
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có phản ánh nào',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'Gửi yêu cầu hỗ trợ kỹ thuật hoặc phản ánh vấn đề đến đội ngũ quản trị hệ thống.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final res = await CreateTicketDialog.show(context);
                            if (res == true) {
                              ref.read(ticketsViewModelProvider.notifier).refresh();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo phản ánh đầu tiên'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(ticketsViewModelProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              itemCount: tickets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = tickets[index];

                return Card(
                  elevation: 0.5,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => TicketDetailView.navigate(context, ticket),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ticket.ticketId.isNotEmpty ? ticket.ticketId : 'TCK',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ticket.priorityBackgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ticket.priorityLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ticket.priorityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ticket.statusBackgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ticket.statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ticket.statusColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(ticket.updatedAt ?? ticket.createdAt),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ticket.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (ticket.isClosed) ...[
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _confirmDelete(context, ref, ticket),
                                  borderRadius: BorderRadius.circular(20),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (ticket.messages.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${ticket.messages.length} tin nhắn',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
