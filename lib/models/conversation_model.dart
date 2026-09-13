import 'user_model.dart';
import 'message_model.dart';
import '../utils/enum_utils.dart';

enum ConversationStatus { ACTIVE, PENDING, DECLINED, BLOCKED }

class ConversationModel {
  final int id;
  final ConversationStatus status;
  final DateTime lastActivityAt;
  final bool isMuted;
  final UserModel partner;
  final MessageModel? lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.status,
    required this.lastActivityAt,
    required this.isMuted,
    required this.partner,
    this.lastMessage,
    this.unreadCount = 0,
  });

  ConversationModel copyWith({
    int? id,
    ConversationStatus? status,
    DateTime? lastActivityAt,
    bool? isMuted,
    UserModel? partner,
    MessageModel? lastMessage,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      status: status ?? this.status,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isMuted: isMuted ?? this.isMuted,
      partner: partner ?? this.partner,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'],
      status: ConversationStatus.values.firstWhere(
        (e) => enumName(e) == (map['status'] ?? 'ACTIVE'),
        orElse: () => ConversationStatus.ACTIVE,
      ),
      lastActivityAt:
          DateTime.tryParse((map['last_activity_at'] ?? '').toString()) ??
              DateTime.now(),
      isMuted: map['is_muted'] ?? false,
      partner: UserModel.fromMap(map['partner']),
      lastMessage: map['last_message'] != null ? MessageModel.fromMap(map['last_message']) : null,
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'status': enumName(status),
      'last_activity_at': lastActivityAt.toIso8601String(),
      'is_muted': isMuted,
      'partner': partner.toMap(),
      'last_message': lastMessage?.toMap(),
      'unread_count': unreadCount,
    };
  }
}
