import 'user_model.dart';

enum PostType { post, comment, reply, quote }

class PostModel {
  final String id;
  final String userId;
  final String? parentId;
  final String content;
  final PostType type;
  final DateTime createdAt;
  
  // Thông tin mở rộng (thường lấy từ JOIN hoặc bảng counts)
  final UserModel? author;
  final int likeCount;
  final int commentCount;
  final int repostCount;

  PostModel({
    required this.id,
    required this.userId,
    this.parentId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.author,
    this.likeCount = 0,
    this.commentCount = 0,
    this.repostCount = 0,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      parentId: map['parent_id']?.toString(),
      content: map['content'],
      type: PostType.values.firstWhere((e) => e.name == map['type']),
      createdAt: DateTime.parse(map['created_at']),
      author: map['author'] != null ? UserModel.fromMap(map['author']) : null,
      likeCount: map['like_count'] ?? 0,
      commentCount: map['comment_count'] ?? 0,
      repostCount: map['repost_count'] ?? 0,
    );
  }
}