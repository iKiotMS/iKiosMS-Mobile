import '../../models/ai_chat_model.dart';

abstract class AIRepository {
  Future<List<AIChatSession>> listConversations();
  Future<AIChatSession> getConversationDetail(String id);
  Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    String? conversationId,
  });
  Future<void> deleteConversation(String id);
  Future<AIChatSession> renameConversation(String id, String title);
}
