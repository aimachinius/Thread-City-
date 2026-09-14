import 'user_model.dart';
import 'post_media_model.dart';
import 'hashtag_model.dart';
import '../utils/enum_utils.dart';

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
  final bool isLiked; 
  final bool isReposted;
  final String? repostedBy;
  final bool isFollowing; 
  
  final List<PostMediaModel> media;
  final List<HashtagModel> hashtags;
  final List<PostModel> replies; 

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
    this.isReposted = false,
    this.repostedBy,
    this.isFollowing = false,
    this.media = const [],
    this.hashtags = const [],
    this.replies = const [],
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    final counts = map['counts'] ?? {};
    
    List<PostMediaModel> parsedMedia = [];
    if (map['media'] != null && map['media'] is List) {
      parsedMedia = (map['media'] as List).map((m) => PostMediaModel.fromMap(Map<String, dynamic>.from(m as Map))).toList();
    }

    List<HashtagModel> parsedHashtags = [];
    if (map['hashtags'] != null && map['hashtags'] is List) {
      parsedHashtags = (map['hashtags'] as List).map((h) => HashtagModel.fromMap(Map<String, dynamic>.from(h['hashtag'] as Map))).toList();
    }

    List<PostModel> parsedReplies = [];
    if (map['replies'] != null && map['replies'] is List) {
      parsedReplies = (map['replies'] as List).map((r) => PostModel.fromMap(Map<String, dynamic>.from(r as Map))).toList();
    }
    
    return PostModel(
      id: map['id'] ?? 0,
      userId: map['user_id'] ?? 0,
      parentId: map['parent_id'],
      content: map['content'] ?? '',
      type: PostType.values.firstWhere(
        (e) => enumName(e) == (map['type'] ?? 'post'),
        orElse: () => PostType.post,
      ),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
      author: map['user'] != null ? UserModel.fromMap(Map<String, dynamic>.from(map['user'] as Map)) : null,
      likeCount: counts['like_count'] ?? 0,
      commentCount: counts['comment_count'] ?? 0,
      repostCount: counts['repost_count'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isReposted: map['isReposted'] ?? false,
      repostedBy: map['repostedBy'],
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
    bool? isReposted,
    String? repostedBy,
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
      isReposted: isReposted ?? this.isReposted,
      repostedBy: repostedBy ?? this.repostedBy,
      isFollowing: isFollowing ?? this.isFollowing,
      media: media ?? this.media,
      hashtags: hashtags ?? this.hashtags,
      replies: replies ?? this.replies,
    );
  }
}