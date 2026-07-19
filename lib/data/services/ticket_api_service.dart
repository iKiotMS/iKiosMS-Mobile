import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'ticket_api_service.g.dart';

@riverpod
TicketApiService ticketApiService(Ref ref) {
  return TicketApiService(ref.read(apiClientProvider));
}

/// Raw HTTP calls for tickets.
class TicketApiService {
  final Dio _dio;

  TicketApiService(this._dio);

  Future<List<dynamic>> listMyTickets() async {
    final response = await _dio.get(ApiEndpoints.myTickets);
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    return [];
  }

  Future<Map<String, dynamic>> createTicket({
    required String title,
    required String description,
    required String priority,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.tickets,
      data: {
        'title': title,
        'description': description,
        'priority': priority,
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    return data;
  }

  Future<Map<String, dynamic>> getTicketDetail(String id) async {
    final response = await _dio.get(ApiEndpoints.ticketDetail(id));
    final data = response.data as Map<String, dynamic>;
    if (data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    return data;
  }

  Future<Map<String, dynamic>> replyMyTicket(String id, String message) async {
    final response = await _dio.post(
      ApiEndpoints.replyTicket(id),
      data: {'message': message},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    return data;
  }

  Future<void> deleteTicket(String id) async {
    await _dio.delete(ApiEndpoints.ticketDetail(id));
  }
}
