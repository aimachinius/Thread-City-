import 'user_model.dart';
import 'post_media_model.dart';
import 'hashtag_model.dart';

enum PostType { post, comment, reply, quote }

class PostModel {
  final int id;
  final int userId;
  final int? parentId;
  final String content;
  final PostType type;
  final DateTime createdAt;
  
  // Thông tin mở rộng
  final UserModel? author;
  final int likeCount;
  final int commentCount;
  final int repostCount;
  final bool isLiked; // Thêm trường này
  final bool isFollowing; // Trạng thái follow của người xem đối với author của bài viết này
  
  final List<PostMediaModel> media;
  final List<HashtagModel> hashtags;
  final List<PostModel> replies; // nested replies

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
    this.isLiked = false,
    this.isFollowing = false,
    this.media = const [],
    this.hashtags = const [],
    this.replies = const [],
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    final counts = map['counts'] ?? {};
    
    List<PostMediaModel> parsedMedia = [];
    if (map['media'] != null && map['media'] is List) {
      parsedMedia = (map['media'] as List).map((m) => PostMediaModel.fromMap(m)).toList();
    }

    List<HashtagModel> parsedHashtags = [];
    if (map['hashtags'] != null && map['hashtags'] is List) {
      parsedHashtags = (map['hashtags'] as List).map((h) => HashtagModel.fromMap(h['hashtag'])).toList();
    }

    List<PostModel> parsedReplies = [];
    if (map['replies'] != null && map['replies'] is List) {
      parsedReplies = (map['replies'] as List).map((r) => PostModel.fromMap(r)).toList();
    }
    
    return PostModel(
      id: map['id'],
      userId: map['user_id'],
      parentId: map['parent_id'],
      content: map['content'] ?? '',
      type: PostType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'post'),
        orElse: () => PostType.post,
      ),
      createdAt: DateTime.parse(map['created_at']),
      author: map['user'] != null ? UserModel.fromMap(map['user']) : null,
      likeCount: counts['like_count'] ?? 0,
      commentCount: counts['comment_count'] ?? 0,
      repostCount: counts['repost_count'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isFollowing: map['isFollowing'] ?? false,
      media: parsedMedia,
      hashtags: parsedHashtags,
      replies: parsedReplies,
    );
  }

  PostModel copyWith({
    int? id,
    int? userId,
    int? parentId,
    String? content,
    PostType? type,
    DateTime? createdAt,
    UserModel? author,
    int? likeCount,
    int? commentCount,
    int? repostCount,
    bool? isLiked,
    bool? isFollowing,
    List<PostMediaModel>? media,
    List<HashtagModel>? hashtags,
    List<PostModel>? replies,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      repostCount: repostCount ?? this.repostCount,
      isLiked: isLiked ?? this.isLiked,
      isFollowing: isFollowing ?? this.isFollowing,
      media: media ?? this.media,
      hashtags: hashtags ?? this.hashtags,
      replies: replies ?? this.replies,
    );
  }
}