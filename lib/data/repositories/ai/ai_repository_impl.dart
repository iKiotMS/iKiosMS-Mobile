import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/ai_chat_model.dart';
import '../../services/ai_api_service.dart';
import 'ai_repository.dart';

class AIRepositoryImpl implements AIRepository {
  final AiApiService _apiService;

  AIRepositoryImpl(this._apiService);

  @override
  Future<List<AIChatSession>> listConversations() async {
    try {
      final response = await _apiService.listConversations();
      final list = response['data'];
      if (list is List) {
        return list
            .map((item) => AIChatSession.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.message ??
            'Lỗi tải danh sách hội thoại',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<AIChatSession> getConversationDetail(String id) async {
    try {
      final response = await _apiService.getConversationDetail(id);
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return AIChatSession.fromJson(data);
      }
      throw const ApiException(message: 'Dữ liệu hội thoại không hợp lệ');
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.message ??
            'Lỗi tải chi tiết hội thoại',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    String? conversationId,
  }) async {
    try {
      final response = await _apiService.sendChatMessage(
        message,
        conversationId: conversationId,
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data; // Returns { reply, conversationId, title }
      }
      throw const ApiException(message: 'Dữ liệu phản hồi không hợp lệ');
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.message ??
            'Lỗi gửi tin nhắn',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    try {
      await _apiService.deleteConversation(id);
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.message ??
            'Lỗi xóa hội thoại',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<AIChatSession> renameConversation(String id, String title) async {
    try {
      final response = await _apiService.renameConversation(id, title);
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return AIChatSession.fromJson(data);
      }
      throw const ApiException(message: 'Dữ liệu phản hồi không hợp lệ');
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.message ??
            'Lỗi đổi tên hội thoại',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
