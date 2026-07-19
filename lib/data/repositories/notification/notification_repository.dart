import '../../models/notification_model.dart';

abstract class NotificationRepository {
  /// One page of the caller's inbox plus the unread count.
  Future<NotificationInbox> getInbox({int page = 1, int limit = 20});

  /// Marks a single notification read.
  Future<void> markRead(String id);

  /// Marks every unread notification read.
  Future<void> markAllRead();
}
