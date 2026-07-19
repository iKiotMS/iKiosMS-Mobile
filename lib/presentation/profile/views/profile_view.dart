import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_token_provider.dart';
import '../../../core/push/push_service.dart';
import '../../../data/models/user_model.dart';
import '../../auth/viewmodels/user_profile_provider.dart';
import '../viewmodels/profile_view_model.dart';

/// The "Cá nhân" (Profile) tab. Shows the signed-in user's details, lets them
/// set the email used for Google sign-in, toggle push notifications, and log
/// out.
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool _pushEnabled = false;
  bool _pushBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final enabled = await ref.read(pushServiceProvider).isEnabled();
      if (mounted) setState(() => _pushEnabled = enabled);
    });
  }

  Future<void> _togglePush(bool value) async {
    setState(() => _pushBusy = true);
    final push = ref.read(pushServiceProvider);
    bool result = value;
    if (value) {
      result = await push.register();
      if (mounted && !result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa được cấp quyền thông báo.'),
          ),
        );
      }
    } else {
      await push.unregister();
      result = false;
    }
    if (mounted) {
      setState(() {
        _pushEnabled = result;
        _pushBusy = false;
      });
    }
  }

  Future<void> _logout() async {
    // Detach this device from push before dropping the session (needs the
    // token to still be valid), then clear tokens to route back to login.
    await ref.read(pushServiceProvider).unregister();
    await ref.read(authTokenProvider.notifier).clearTokens();
  }

  Future<void> _editEmail(UserModel user) async {
    final controller = TextEditingController(text: user.email);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _EditEmailDialog(controller: controller);
      },
    );
    controller.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        centerTitle: true,
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Không thể tải hồ sơ. Vui lòng thử lại.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Chưa đăng nhập'));
          }
          final initials = user.fullName
              .trim()
              .split(RegExp(r'\s+'))
              .where((p) => p.isNotEmpty)
              .map((p) => p[0])
              .take(2)
              .join()
              .toUpperCase();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(user.roleLabel),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Account info
              Text('Thông tin tài khoản',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone_android_rounded),
                      title: const Text('Số điện thoại'),
                      subtitle: Text(
                        user.phoneNumber.isEmpty ? '—' : user.phoneNumber,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email (đăng nhập Google)'),
                      subtitle: Text(
                        user.email.isEmpty
                            ? 'Chưa thiết lập — chạm để thêm'
                            : user.email,
                      ),
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                      onTap: () => _editEmail(user),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notifications
              Text('Thông báo',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Nhận thông báo đẩy'),
                  subtitle: const Text(
                    'Nhận thông báo về ca làm, đơn hàng, kho...',
                  ),
                  value: _pushEnabled,
                  onChanged: _pushBusy ? null : _togglePush,
                ),
              ),
              const SizedBox(height: 32),

              // Logout
              FilledButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Dialog for setting the login email. Owns its own busy state and returns
/// `true` via [Navigator.pop] when the save succeeds.
class _EditEmailDialog extends ConsumerStatefulWidget {
  const _EditEmailDialog({required this.controller});

  final TextEditingController controller;

  @override
  ConsumerState<_EditEmailDialog> createState() => _EditEmailDialogState();
}

class _EditEmailDialogState extends ConsumerState<_EditEmailDialog> {
  String? _error;

  Future<void> _save() async {
    final email = widget.controller.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) {
      setState(() => _error = 'Email không hợp lệ');
      return;
    }

    setState(() => _error = null);
    final ok =
        await ref.read(profileViewModelProvider.notifier).updateEmail(email);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error =
            ref.read(profileViewModelProvider).errorMessage ?? 'Lưu thất bại';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(profileViewModelProvider).isSaving;

    return AlertDialog(
      title: const Text('Email đăng nhập Google'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            enabled: !isSaving,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'ban@gmail.com',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Phải trùng với tài khoản Google bạn dùng để đăng nhập.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: isSaving ? null : _save,
          child: isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
