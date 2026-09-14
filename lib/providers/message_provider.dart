import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/message_repository.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/socket_service.dart';
import '../utils/enum_utils.dart';
import 'auth_provider.dart' as app_auth;
import '../main.dart';
import '../widgets/top_notification_banner.dart';
import '../screens/chat_detail_screen.dart';

class MessageProvider extends ChangeNotifier {
  final IMessageRepository _messageRepository;
  app_auth.AuthProvider _authProvider;
  final SocketService _socketService = SocketService();

  List<ConversationModel> _conversations = [];
  List<ConversationModel> _messageRequests = [];
  final Map<int, List<MessageModel>> _conversationMessages = {};
  int? _activeConversationId;
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  String? _errorMessage;

  // Track typing users by their user ID
  final Set<int> _typingUsers = {};

  MessageProvider(this._messageRepository, this._authProvider) {
    _init();
  }

  void updateAuth(app_auth.AuthProvider auth) {
    _authProvider = auth;
    if (auth.isAuthenticated && auth.currentUserData != null) {
      _connectSocketIfPossible();
      fetchConversations();
    }
  }

  Future<void> _init() async {
    await _connectSocketIfPossible();
    _setupSocketListeners();
  }

  Future<void> _connectSocketIfPossible() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null && token.isNotEmpty) {
      _socketService.connectSocket(token: token);
    }
  }

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<ConversationModel> get messageRequests => _messageRequests;
  List<MessageModel> getActiveMessages(int conversationId) =>
      _conversationMessages[conversationId] ?? [];
  int? get activeConversationId => _activeConversationId;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get errorMessage => _errorMessage;
  Set<int> get typingUsers => _typingUsers;

  int get totalUnreadCount {
    final uniqueMap = <int, ConversationModel>{};
    for (final c in _conversations) {
      uniqueMap[c.id] = c;
    }
    for (final c in _messageRequests) {
      uniqueMap[c.id] = c;
    }
    return uniqueMap.values.fold<int>(0, (sum, c) => sum + c.unreadCount);
  }

  void setActiveConversation(int? conversationId) {
    _activeConversationId = conversationId;
    _typingUsers.clear();
    if (conversationId != null) {
      _socketService.joinConversation(conversationId);
    }
  }

  void notifyTyping(int conversationId) {
    final currentUser = _authProvider.currentUserData;
    if (currentUser != null && currentUser['id'] != null) {
      _socketService.emitTyping(conversationId);
    }
  }

  void notifyStopTyping(int conversationId) {
    final currentUser = _authProvider.currentUserData;
    if (currentUser != null && currentUser['id'] != null) {
      _socketService.emitStopTyping(conversationId);
    }
  }

  Future<void> fetchConversations() async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return;
    await _connectSocketIfPossible();

    _isLoadingConversations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversations =
          await _messageRepository.getConversations(firebaseUid: firebaseUid);
      _messageRequests =
          await _messageRepository.getMessageRequests(firebaseUid: firebaseUid);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(int conversationId, {bool refresh = false}) async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return;
    if (_isLoadingMessages) return;

    _isLoadingMessages = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final messages = await _messageRepository.getMessages(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
      );
      _conversationMessages[conversationId] = messages;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<bool> sendChatMessage({
    required int receiverId,
    required String content,
    String type = 'TEXT',
    String? mediaUrl,
    int? sharedPostId,
  }) async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return false;

    try {
      final message = await _messageRepository.sendMessage(
        firebaseUid: firebaseUid,
        receiverId: receiverId,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        sharedPostId: sharedPostId,
      );

      // Manually add the message to the UI instantly so it shows up without delay
      final convId = message.conversationId;
      if (_conversationMessages.containsKey(convId)) {
        if (!_conversationMessages[convId]!.any((m) => m.id == message.id)) {
          _conversationMessages[convId]!.insert(0, message);
        }
      } else {
        _conversationMessages[convId] = [message];
      }

      final convIndex = _conversations.indexWhere((c) => c.id == convId);
      if (convIndex != -1) {
        final existingConv = _conversations[convIndex];
        _conversations[convIndex] = existingConv.copyWith(
          lastActivityAt: message.createdAt,
          lastMessage: message,
        );
        _conversations
            .sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
      } else {
        final reqIndex = _messageRequests.indexWhere((c) => c.id == convId);
        if (reqIndex != -1) {
          final existingReq = _messageRequests[reqIndex];
          _messageRequests[reqIndex] = existingReq.copyWith(
            lastActivityAt: message.createdAt,
            lastMessage: message,
          );
          _messageRequests
              .sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
        } else {
          await fetchConversations();
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<ConversationModel?> createOrOpenConversation(int receiverId) async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return null;
    try {
      final conversation = await _messageRepository.createOrOpenConversation(
        firebaseUid: firebaseUid,
        receiverId: receiverId,
      );
      await fetchConversations();
      return conversation;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> markAsRead(int conversationId) async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return false;
    final currentUserId = (_authProvider.currentUserData?['id'] as num?)?.toInt();

    try {
      await _messageRepository.markMessagesAsRead(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
      );
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        final conv = _conversations[idx];
        final updatedLastMessage = (conv.lastMessage != null &&
                currentUserId != null &&
                conv.lastMessage!.senderId != currentUserId)
            ? conv.lastMessage!.copyWith(status: MessageStatus.READ)
            : conv.lastMessage;
        _conversations[idx] = conv.copyWith(
          unreadCount: 0,
          lastMessage: updatedLastMessage,
        );
      }
      final reqIdx = _messageRequests.indexWhere((c) => c.id == conversationId);
      if (reqIdx != -1) {
        final req = _messageRequests[reqIdx];
        final updatedLastMessage = (req.lastMessage != null &&
                currentUserId != null &&
                req.lastMessage!.senderId != currentUserId)
            ? req.lastMessage!.copyWith(status: MessageStatus.READ)
            : req.lastMessage;
        _messageRequests[reqIdx] = req.copyWith(
          unreadCount: 0,
          lastMessage: updatedLastMessage,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('Lỗi markAsRead: $e');
      return false;
    }
  }

  Future<bool> blockConversation(int conversationId) async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return false;

    try {
      await _messageRepository.blockConversation(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
      );
      _conversations.removeWhere((c) => c.id == conversationId);
      notifyListeners();
      return true;
    } catch (e) {
      print('Lỗi blockConversation: $e');
      return false;
    }
  }

  Future<bool> deleteMessage(int messageId) async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return false;

    try {
      await _messageRepository.deleteMessage(
        messageId: messageId,
        firebaseUid: firebaseUid,
      );
      // Update UI by removing message from list
      for (final messages in _conversationMessages.values) {
        messages.removeWhere((m) => m.id == messageId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('Lỗi deleteMessage: $e');
      return false;
    }
  }

  Future<bool> hideMessageForMe(int messageId) async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return false;

    try {
      await _messageRepository.hideMessageForMe(
        messageId: messageId,
        firebaseUid: firebaseUid,
      );
      for (final messages in _conversationMessages.values) {
        messages.removeWhere((m) => m.id == messageId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptMessageRequest(int conversationId) async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return false;

    try {
      final updatedConv = await _messageRepository.acceptRequest(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
      );

      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        _conversations[idx] = updatedConv;
      } else {
        _conversations.insert(0, updatedConv);
      }
      _conversations
          .sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
      _messageRequests.removeWhere((c) => c.id == conversationId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> declineMessageRequest(int conversationId) async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return false;

    try {
      await _messageRepository.declineRequest(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
      );

      _conversations.removeWhere((c) => c.id == conversationId);
      _messageRequests.removeWhere((c) => c.id == conversationId);
      _conversationMessages.remove(conversationId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setupSocketListeners() {
    _socketService.onNewMessage((data) {
      final newMessage = MessageModel.fromMap(data);
      final convId = newMessage.conversationId;
      final currentUserId = _authProvider.currentUserData?['id'] as int?;
      final isFromOther = newMessage.senderId != currentUserId;
      final isOutsideThisChat = convId != _activeConversationId;

      // Append to cache
      if (_conversationMessages.containsKey(convId)) {
        final currentMessages = _conversationMessages[convId]!;
        if (!currentMessages.any((m) => m.id == newMessage.id)) {
          // Since messages are sorted desc, new message goes to the top (index 0)
          currentMessages.insert(0, newMessage);
        }
      } else {
        _conversationMessages[convId] = [newMessage];
      }

      // Update conversation item
      final convIndex = _conversations.indexWhere((c) => c.id == convId);
      if (convIndex != -1) {
        final existingConv = _conversations[convIndex];
        final isAlreadyLast = existingConv.lastMessage?.id == newMessage.id;
        final newUnread = (isFromOther && isOutsideThisChat && !isAlreadyLast)
            ? existingConv.unreadCount + 1
            : existingConv.unreadCount;
        _conversations[convIndex] = existingConv.copyWith(
          lastActivityAt: newMessage.createdAt,
          lastMessage: newMessage,
          unreadCount: newUnread,
        );
        _conversations
            .sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
      } else {
        final reqIndex = _messageRequests.indexWhere((c) => c.id == convId);
        if (reqIndex != -1) {
          final existingReq = _messageRequests[reqIndex];
          final isAlreadyLast = existingReq.lastMessage?.id == newMessage.id;
          final newUnread = (isFromOther && isOutsideThisChat && !isAlreadyLast)
              ? existingReq.unreadCount + 1
              : existingReq.unreadCount;
          _messageRequests[reqIndex] = existingReq.copyWith(
            lastActivityAt: newMessage.createdAt,
            lastMessage: newMessage,
            unreadCount: newUnread,
          );
          _messageRequests
              .sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
        } else {
          fetchConversations();
        }
      }

      // Show top-down in-app notification if it's not the active conversation and not sent by me
      if (isOutsideThisChat && isFromOther && newMessage.sender != null) {
        final sender = newMessage.sender!;
        final previewText = newMessage.type == MessageType.POST_SHARE
            ? 'Đã chia sẻ một bài viết'
            : (newMessage.type == MessageType.IMAGE
                ? 'Đã gửi một hình ảnh'
                : (newMessage.type == MessageType.VIDEO
                    ? 'Đã gửi một video'
                    : (newMessage.content ?? '')));

        TopNotificationBanner.show(
          title: sender.nickname ?? sender.username,
          message: previewText,
          avatarUrl: sender.avatarUrl,
          onTap: () {
            final conv = _conversations.where((c) => c.id == convId).firstOrNull ??
                _messageRequests.where((c) => c.id == convId).firstOrNull;
            if (conv != null && navigatorKey.currentState != null) {
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(conversation: conv),
                ),
              );
            }
          },
        );
      }

      notifyListeners();
    });

    _socketService.onTyping((data) {
      final convId = (data['conversationId'] as num?)?.toInt();
      final userId = (data['userId'] as num?)?.toInt();

      if (convId != null && userId != null && convId == _activeConversationId) {
        // Don't show typing for current user
        final currentUserId = _authProvider.currentUserData?['id'];
        if (userId == currentUserId) return;

        _typingUsers.add(userId);
        notifyListeners();

        // Clear typing indicator after 3 seconds of inactivity
        Future.delayed(const Duration(seconds: 2), () {
          if (_typingUsers.contains(userId)) {
            _typingUsers.remove(userId);
            notifyListeners();
          }
        });
      }
    });

    _socketService.onStopTyping((data) {
      final convId = (data['conversationId'] as num?)?.toInt();
      final userId = (data['userId'] as num?)?.toInt();
      if (convId == _activeConversationId && userId != null) {
        _typingUsers.remove(userId);
        notifyListeners();
      }
    });

    _socketService.onRequestAccepted((data) {
      final convId = (data['conversationId'] as num?)?.toInt();
      if (convId == null) return;
      final idx = _conversations.indexWhere((c) => c.id == convId);
      if (idx != -1) {
        final c = _conversations[idx];
        _conversations[idx] = c.copyWith(status: ConversationStatus.ACTIVE);
      } else {
        final reqIdx = _messageRequests.indexWhere((c) => c.id == convId);
        if (reqIdx != -1) {
          final c = _messageRequests[reqIdx];
          _conversations.insert(0, c.copyWith(status: ConversationStatus.ACTIVE));
        }
      }
      _messageRequests.removeWhere((c) => c.id == convId);
      notifyListeners();
    });

    _socketService.onMessageRequest((_) {
      fetchConversations();
    });

    _socketService.onMessageDeleted((data) {
      final messageId = (data['messageId'] as num?)?.toInt();
      if (messageId == null) return;
      for (final messages in _conversationMessages.values) {
        final idx = messages.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          final old = messages[idx];
          messages[idx] = MessageModel(
            id: old.id,
            conversationId: old.conversationId,
            senderId: old.senderId,
            type: old.type,
            content: old.content,
            mediaUrl: old.mediaUrl,
            sharedPostId: old.sharedPostId,
            createdAt: old.createdAt,
            status: old.status,
            isDeleted: true,
            sender: old.sender,
            sharedPost: old.sharedPost,
          );
        }
      }
      notifyListeners();
    });

    _socketService.onMessageStatus((data) {
      final messageId = (data['messageId'] as num?)?.toInt();
      final statusName = data['status']?.toString();
      final convId = (data['conversationId'] as num?)?.toInt();
      if (statusName == null) return;
      final status = MessageStatus.values.firstWhere(
        (e) => enumName(e) == statusName,
        orElse: () => MessageStatus.SENT,
      );

      if (messageId != null) {
        for (final messages in _conversationMessages.values) {
          final idx = messages.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            messages[idx] = messages[idx].copyWith(status: status);
          }
        }

        if (convId != null) {
          final cIdx = _conversations.indexWhere((c) => c.id == convId);
          if (cIdx != -1 && _conversations[cIdx].lastMessage?.id == messageId) {
            _conversations[cIdx] = _conversations[cIdx].copyWith(
              lastMessage: _conversations[cIdx].lastMessage!.copyWith(status: status),
            );
          }
          final rIdx = _messageRequests.indexWhere((c) => c.id == convId);
          if (rIdx != -1 && _messageRequests[rIdx].lastMessage?.id == messageId) {
            _messageRequests[rIdx] = _messageRequests[rIdx].copyWith(
              lastMessage: _messageRequests[rIdx].lastMessage!.copyWith(status: status),
            );
          }
        }
        notifyListeners();
      }
    });

    _socketService.onMessagesRead((data) {
      final convId = (data['conversationId'] as num?)?.toInt();
      final readerId = (data['readerId'] as num?)?.toInt();
      final currentUserId = (_authProvider.currentUserData?['id'] as num?)?.toInt();
      if (convId == null) return;

      if (readerId != null && currentUserId != null) {
        if (readerId != currentUserId) {
          // The other user (readerId) read my messages!
          // Mark all messages sent by me in this conversation as READ
          if (_conversationMessages.containsKey(convId)) {
            for (int i = 0; i < _conversationMessages[convId]!.length; i++) {
              if (_conversationMessages[convId]![i].senderId == currentUserId) {
                _conversationMessages[convId]![i] =
                    _conversationMessages[convId]![i].copyWith(status: MessageStatus.READ);
              }
            }
          }
          final cIdx = _conversations.indexWhere((c) => c.id == convId);
          if (cIdx != -1 && _conversations[cIdx].lastMessage?.senderId == currentUserId) {
            _conversations[cIdx] = _conversations[cIdx].copyWith(
              lastMessage: _conversations[cIdx].lastMessage!.copyWith(status: MessageStatus.READ),
            );
          }
          final rIdx = _messageRequests.indexWhere((c) => c.id == convId);
          if (rIdx != -1 && _messageRequests[rIdx].lastMessage?.senderId == currentUserId) {
            _messageRequests[rIdx] = _messageRequests[rIdx].copyWith(
              lastMessage: _messageRequests[rIdx].lastMessage!.copyWith(status: MessageStatus.READ),
            );
          }
        } else {
          // I am the reader. My unread count for this conversation is 0.
          final cIdx = _conversations.indexWhere((c) => c.id == convId);
          if (cIdx != -1) {
            _conversations[cIdx] = _conversations[cIdx].copyWith(unreadCount: 0);
          }
          final rIdx = _messageRequests.indexWhere((c) => c.id == convId);
          if (rIdx != -1) {
            _messageRequests[rIdx] = _messageRequests[rIdx].copyWith(unreadCount: 0);
          }
        }
        notifyListeners();
      }
    });

    _socketService.onUserStatus((data) {
      final userId = (data['userId'] as num?)?.toInt();
      final isOnline = data['isOnline'] as bool?;
      if (userId == null || isOnline == null) return;

      bool changed = false;
      for (var c in _conversations) {
        if (c.partner.id == userId && c.partner.isOnline != isOnline) {
          c.partner.isOnline = isOnline;
          changed = true;
        }
      }
      for (var c in _messageRequests) {
        if (c.partner.id == userId && c.partner.isOnline != isOnline) {
          c.partner.isOnline = isOnline;
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}

