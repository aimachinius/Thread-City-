import 'dart:developer' as dev;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? socket;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void connectSocket({required String token}) {
    if (socket != null && socket!.connected) return;

    socket = IO.io(AppConfig.serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    socket!.connect();

    socket!.onConnect((_) {
      dev.log('✅ Connected to Socket.io server', name: 'SocketService');
    });

    socket!.onDisconnect((_) {
      dev.log('🛑 Disconnected from Socket.io server', name: 'SocketService');
    });

    socket!.onConnectError((err) => dev.log('⚠️ Socket Connect Error: $err', name: 'SocketService'));
    socket!.onError((err) => dev.log('⚠️ Socket Error: $err', name: 'SocketService'));
  }

  void disconnect() {
    socket?.disconnect();
  }

  // Xin vào phòng chat để nghe tin nhắn riêng
  void joinConversation(int conversationId) {
    socket?.emit('join_conversation', conversationId);
  }

  // Báo cho đối phương biết mình đang gõ
  void emitTyping(int conversationId) {
    socket?.emit('typing', {
      'conversationId': conversationId,
    });
  }

  void emitStopTyping(int conversationId) {
    socket?.emit('stop_typing', {
      'conversationId': conversationId,
    });
  }

  // Lắng nghe tin nhắn mới
  void onNewMessage(Function(dynamic) callback) {
    socket?.on('new_message', callback);
  }

  void onTyping(Function(dynamic) callback) {
    socket?.on('user_typing', callback);
  }

  void onStopTyping(Function(dynamic) callback) {
    socket?.on('user_stop_typing', callback);
  }

  void onRequestAccepted(Function(dynamic) callback) {
    socket?.on('request_accepted', callback);
  }

  void onMessageRequest(Function(dynamic) callback) {
    socket?.on('message_request', callback);
  }

  void onMessageDeleted(Function(dynamic) callback) {
    socket?.on('message_deleted', callback);
  }

  void onMessageStatus(Function(dynamic) callback) {
    socket?.on('message_status', callback);
  }

  void onMessagesRead(Function(dynamic) callback) {
    socket?.on('messages_read', callback);
  }

  void onUserStatus(Function(dynamic) callback) {
    socket?.on('user_status', callback);
  }
}
