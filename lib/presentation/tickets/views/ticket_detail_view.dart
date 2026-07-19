import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/ticket_model.dart';
import '../viewmodels/tickets_view_model.dart';

class TicketDetailView extends ConsumerStatefulWidget {
  final TicketModel initialTicket;

  const TicketDetailView({super.key, required this.initialTicket});

  static Future<void> navigate(BuildContext context, TicketModel ticket) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketDetailView(initialTicket: ticket),
      ),
    );
  }

  @override
  ConsumerState<TicketDetailView> createState() => _TicketDetailViewState();
}

class _TicketDetailViewState extends ConsumerState<TicketDetailView> {
  late TicketModel _ticket;
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.initialTicket;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final updated = await ref
          .read(ticketsViewModelProvider.notifier)
          .replyTicket(id: _ticket.id, message: text);

      if (updated != null && mounted) {
        setState(() {
          _ticket = updated;
          _replyController.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi phản hồi thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm dd/MM/yyyy').format(dt);
  }

  Future<void> _confirmDelete() async {
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
            'Bạn có chắc chắn muốn xóa phiếu phản ánh "${_ticket.title}" (${_ticket.ticketId})?\nHành động này không thể hoàn tác.',
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

    if (confirmed == true && mounted) {
      try {
        await ref.read(ticketsViewModelProvider.notifier).deleteTicket(_ticket.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa phiếu phản ánh thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ticketsState = ref.watch(ticketsViewModelProvider);

    // Keep ticket synced with latest state from viewmodel list if updated
    final latestTicket = ticketsState.valueOrNull
        ?.firstWhere((t) => t.id == _ticket.id, orElse: () => _ticket);
    if (latestTicket != null && latestTicket != _ticket) {
      _ticket = latestTicket;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_ticket.ticketId.isNotEmpty ? _ticket.ticketId : 'Chi tiết phản ánh'),
        actions: [
          if (_ticket.isClosed)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _confirmDelete,
              tooltip: 'Xóa phiếu phản ánh',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ticketsViewModelProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _ticket.priorityBackgroundColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ticket.priorityColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _ticket.priorityLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _ticket.priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _ticket.statusBackgroundColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _ticket.statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _ticket.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _ticket.statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(_ticket.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _ticket.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _ticket.description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Messages List / Chat Thread
          Expanded(
            child: _ticket.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mark_chat_read_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có phản hồi nào.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Đội ngũ quản trị viên sẽ hồi đáp yêu cầu của bạn sớm nhất.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _ticket.messages.length,
                    itemBuilder: (context, index) {
                      final msg = _ticket.messages[index];
                      final isAdmin = msg.isAdmin;

                      return Align(
                        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? theme.colorScheme.surfaceContainerHigh
                                : theme.colorScheme.primary,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isAdmin ? 0 : 12),
                              bottomRight: Radius.circular(isAdmin ? 12 : 0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isAdmin ? 'Hỗ trợ kỹ thuật' : 'Bạn',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(msg.createdAt),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isAdmin
                                          ? Colors.grey.shade600
                                          : theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isAdmin
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Reply Input
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _ticket.isClosed
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Yêu cầu hỗ trợ này đã được đóng.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            enabled: !_isSending,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Nhập thông tin hoặc câu hỏi phản hồi...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isSending ? null : _sendReply,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
