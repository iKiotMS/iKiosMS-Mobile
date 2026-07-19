import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/notification_model.dart';
import '../../services/notification_api_service.dart';
import 'notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationApiService _apiService;

  NotificationRepositoryImpl(this._apiService);

  @override
  Future<NotificationInbox> getInbox({int page = 1, int limit = 20}) async {
    try {
      final data = await _apiService.getInbox(page: page, limit: limit);
      final rawItems = (data['data'] as List<dynamic>?) ?? const [];
      final items = rawItems
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final unreadCount = (data['unreadCount'] as num?)?.toInt() ?? 0;
      return NotificationInbox(items: items, unreadCount: unreadCount);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ?? 'Lỗi kết nối máy chủ.';
      throw ApiException(message: message, statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _apiService.markRead(id);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ?? 'Lỗi kết nối máy chủ.';
      throw ApiException(message: message, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _apiService.markAllRead();
    } on DioException catch (e) {
      final message =
          e.response?.data?['message']?.toString() ?? 'Lỗi kết nối máy chủ.';
      throw ApiException(message: message, statusCode: e.response?.statusCode);
    }
  }
}
