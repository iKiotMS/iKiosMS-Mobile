import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/ai_chat_model.dart';
import '../../../data/repositories/ai/ai_repository_provider.dart';
import '../../../data/repositories/auth/auth_repository_provider.dart';

part 'ai_chat_view_model.g.dart';

class AIChatState {
  final List<AIChatSession> conversations;
  final String? activeConversationId;
  final List<AIChatMessage> messages;
  final bool isLoadingConversations;
  final bool isLoadingMessages;
  final bool isSending;
  final String? error;
  final bool isTenantOwner;
  final bool isLoadingProfile;

  AIChatState({
    this.conversations = const [],
    this.activeConversationId,
    this.messages = const [],
    this.isLoadingConversations = false,
    this.isLoadingMessages = false,
    this.isSending = false,
    this.error,
    this.isTenantOwner = false,
    this.isLoadingProfile = true,
  });

  AIChatState copyWith({
    List<AIChatSession>? conversations,
    String? Function()? activeConversationId,
    List<AIChatMessage>? messages,
    bool? isLoadingConversations,
    bool? isLoadingMessages,
    bool? isSending,
    String? error,
    bool? isTenantOwner,
    bool? isLoadingProfile,
  }) {
    return AIChatState(
      conversations: conversations ?? this.conversations,
      activeConversationId: activeConversationId != null
          ? activeConversationId()
          : this.activeConversationId,
      messages: messages ?? this.messages,
      isLoadingConversations:
          isLoadingConversations ?? this.isLoadingConversations,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
      isTenantOwner: isTenantOwner ?? this.isTenantOwner,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
    );
  }
}

@riverpod
class AIChatViewModel extends _$AIChatViewModel {
  @override
  AIChatState build() {
    // Automatically trigger initial load of profile and conversation list
    Future.microtask(() => initChat());
    return AIChatState();
  }

  Future<void> initChat() async {
    state = state.copyWith(isLoadingProfile: true, error: null);
    try {
      final profile = await ref.read(authRepositoryProvider).getProfile();
      final isOwner = profile.role == 'TENANT_OWNER';
      state = state.copyWith(isTenantOwner: isOwner, isLoadingProfile: false);
      if (isOwner) {
        await fetchConversations(autoSelectFirst: true);
      }
    } catch (e) {
      state = state.copyWith(isLoadingProfile: false, error: e.toString());
    }
  }

  Future<void> fetchConversations({
    String? selectId,
    bool autoSelectFirst = false,
  }) async {
    state = state.copyWith(isLoadingConversations: true, error: null);
    try {
      final conversations = await ref
          .read(aiRepositoryProvider)
          .listConversations();

      // Sort conversations by updatedAt descending (newest first)
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      String? activeId = state.activeConversationId;
      if (selectId != null) {
        activeId = selectId;
      } else if (autoSelectFirst &&
          conversations.isNotEmpty &&
          activeId == null) {
        activeId = conversations.first.id;
      }

      state = state.copyWith(
        conversations: conversations,
        activeConversationId: () => activeId,
        isLoadingConversations: false,
      );

      if (activeId != null) {
        await fetchActiveMessages(activeId);
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingConversations: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchActiveMessages(String id) async {
    state = state.copyWith(isLoadingMessages: true, error: null);
    try {
      final detail = await ref
          .read(aiRepositoryProvider)
          .getConversationDetail(id);
      state = state.copyWith(
        messages: detail.messages,
        isLoadingMessages: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMessages: false, error: e.toString());
    }
  }

  void selectConversation(String id) {
    if (state.activeConversationId == id) return;
    state = state.copyWith(activeConversationId: () => id);
    fetchActiveMessages(id);
  }

  void startNewSession() {
    state = state.copyWith(activeConversationId: () => null, messages: []);
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isSending) return;

    final userMsg = AIChatMessage(
      role: 'user',
      text: content,
      createdAt: DateTime.now(),
    );

    // Optimistically add user message
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isSending: true,
      error: null,
    );

    try {
      final activeId = state.activeConversationId;
      final response = await ref
          .read(aiRepositoryProvider)
          .sendChatMessage(content, conversationId: activeId);

      final modelMsg = AIChatMessage(
        role: 'model',
        text: response['reply']?.toString() ?? '',
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, modelMsg],
        isSending: false,
      );

      final newConvId = response['conversationId']?.toString();
      if (activeId == null && newConvId != null) {
        await fetchConversations(selectId: newConvId);
      } else {
        await fetchConversations(selectId: activeId);
      }
    } catch (e) {
      final defaultErrorReply =
          'Xin lỗi, tôi đang có chút xíu việc bận ngay lúc này. Hãy nhờ tôi vào một lúc sau nha.';
      final modelMsg = AIChatMessage(
        role: 'model',
        text: defaultErrorReply,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, modelMsg],
        isSending: false,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await ref.read(aiRepositoryProvider).deleteConversation(id);

      final updatedList = state.conversations.where((c) => c.id != id).toList();

      if (state.activeConversationId == id) {
        if (updatedList.isNotEmpty) {
          state = state.copyWith(
            conversations: updatedList,
            activeConversationId: () => updatedList.first.id,
          );
          await fetchActiveMessages(updatedList.first.id);
        } else {
          state = state.copyWith(
            conversations: [],
            activeConversationId: () => null,
            messages: [],
          );
        }
      } else {
        state = state.copyWith(conversations: updatedList);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> renameConversation(String id, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    try {
      await ref.read(aiRepositoryProvider).renameConversation(id, newTitle);

      final updatedList = state.conversations.map((c) {
        if (c.id == id) {
          return AIChatSession(
            id: c.id,
            title: newTitle,
            updatedAt: DateTime.now(),
            messages: c.messages,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(conversations: updatedList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
