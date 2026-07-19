import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'notification_api_service.g.dart';

@riverpod
NotificationApiService notificationApiService(Ref ref) {
  return NotificationApiService(ref.read(apiClientProvider));
}

/// Raw HTTP for the in-app notification inbox. No logic — returns raw JSON.
class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  Future<Map<String, dynamic>> getInbox({int page = 1, int limit = 20}) async {
    final response =
        await _dio.get(ApiEndpoints.notifications(page: page, limit: limit));
    return response.data as Map<String, dynamic>;
  }

  Future<void> markRead(String id) async {
    await _dio.patch(ApiEndpoints.markNotificationRead(id));
  }

  Future<void> markAllRead() async {
    await _dio.patch(ApiEndpoints.markAllNotificationsRead);
  }
}
