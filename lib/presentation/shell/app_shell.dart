import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai_chat/views/ai_chat_view.dart';
import '../auth/viewmodels/user_profile_provider.dart';
import '../../core/auth/auth_token_provider.dart';
import '../../core/push/push_service.dart';
import '../profile/views/profile_view.dart';
import '../work/views/work_view.dart';
import 'tab_placeholders.dart';

/// The root shell of the app — provides a bottom navigation bar
/// with role-based dynamic tabs.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Once the user reaches the shell they're authenticated — register this
    // device for push (asks permission on Android 13+/iOS the first time).
    // Fire-and-forget; failures are swallowed inside PushService.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final push = ref.read(pushServiceProvider);
      push.register();
      push.initForeground();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return profileState.when(
      data: (profile) {
        final isTenant = profile?.role == 'TENANT_OWNER';

        final screens = [
          const HomeView(),
          const WorkView(),
          const NotificationsView(),
          if (isTenant) const AIChatView(),
          const ProfileView(),
        ];

        // Ensure selectedIndex doesn't go out of bounds if tabs count changes dynamically
        if (_selectedIndex >= screens.length) {
          _selectedIndex = 0;
        }

        final destinations = [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Công việc',
          ),
          const NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Thông báo',
          ),
          if (isTenant)
            const NavigationDestination(
              icon: Icon(Icons.assistant_outlined),
              selectedIcon: Icon(Icons.assistant_rounded),
              label: 'AI',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: destinations,
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không thể tải dữ liệu phân quyền',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Có lỗi kết nối mạng xảy ra. Vui lòng thử lại.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(userProfileProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authTokenProvider.notifier).clearTokens();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
