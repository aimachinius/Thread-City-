import 'package:thread_app/models/post_model.dart';

class SearchResultModel {
  final List<UserSearchModel> users;
  final List<PostModel> posts;
  final List<TrendingHashtagModel> hashtags;

  SearchResultModel({
    this.users = const [],
    this.posts = const [],
    this.hashtags = const [],
  });

  SearchResultModel copyWith({
    List<UserSearchModel>? users,
    List<PostModel>? posts,
    List<TrendingHashtagModel>? hashtags,
  }) {
    return SearchResultModel(
      users: users ?? this.users,
      posts: posts ?? this.posts,
      hashtags: hashtags ?? this.hashtags,
    );
  }

  factory SearchResultModel.fromMap(Map<String, dynamic> map) {
    return SearchResultModel(
      users: (map['users'] as List? ?? [])
          .map((e) => UserSearchModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      posts: (map['posts'] as List? ?? [])
          .map((e) => PostModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      hashtags: (map['hashtags'] as List? ?? [])
          .map((e) => TrendingHashtagModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserSearchModel {
  final int id;
  final String firebaseUid;
  final String username;
  final String? nickname;
  final String? bio;
  final String? avatarUrl;
  final int followerCount;
  final int postCount;
  final bool isFollowing;

  UserSearchModel({
    required this.id,
    required this.firebaseUid,
    required this.username,
    this.nickname,
    this.bio,
    this.avatarUrl,
    this.followerCount = 0,
    this.postCount = 0,
    this.isFollowing = false,
  });

  UserSearchModel copyWith({
    int? id,
    String? firebaseUid,
    String? username,
    String? nickname,
    String? bio,
    String? avatarUrl,
    int? followerCount,
    int? postCount,
    bool? isFollowing,
  }) {
    return UserSearchModel(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followerCount: followerCount ?? this.followerCount,
      postCount: postCount ?? this.postCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  factory UserSearchModel.fromMap(Map<String, dynamic> map) {
    return UserSearchModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      firebaseUid: map['firebase_uid'] ?? '',
      username: map['username'] ?? '',
      nickname: map['nickname'],
      bio: map['bio'],
      avatarUrl: map['avatar_url'],
      followerCount: map['followerCount'] ?? map['follower_count'] ?? 0,
      postCount: map['postCount'] ?? map['post_count'] ?? 0,
      isFollowing: map['isFollowing'] ?? (map['is_following'] == 1 || map['is_following'] == true || map['is_following'] == '1'),
    );
  }
}

class TrendingHashtagModel {
  final int id;
  final String tagName;
  final int postCount;

  TrendingHashtagModel({
    required this.id,
    required this.tagName,
    this.postCount = 0,
  });

  factory TrendingHashtagModel.fromMap(Map<String, dynamic> map) {
    return TrendingHashtagModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      tagName: map['tagName'] ?? map['tag_name'] ?? '',
      postCount: map['postCount'] ?? map['post_count'] ?? 0,
    );
  }

  TrendingHashtagModel copyWith({
    int? id,
    String? tagName,
    int? postCount,
  }) {
    return TrendingHashtagModel(
      id: id ?? this.id,
      tagName: tagName ?? this.tagName,
      postCount: postCount ?? this.postCount,
    );
  }
}
