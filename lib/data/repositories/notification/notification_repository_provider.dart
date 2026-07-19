import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/notification_api_service.dart';
import 'notification_repository.dart';
import 'notification_repository_impl.dart';

part 'notification_repository_provider.g.dart';

@riverpod
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepositoryImpl(ref.read(notificationApiServiceProvider));
}
