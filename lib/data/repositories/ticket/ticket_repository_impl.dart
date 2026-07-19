import '../../models/ticket_model.dart';
import '../../services/ticket_api_service.dart';
import 'ticket_repository.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketApiService _apiService;

  TicketRepositoryImpl(this._apiService);

  @override
  Future<List<TicketModel>> getMyTickets() async {
    final list = await _apiService.listMyTickets();
    return list
        .map((json) => TicketModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String priority,
  }) async {
    final json = await _apiService.createTicket(
      title: title,
      description: description,
      priority: priority,
    );
    return TicketModel.fromJson(json);
  }

  @override
  Future<TicketModel> getTicketDetail(String id) async {
    final json = await _apiService.getTicketDetail(id);
    return TicketModel.fromJson(json);
  }

  @override
  Future<TicketModel> replyMyTicket(String id, String message) async {
    final json = await _apiService.replyMyTicket(id, message);
    return TicketModel.fromJson(json);
  }

  @override
  Future<void> deleteTicket(String id) async {
    await _apiService.deleteTicket(id);
  }
}
