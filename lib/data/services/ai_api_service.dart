import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'ai_api_service.g.dart';

@riverpod
AiApiService aiApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return AiApiService(dio);
}

class AiApiService {
  final Dio _dio;

  AiApiService(this._dio);

  /// POST /ai/chat
  Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    String? conversationId,
  }) async {
    final Map<String, dynamic> requestData = {
      'message': message,
    };
    if (conversationId != null) {
      requestData['conversationId'] = conversationId;
    }
    final response = await _dio.post(
      ApiEndpoints.aiChat,
      data: requestData,
    );
    return response.data;
  }

  /// GET /ai/conversations
  Future<Map<String, dynamic>> listConversations() async {
    final response = await _dio.get(ApiEndpoints.aiConversations);
    return response.data;
  }

  /// GET /ai/conversations/:id
  Future<Map<String, dynamic>> getConversationDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.aiConversationDetail(id));
    return response.data;
  }

  /// DELETE /ai/conversations/:id
  Future<Map<String, dynamic>> deleteConversation(String id) async {
    final response = await _dio.delete(ApiEndpoints.deleteAiConversation(id));
    return response.data;
  }

  /// PUT /ai/conversations/:id
  Future<Map<String, dynamic>> renameConversation(
    String id,
    String title,
  ) async {
    final response = await _dio.put(
      ApiEndpoints.renameAiConversation(id),
      data: {'title': title},
    );
    return response.data;
  }
}
