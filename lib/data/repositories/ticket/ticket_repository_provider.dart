import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/ticket_api_service.dart';
import 'ticket_repository.dart';
import 'ticket_repository_impl.dart';

part 'ticket_repository_provider.g.dart';

@riverpod
TicketRepository ticketRepository(Ref ref) {
  final apiService = ref.watch(ticketApiServiceProvider);
  return TicketRepositoryImpl(apiService);
}
