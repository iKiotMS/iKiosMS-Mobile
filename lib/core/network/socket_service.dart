import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';

class SocketService {
  io.Socket? _socket;
  final Set<String> _joinedRooms = {};

  void init() {
    if (_socket != null) return;

    final baseUrl = kBaseUrl;
    if (baseUrl.isEmpty) return;

    debugPrint('[SocketService] Initializing socket connection to: $baseUrl');

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket?.onConnect((_) {
      debugPrint('[SocketService] Connected. Socket ID: ${_socket?.id}');
      // Re-join rooms if socket reconnected
      for (final room in _joinedRooms) {
        _socket?.emit('join', room);
        debugPrint('[SocketService] Re-joined room: $room');
      }
    });

    _socket?.onDisconnect((reason) {
      debugPrint('[SocketService] Disconnected. Reason: $reason');
    });

    _socket?.onError((err) {
      debugPrint('[SocketService] Error: $err');
    });
  }

  /// Join a room (e.g. 'tenant:tenantId' or 'admin')
  void joinRoom(String room) {
    if (room.isEmpty) return;
    init();
    _joinedRooms.add(room);
    if (_socket?.connected == true) {
      _socket?.emit('join', room);
      debugPrint('[SocketService] Joined room: $room');
    }
  }

  /// Listen for 'ticket-update' events
  void onTicketUpdate(void Function(dynamic data) handler) {
    init();
    _socket?.off('ticket-update');
    _socket?.on('ticket-update', handler);
  }

  /// Stop listening for 'ticket-update' events
  void offTicketUpdate() {
    _socket?.off('ticket-update');
  }

  /// Listen for 'ticket-delete' events
  void onTicketDelete(void Function(dynamic data) handler) {
    init();
    _socket?.off('ticket-delete');
    _socket?.on('ticket-delete', handler);
  }

  /// Stop listening for 'ticket-delete' events
  void offTicketDelete() {
    _socket?.off('ticket-delete');
  }

  /// Disconnect and clean up
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _joinedRooms.clear();
  }
}
