import 'user_model.dart';
import 'post_model.dart';

class NotificationModel {
  final int id;
  final int userId;
  final int actorId;
  final int? postId;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final UserModel actor;
  final PostModel? post;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    this.postId,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.actor,
    this.post,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      userId: map['user_id'],
      actorId: map['actor_id'],
      postId: map['post_id'],
      type: map['type'],
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      actor: UserModel.fromMap(Map<String, dynamic>.from(map['actor'])),
      post: map['post'] != null ? PostModel.fromMap(Map<String, dynamic>.from(map['post'])) : null,
    );
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    int? actorId,
    int? postId,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    UserModel? actor,
    PostModel? post,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      postId: postId ?? this.postId,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actor: actor ?? this.actor,
      post: post ?? this.post,
    );
  }
}
