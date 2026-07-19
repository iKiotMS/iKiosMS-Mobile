import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification/notification_repository_provider.dart';

part 'notifications_view_model.g.dart';

@riverpod
class NotificationsViewModel extends _$NotificationsViewModel {
  @override
  Future<NotificationInbox> build() {
    return ref.read(notificationRepositoryProvider).getInbox();
  }

  /// Re-fetch the inbox (pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).getInbox(),
    );
  }

  /// Marks one notification read, optimistically updating the list and badge.
  Future<void> markRead(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final target = current.items.where((n) => n.id == id);
    if (target.isEmpty || target.first.isRead) return; // already read / gone

    state = AsyncData(
      NotificationInbox(
        items: current.items
            .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
            .toList(),
        unreadCount:
            current.unreadCount > 0 ? current.unreadCount - 1 : 0,
      ),
    );

    try {
      await ref.read(notificationRepositoryProvider).markRead(id);
    } catch (_) {
      await refresh(); // revert to server truth on failure
    }
  }

  /// Marks every notification read.
  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null || current.unreadCount == 0) return;

    state = AsyncData(
      NotificationInbox(
        items: current.items.map((n) => n.copyWith(isRead: true)).toList(),
        unreadCount: 0,
      ),
    );

    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
    } catch (_) {
      await refresh();
    }
  }
}
