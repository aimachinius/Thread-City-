import 'package:flutter_test/flutter_test.dart';
import 'package:thread_app/models/search_result_model.dart';

void main() {
  group('UserSearchModel Tests', () {
    test('fromMap parses valid map correctly', () {
      final map = {
        'id': 42,
        'firebase_uid': 'fb_42',
        'username': 'thanh_hau',
        'nickname': 'Thanh Hậu',
        'bio': 'Flutter & Node.js Developer',
        'avatar_url': 'https://example.com/avatar.png',
        'follower_count': 1500,
        'post_count': 35,
        'is_following': true,
      };

      final user = UserSearchModel.fromMap(map);

      expect(user.id, 42);
      expect(user.firebaseUid, 'fb_42');
      expect(user.username, 'thanh_hau');
      expect(user.nickname, 'Thanh Hậu');
      expect(user.bio, 'Flutter & Node.js Developer');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.followerCount, 1500);
      expect(user.postCount, 35);
      expect(user.isFollowing, isTrue);
    });

    test('fromMap handles null and missing fields gracefully', () {
      final map = <String, dynamic>{
        'id': 10,
        'firebase_uid': 'fb_10',
        'username': 'minh_dev',
      };

      final user = UserSearchModel.fromMap(map);

      expect(user.id, 10);
      expect(user.firebaseUid, 'fb_10');
      expect(user.username, 'minh_dev');
      expect(user.nickname, isNull);
      expect(user.bio, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.followerCount, 0);
      expect(user.postCount, 0);
      expect(user.isFollowing, isFalse);
    });

    test('copyWith toggles isFollowing correctly', () {
      final user = UserSearchModel(
        id: 1,
        firebaseUid: 'fb_1',
        username: 'alice',
        followerCount: 10,
        isFollowing: false,
      );

      final updated = user.copyWith(isFollowing: true);

      expect(updated.id, user.id);
      expect(updated.username, user.username);
      expect(updated.isFollowing, isTrue);
      expect(user.isFollowing, isFalse);
    });
  });

  group('TrendingHashtagModel Tests', () {
    test('fromMap parses valid map correctly', () {
      final map = {
        'tag_name': 'flutter',
        'post_count': 450,
      };

      final hashtag = TrendingHashtagModel.fromMap(map);

      expect(hashtag.tagName, 'flutter');
      expect(hashtag.postCount, 450);
    });

    test('fromMap fallback if tag_name is null', () {
      final map = <String, dynamic>{};

      final hashtag = TrendingHashtagModel.fromMap(map);

      expect(hashtag.tagName, '');
      expect(hashtag.postCount, 0);
    });

    test('copyWith updates fields correctly', () {
      final hashtag = TrendingHashtagModel(id: 1, tagName: 'dart', postCount: 100);
      final updated = hashtag.copyWith(postCount: 200);

      expect(updated.tagName, 'dart');
      expect(updated.postCount, 200);
    });
  });

  group('SearchResultModel Tests', () {
    test('fromMap parses users, posts, and hashtags', () {
      final map = {
        'users': [
          {
            'id': 1,
            'firebase_uid': 'fb_1',
            'username': 'bob',
            'follower_count': 5,
            'post_count': 2,
            'is_following': false,
          }
        ],
        'posts': [
          {
            'id': 101,
            'user_id': 1,
            'content': 'Hello Flutter Search!',
            'type': 'post',
            'created_at': '2026-09-20T10:00:00Z',
            'counts': {
              'like_count': 10,
              'comment_count': 2,
              'repost_count': 1,
            },
          }
        ],
        'hashtags': [
          {
            'tag_name': 'flutter',
            'post_count': 99,
          }
        ],
      };

      final result = SearchResultModel.fromMap(map);

      expect(result.users.length, 1);
      expect(result.users.first.username, 'bob');
      expect(result.posts.length, 1);
      expect(result.posts.first.content, 'Hello Flutter Search!');
      expect(result.hashtags.length, 1);
      expect(result.hashtags.first.tagName, 'flutter');
    });

    test('fromMap handles null lists safely', () {
      final map = <String, dynamic>{};

      final result = SearchResultModel.fromMap(map);

      expect(result.users, isEmpty);
      expect(result.posts, isEmpty);
      expect(result.hashtags, isEmpty);
    });
  });
}
