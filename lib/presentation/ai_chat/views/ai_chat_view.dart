// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/ai_chat_model.dart';
import '../viewmodels/ai_chat_view_model.dart';

class AIChatView extends ConsumerStatefulWidget {
  const AIChatView({super.key});

  @override
  ConsumerState<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends ConsumerState<AIChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  int? _editingIndex;
  final TextEditingController _editController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref.read(aIChatViewModelProvider.notifier).sendMessage(text);
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép tin nhắn vào bộ nhớ tạm.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showUserMessageOptions(int index, String text) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Sao chép tin nhắn'),
                onTap: () {
                  Navigator.of(context).pop();
                  _copyToClipboard(text);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Chỉnh sửa tin nhắn'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _editingIndex = index;
                    _editController.text = text;
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(String id, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đổi tên hội thoại'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nhập tên cuộc hội thoại mới...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  ref.read(aIChatViewModelProvider.notifier).renameConversation(id, newTitle);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa hội thoại?'),
          content: const Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện này không? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(aIChatViewModelProvider.notifier).deleteConversation(id);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aIChatViewModelProvider);
    final theme = Theme.of(context);

    // Listen to changes to scroll to bottom only when new messages are added or sending state starts
    ref.listen<AIChatState>(aIChatViewModelProvider, (previous, next) {
      if (previous != null) {
        if (next.messages.length > previous.messages.length ||
            (next.isSending && !previous.isSending)) {
          _scrollToBottom();
        }
      }
    });

    // 1. Loading Profile / User Verification state
    if (state.isLoadingProfile) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang kiểm tra quyền truy cập...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Access Denied Screen (Non-TENANT_OWNER)
    if (!state.isTenantOwner) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trợ lý AI'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 80,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Quyền truy cập bị từ chối',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tính năng Trợ lý AI (AI Chat Assistant) yêu cầu quyền truy cập của Chủ cửa hàng (Role: TENANT_OWNER) để có thể đọc các báo cáo doanh thu và thông tin kinh doanh nhạy cảm. Tài khoản của bạn hiện tại không có quyền này.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Fully authorized Chat Assistant UI
    final activeSession = state.conversations.firstWhere(
      (c) => c.id == state.activeConversationId,
      orElse: () => AIChatSession(id: '', title: '', updatedAt: DateTime.now(), messages: const []),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.activeConversationId != null && activeSession.id.isNotEmpty
              ? activeSession.title
              : 'Trợ lý AI',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: () {
              ref.read(aIChatViewModelProvider.notifier).startNewSession();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã bắt đầu phiên trò chuyện mới.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: 'Lịch sử trò chuyện',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lịch sử chat',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(aIChatViewModelProvider.notifier).startNewSession();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Hội thoại mới'),
                ),
              ),
              Expanded(
                child: state.isLoadingConversations
                    ? const Center(child: CircularProgressIndicator())
                    : state.conversations.isEmpty
                        ? const Center(
                            child: Text(
                              'Không có lịch sử trò chuyện',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.conversations.length,
                            itemBuilder: (context, index) {
                              final session = state.conversations[index];
                              final isActive = session.id == state.activeConversationId;
                              return ListTile(
                                dense: true,
                                selected: isActive,
                                leading: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: isActive ? theme.colorScheme.primary : Colors.grey,
                                ),
                                title: Text(
                                  session.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('dd/MM HH:mm').format(session.updatedAt),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                                  onSelected: (value) {
                                    if (value == 'rename') {
                                      _showRenameDialog(session.id, session.title);
                                    } else if (value == 'delete') {
                                      _showDeleteDialog(session.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'rename',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Đổi tên'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Xóa', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  ref.read(aIChatViewModelProvider.notifier).selectConversation(session.id);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _buildWelcomeScreen(theme)
                : _buildMessageList(state, theme),
          ),
          if (state.isSending) _buildTypingIndicator(theme),
          _buildInputBar(state, theme),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen(ThemeData theme) {
    final suggestions = [
      {
        'title': 'Thống kê doanh thu',
        'desc': 'Báo cáo doanh số và đơn hàng hôm nay',
        'prompt': 'Thống kê tình hình doanh thu và số đơn hàng của cửa hàng ngày hôm nay.',
        'icon': Icons.analytics_outlined,
        'color': Colors.amber,
      },
      {
        'title': 'Xu hướng thị trường',
        'desc': 'Hỏi AI xu hướng hot trend',
        'prompt': 'Sản phẩm nào đang là xu hướng bán chạy trên thị trường hiện nay?',
        'icon': Icons.trending_up_rounded,
        'color': Colors.teal,
      },
      {
        'title': 'Đơn hàng gần đây',
        'desc': 'Liệt kê các đơn hàng mới nhất',
        'prompt': 'Liệt kê danh sách các đơn hàng mới nhất của tôi.',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.blue,
      },
      {
        'title': 'Danh sách sản phẩm',
        'desc': 'Tìm các sản phẩm đang có',
        'prompt': 'Liệt kê các sản phẩm có trong danh mục của cửa hàng.',
        'icon': Icons.inventory_2_outlined,
        'color': Colors.purple,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.spa_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Xin chào! Tôi có thể giúp gì cho bạn hôm nay?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tôi là trợ lý AI của cửa hàng, được kết nối trực tiếp với dữ liệu doanh thu, sản phẩm và ca làm việc của bạn. Hãy chọn một câu hỏi gợi ý bên dưới hoặc tự nhập câu hỏi.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final sug = suggestions[index];
              final iconColor = sug['color'] as Color;
              return InkWell(
                onTap: () {
                  ref.read(aIChatViewModelProvider.notifier).sendMessage(sug['prompt'] as String);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          sug['icon'] as IconData,
                          size: 20,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sug['title'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sug['desc'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(AIChatState state, ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isUser = message.role == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.spa_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (isUser && _editingIndex == index) ...[
                        Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.primary),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextField(
                                controller: _editController,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: 'Chỉnh sửa tin nhắn...',
                                ),
                                style: const TextStyle(fontSize: 14.0),
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _editingIndex = null;
                                      });
                                    },
                                    child: const Text('Hủy bỏ'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: () {
                                      final text = _editController.text.trim();
                                      if (text.isNotEmpty) {
                                        ref.read(aIChatViewModelProvider.notifier).sendMessage(text);
                                      }
                                      setState(() {
                                        _editingIndex = null;
                                      });
                                    },
                                    child: const Text('Gửi'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        GestureDetector(
                          onLongPress: isUser
                              ? () => _showUserMessageOptions(index, message.text)
                              : () => _copyToClipboard(message.text),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                bottomLeft: const Radius.circular(16),
                                topRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                                bottomRight: isUser ? const Radius.circular(16) : const Radius.circular(4),
                              ),
                            ),
                            child: isUser
                                ? Text(
                                    message.text,
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontSize: 14.0,
                                      height: 1.4,
                                    ),
                                  )
                                : MarkdownBody(
                                    data: message.text,
                                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                                      p: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 14.0,
                                        height: 1.4,
                                      ),
                                      listBullet: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                                fontSize: 9.0,
                              ),
                            ),
                            if (!isUser) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _copyToClipboard(message.text),
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.outlineVariant,
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.spa_outlined,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI đang suy nghĩ',
                  style: TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(AIChatState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: const InputDecoration(
                    hintText: 'Hỏi trợ lý AI về sản phẩm, doanh thu...',
                    hintStyle: TextStyle(fontSize: 13.0, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Material(
              color: state.isSending ? Colors.grey : theme.colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 1,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, size: 20.0),
                color: theme.colorScheme.onPrimary,
                onPressed: state.isSending ? null : _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
