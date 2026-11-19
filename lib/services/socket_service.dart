import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? socket;
  String? _currentToken;
  int? _activeConversationId;
  final Map<String, List<Function(dynamic)>> _listeners = {};

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  bool get isConnected => socket != null && socket!.connected;
  int? get activeConversationId => _activeConversationId;

  Future<void> ensureConnected() async {
    if (isConnected) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          connectSocket(token: token);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SocketService] ensureConnected error: $e');
    }
  }

  void connectSocket({required String token}) {
    if (token.isEmpty) return;

    // Nếu đã kết nối với cùng token, không cần khởi tạo lại nhưng đảm bảo listeners được gắn
    if (socket != null && socket!.connected && _currentToken == token) {
      _bindAllListeners();
      return;
    }

    _currentToken = token;

    // Hủy socket cũ nếu có trước khi tạo mới
    if (socket != null) {
      try {
        socket!.dispose();
      } catch (_) {}
      socket = null;
    }

    debugPrint('🔌 [SocketService] Connecting to ${AppConfig.serverUrl}...');

    socket = IO.io(
      AppConfig.serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    // Gắn lại toàn bộ event listeners đã đăng ký trong registry
    _bindAllListeners();

    socket!.onConnect((_) {
      debugPrint('🔌 [SocketService] Connected successfully! Socket ID: ${socket?.id}');
      _bindAllListeners();
      if (_activeConversationId != null) {
        socket!.emit('join_conversation', _activeConversationId);
      }
    });

    socket!.onReconnect((_) {
      debugPrint('🔌 [SocketService] Reconnected successfully! Socket ID: ${socket?.id}');
      _bindAllListeners();
      if (_activeConversationId != null) {
        socket!.emit('join_conversation', _activeConversationId);
      }
    });

    socket!.on('reconnect_attempt', (_) async {
      debugPrint('🔄 [SocketService] Reconnecting attempt...');
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final freshToken = await user.getIdToken();
          if (freshToken != null && freshToken.isNotEmpty) {
            _currentToken = freshToken;
            socket?.auth = {'token': freshToken};
            socket?.io.options?['auth'] = {'token': freshToken};
          }
        }
      } catch (e) {
        debugPrint('⚠️ [SocketService] Error refreshing token on reconnect: $e');
      }
    });

    socket!.onDisconnect((reason) {
      debugPrint('🔌 [SocketService] Disconnected. Reason: $reason');
    });

    socket!.onConnectError((err) {
      debugPrint('❌ [SocketService] Connect error: $err');
    });

    socket!.onError((err) {
      debugPrint('❌ [SocketService] Error: $err');
    });

    socket!.on('auth_error', (data) async {
      debugPrint('❌ [SocketService] Auth error from server: $data. Attempting token refresh...');
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final freshToken = await user.getIdToken(true);
          if (freshToken != null && freshToken.isNotEmpty) {
            connectSocket(token: freshToken);
          }
        }
      } catch (e) {
        debugPrint('❌ [SocketService] Token refresh failed: $e');
      }
    });

    socket!.connect();
  }

  void on(String event, Function(dynamic) callback) {
    _listeners[event] = [callback];
    _bindEvent(event);
  }

  static dynamic _normalizeData(dynamic data) {
    if (data is Map) {
      final map = <String, dynamic>{};
      data.forEach((k, v) {
        map[k.toString()] = _normalizeData(v);
      });
      return map;
    } else if (data is List) {
      return data.map((item) => _normalizeData(item)).toList();
    }
    return data;
  }

  void _bindEvent(String event) {
    if (socket == null) return;
    socket!.off(event);
    socket!.on(event, (data) {
      debugPrint('📩 [SocketService] Event "$event" received');
      final normalizedData = _normalizeData(data);
      final callbacks = List<Function(dynamic)>.from(_listeners[event] ?? []);
      for (final cb in callbacks) {
        try {
          cb(normalizedData);
        } catch (e, stack) {
          debugPrint('❌ [SocketService] Error in callback for "$event": $e\n$stack');
        }
      }
    });
  }

  void _bindAllListeners() {
    if (socket == null) return;
    for (final event in _listeners.keys) {
      _bindEvent(event);
    }
  }

  void disconnect() {
    debugPrint('🔌 [SocketService] Disconnecting socket...');
    _currentToken = null;
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }

  // Xin vào phòng chat để nghe tin nhắn riêng
  void joinConversation(int conversationId) {
    _activeConversationId = conversationId;
    if (socket != null && socket!.connected) {
      socket!.emit('join_conversation', conversationId);
    }
  }

  // Rời phòng chat khi thoát màn hình chi tiết
  void leaveConversation(int conversationId) {
    if (_activeConversationId == conversationId) {
      _activeConversationId = null;
    }
    if (socket != null && socket!.connected) {
      socket!.emit('leave_conversation', conversationId);
    }
  }

  // Báo cho đối phương biết mình đang gõ
  void emitTyping(int conversationId) {
    if (socket != null && socket!.connected) {
      socket!.emit('typing', {
        'conversationId': conversationId,
      });
    }
  }

  void emitStopTyping(int conversationId) {
    if (socket != null && socket!.connected) {
      socket!.emit('stop_typing', {
        'conversationId': conversationId,
      });
    }
  }

  // Lắng nghe tin nhắn mới
  void onNewMessage(Function(dynamic) callback) => on('new_message', callback);
  void onTyping(Function(dynamic) callback) => on('user_typing', callback);
  void onStopTyping(Function(dynamic) callback) => on('user_stop_typing', callback);
  void onRequestAccepted(Function(dynamic) callback) => on('request_accepted', callback);
  void onRequestDeclined(Function(dynamic) callback) => on('request_declined', callback);
  void onMessageRequest(Function(dynamic) callback) => on('message_request', callback);
  void onMessageDeleted(Function(dynamic) callback) => on('message_deleted', callback);
  void onMessageStatus(Function(dynamic) callback) => on('message_status', callback);
  void onMessagesRead(Function(dynamic) callback) => on('messages_read', callback);
  void onUserStatus(Function(dynamic) callback) => on('user_status', callback);
  void onNewNotification(Function(dynamic) callback) => on('new_notification', callback);
}
