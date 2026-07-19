import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'socket_service.dart';

part 'socket_service_provider.g.dart';

@riverpod
SocketService socketService(Ref ref) {
  final service = SocketService();
  ref.onDispose(() {
    service.disconnect();
  });
  return service;
}
