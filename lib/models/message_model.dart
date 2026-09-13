import 'user_model.dart';
import 'post_model.dart';
import '../utils/enum_utils.dart';

enum MessageType { TEXT, IMAGE, VIDEO, POST_SHARE }
enum MessageStatus { SENT, DELIVERED, READ }

class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final MessageType type;
  final String? content;
  final String? mediaUrl;
  final int? sharedPostId;
  final DateTime createdAt;
  final MessageStatus status;
  final bool isDeleted;
  
  // Expanded fields
  final UserModel? sender;
  final PostModel? sharedPost;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.sharedPostId,
    required this.createdAt,
    this.status = MessageStatus.SENT,
    this.isDeleted = false,
    this.sender,
    this.sharedPost,
  });

  MessageModel copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    MessageType? type,
    String? content,
    String? mediaUrl,
    int? sharedPostId,
    DateTime? createdAt,
    MessageStatus? status,
    bool? isDeleted,
    UserModel? sender,
    PostModel? sharedPost,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      sharedPostId: sharedPostId ?? this.sharedPostId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      sender: sender ?? this.sender,
      sharedPost: sharedPost ?? this.sharedPost,
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    if (map['type'] == 'POST_SHARE' || map['type'] == 'SHARED_POST') {
      print('--- DEBUG MESSAGE FROM MAP ---');
      print(map);
      print('------------------------------');
    }
    return MessageModel(
      id: map['id'],
      conversationId: map['conversation_id'],
      senderId: map['sender_id'],
      type: MessageType.values.firstWhere(
        (e) {
          final incomingType = (map['type'] ?? 'TEXT').toString();
          final normalized = incomingType == 'SHARED_POST'
              ? 'POST_SHARE'
              : incomingType;
          return enumName(e) == normalized;
        },
        orElse: () => MessageType.TEXT,
      ),
      content: map['content'],
      mediaUrl: map['media_url'],
      sharedPostId: map['shared_post_id'],
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => enumName(e) == (map['status'] ?? 'SENT'),
        orElse: () => MessageStatus.SENT,
      ),
      isDeleted: map['is_deleted'] ?? false,
      sender: map['sender'] != null ? UserModel.fromMap(map['sender']) : null,
      sharedPost: _parseSharedPost(map['posts']),
    );
  }

  static PostModel? _parseSharedPost(dynamic postData) {
    if (postData == null) return null;
    try {
      // Force-convert to Map<String, dynamic> because Socket/API can return
      // LinkedHashMap<String, Object> which is not directly castable.
      final map = Map<String, dynamic>.from(postData as Map);
      final post = PostModel.fromMap(map);
      print('[DEBUG] sharedPost parsed OK: id=${post.id}, content=${post.content}');
      return post;
    } catch (e, stacktrace) {
      print('[ERROR] _parseSharedPost failed: $e');
      print(stacktrace);
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'type': enumName(type),
      'content': content,
      'media_url': mediaUrl,
      'shared_post_id': sharedPostId,
      'created_at': createdAt.toIso8601String(),
      'status': enumName(status),
      'is_deleted': isDeleted,
    };
  }
}
