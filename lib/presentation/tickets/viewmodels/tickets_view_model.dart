import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/socket_service_provider.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/ticket/ticket_repository_provider.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'tickets_view_model.g.dart';

@riverpod
class TicketsViewModel extends _$TicketsViewModel {
  @override
  Future<List<TicketModel>> build() async {
    // Setup Socket.IO real-time connection
    _initSocket();

    return ref.read(ticketRepositoryProvider).getMyTickets();
  }

  void _initSocket() {
    final socketService = ref.read(socketServiceProvider);

    // Join room when user profile resolves
    ref.listen<AsyncValue<UserModel?>>(userProfileProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user?.tenantId != null && user!.tenantId!.isNotEmpty) {
        socketService.joinRoom('tenant:${user.tenantId}');
      }
    }, fireImmediately: true);

    // Also check if user profile is already available
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user?.tenantId != null && user!.tenantId!.isNotEmpty) {
      socketService.joinRoom('tenant:${user.tenantId}');
    }

    // Register real-time ticket update & delete handlers
    socketService.onTicketUpdate(_handleSocketUpdate);
    socketService.onTicketDelete(_handleSocketDelete);

    // Cleanup listeners on dispose
    ref.onDispose(() {
      socketService.offTicketUpdate();
      socketService.offTicketDelete();
    });
  }

  void _handleSocketUpdate(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final updatedTicket = TicketModel.fromJson(data);
        debugPrint('[TicketsViewModel] Real-time ticket-update received: ${updatedTicket.ticketId}');

        final currentList = state.valueOrNull ?? [];
        final index = currentList.indexWhere((t) => t.id == updatedTicket.id);

        List<TicketModel> newList;
        if (index != -1) {
          newList = List.from(currentList);
          newList[index] = updatedTicket;
        } else {
          newList = [updatedTicket, ...currentList];
        }

        state = AsyncData(newList);
      }
    } catch (e) {
      debugPrint('[TicketsViewModel] Error handling ticket-update socket event: $e');
    }
  }

  void _handleSocketDelete(dynamic data) {
    try {
      if (data is Map<String, dynamic> && data['_id'] != null) {
        final deletedId = data['_id'].toString();
        debugPrint('[TicketsViewModel] Real-time ticket-delete received: $deletedId');

        final currentList = state.valueOrNull ?? [];
        final newList = currentList.where((t) => t.id != deletedId).toList();
        state = AsyncData(newList);
      }
    } catch (e) {
      debugPrint('[TicketsViewModel] Error handling ticket-delete socket event: $e');
    }
  }

  /// Re-fetch the tickets list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ticketRepositoryProvider).getMyTickets(),
    );
  }

  /// Create a new support ticket.
  Future<TicketModel?> createTicket({
    required String title,
    required String description,
    required String priority,
  }) async {
    try {
      final newTicket = await ref.read(ticketRepositoryProvider).createTicket(
            title: title,
            description: description,
            priority: priority,
          );

      final currentList = state.valueOrNull ?? [];
      final index = currentList.indexWhere((t) => t.id == newTicket.id);
      if (index == -1) {
        state = AsyncData([newTicket, ...currentList]);
      }
      return newTicket;
    } catch (e) {
      rethrow;
    }
  }

  /// Reply to an existing ticket.
  Future<TicketModel?> replyTicket({
    required String id,
    required String message,
  }) async {
    try {
      final updatedTicket =
          await ref.read(ticketRepositoryProvider).replyMyTicket(id, message);

      final currentList = state.valueOrNull ?? [];
      final updatedList =
          currentList.map((t) => t.id == id ? updatedTicket : t).toList();
      state = AsyncData(updatedList);
      return updatedTicket;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a ticket.
  Future<void> deleteTicket(String id) async {
    try {
      await ref.read(ticketRepositoryProvider).deleteTicket(id);
      final currentList = state.valueOrNull ?? [];
      final newList = currentList.where((t) => t.id != id).toList();
      state = AsyncData(newList);
    } catch (e) {
      rethrow;
    }
  }
}
