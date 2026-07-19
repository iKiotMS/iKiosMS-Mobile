import '../../models/ticket_model.dart';

abstract class TicketRepository {
  /// Fetch list of tickets created by current user/tenant.
  Future<List<TicketModel>> getMyTickets();

  /// Create a new ticket.
  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String priority,
  });

  /// Fetch single ticket detail.
  Future<TicketModel> getTicketDetail(String id);

  /// Reply to an existing ticket.
  Future<TicketModel> replyMyTicket(String id, String message);

  /// Delete a ticket.
  Future<void> deleteTicket(String id);
}
