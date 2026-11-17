import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:thread_app/data/repositories/search_repository.dart';
import 'package:thread_app/models/post_model.dart';
import 'package:thread_app/models/search_result_model.dart';
import 'package:thread_app/providers/search_provider.dart';

class MockSearchRepository implements ISearchRepository {
  Completer<SearchResultModel>? searchCompleter;
  SearchResultModel? defaultSearchResult;
  Exception? searchError;
  String? lastSearchQuery;
  String? lastSearchType;
  String? lastSearchViewerUid;

  List<TrendingHashtagModel> defaultTrending = [];
  Exception? trendingError;

  Completer<List<PostModel>>? hashtagCompleter;
  List<PostModel>? defaultHashtagPosts;
  Exception? hashtagError;
  String? lastHashtagTag;
  String? lastHashtagSort;

  @override
  Future<SearchResultModel> search({
    required String query,
    String type = 'all',
    String? viewerUid,
  }) async {
    lastSearchQuery = query;
    lastSearchType = type;
    lastSearchViewerUid = viewerUid;
    if (searchError != null) throw searchError!;
    if (searchCompleter != null) return await searchCompleter!.future;
    return defaultSearchResult ??
        SearchResultModel(users: [], posts: [], hashtags: []);
  }

  @override
  Future<List<TrendingHashtagModel>> getTrendingHashtags() async {
    if (trendingError != null) throw trendingError!;
    return defaultTrending;
  }

  @override
  Future<List<PostModel>> getPostsByHashtag(
    String tag, {
    String? viewerUid,
    String sort = 'latest',
  }) async {
    lastHashtagTag = tag;
    lastHashtagSort = sort;
    if (hashtagError != null) throw hashtagError!;
    if (hashtagCompleter != null) return await hashtagCompleter!.future;
    return defaultHashtagPosts ?? [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSearchRepository mockRepo;
  late SearchProvider provider;

  setUp(() {
    mockRepo = MockSearchRepository();
    provider = SearchProvider(searchRepository: mockRepo);
  });

  tearDown(() {
    provider.dispose();
  });

  group('SearchProvider Query & Generation Tests', () {
    test('query < 2 chars clears results and cancels search immediately', () async {
      provider.onQueryChanged('abc');
      expect(provider.currentQuery, 'abc');

      // Now clear query before debounce
      provider.onQueryChanged('a');
      expect(provider.currentQuery, 'a');
      expect(provider.searchResult, isNull);
      expect(provider.isSearching, isFalse);
    });

    test('stale in-flight search response is ignored when query is cleared', () async {
      final completer = Completer<SearchResultModel>();
      mockRepo.searchCompleter = completer;

      // Start search with 'react'
      provider.onQueryChanged('react');
      // Advance timer past 300ms debounce
      await Future.delayed(const Duration(milliseconds: 350));
      expect(provider.isSearching, isTrue);

      // User clears query to 'r'
      provider.onQueryChanged('r');
      expect(provider.searchResult, isNull);
      expect(provider.isSearching, isFalse);

      // Old search finishes
      completer.complete(SearchResultModel(
        users: [
          UserSearchModel(
            id: 1,
            firebaseUid: 'fb_1',
            username: 'react_dev',
            isFollowing: false,
          )
        ],
        posts: [],
        hashtags: [],
      ));

      // Wait a microtask
      await Future.delayed(Duration.zero);

      // Verify old result was NOT applied
      expect(provider.searchResult, isNull);
      expect(provider.isSearching, isFalse);
    });

    test('stale query result is ignored when new valid query starts', () async {
      final completer1 = Completer<SearchResultModel>();
      mockRepo.searchCompleter = completer1;

      // First query: 'alpha'
      provider.onQueryChanged('alpha');
      await Future.delayed(const Duration(milliseconds: 350));

      // Second query: 'beta' before alpha completes
      final completer2 = Completer<SearchResultModel>();
      mockRepo.searchCompleter = completer2;
      provider.onQueryChanged('beta');
      await Future.delayed(const Duration(milliseconds: 350));

      // Complete alpha (stale)
      completer1.complete(SearchResultModel(
        users: [
          UserSearchModel(
            id: 10,
            firebaseUid: 'fb_10',
            username: 'alpha_user',
            isFollowing: false,
          )
        ],
        posts: [],
        hashtags: [],
      ));
      await Future.delayed(Duration.zero);

      // Alpha should not have overwritten beta's in-progress state
      expect(provider.searchResult, isNull);
      expect(provider.isSearching, isTrue);

      // Complete beta (fresh)
      completer2.complete(SearchResultModel(
        users: [
          UserSearchModel(
            id: 20,
            firebaseUid: 'fb_20',
            username: 'beta_user',
            isFollowing: false,
          )
        ],
        posts: [],
        hashtags: [],
      ));
      await Future.delayed(Duration.zero);

      // Beta results applied!
      expect(provider.searchResult?.users.first.username, 'beta_user');
      expect(provider.isSearching, isFalse);
    });
  });

  group('SearchProvider Follow/Unfollow Tests', () {
    setUp(() async {
      mockRepo.defaultSearchResult = SearchResultModel(
        users: [
          UserSearchModel(
            id: 99,
            firebaseUid: 'fb_99',
            username: 'target_user',
            followerCount: 50,
            isFollowing: false,
          )
        ],
        posts: [],
        hashtags: [],
      );

      provider.onQueryChanged('target');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(provider.searchResult?.users.first.isFollowing, isFalse);
    });

    test('toggleFollowUser optimistically flips follow status on success', () async {
      var apiCalled = false;

      await provider.toggleFollowUser(
        userId: 99,
        apiCall: (userId, newStatus) async {
          apiCalled = true;
          expect(userId, 99);
          expect(newStatus, isTrue);
        },
      );

      expect(apiCalled, isTrue);
      expect(provider.searchResult?.users.first.isFollowing, isTrue);
      expect(provider.searchResult?.users.first.followerCount, 51);
      expect(provider.isFollowLoading(99), isFalse);
    });

    test('toggleFollowUser rolls back optimistic update when API throws exception', () async {
      await provider.toggleFollowUser(
        userId: 99,
        apiCall: (userId, newStatus) async {
          throw Exception('Network timeout');
        },
      );

      expect(provider.searchResult?.users.first.isFollowing, isFalse);
      expect(provider.searchResult?.users.first.followerCount, 50);
      expect(provider.isFollowLoading(99), isFalse);
    });

    test('toggleFollowUser guards against duplicate concurrent calls for same user', () async {
      int apiCallCount = 0;
      final completer = Completer<void>();

      final f1 = provider.toggleFollowUser(
        userId: 99,
        apiCall: (userId, newStatus) async {
          apiCallCount++;
          await completer.future;
        },
      );

      expect(provider.isFollowLoading(99), isTrue);

      // Second call while first is in-flight
      final f2 = provider.toggleFollowUser(
        userId: 99,
        apiCall: (userId, newStatus) async {
          apiCallCount++;
        },
      );

      // Complete the first call
      completer.complete();
      await Future.wait([f1, f2]);

      // Only first call should have executed
      expect(apiCallCount, 1);
      expect(provider.isFollowLoading(99), isFalse);
    });
  });

  group('SearchProvider Hashtag Feed Tests', () {
    test('fetchHashtagFeed loads posts and handles sort parameter', () async {
      mockRepo.defaultHashtagPosts = [
        PostModel(
          id: 1,
          userId: 10,
          content: 'Post with #flutter',
          type: PostType.post,
          createdAt: DateTime.now(),
        )
      ];

      await provider.fetchHashtagFeed('#flutter', sort: 'latest');

      expect(mockRepo.lastHashtagTag, '#flutter');
      expect(mockRepo.lastHashtagSort, 'latest');
      expect(provider.hashtagPosts.length, 1);
      expect(provider.hashtagPosts.first.content, 'Post with #flutter');
      expect(provider.isHashtagLoading, isFalse);
      expect(provider.hashtagError, isNull);
    });

    test('fetchHashtagFeed discards stale sort responses', () async {
      final completer1 = Completer<List<PostModel>>();
      mockRepo.hashtagCompleter = completer1;

      // User requests 'top'
      final f1 = provider.fetchHashtagFeed('tech', sort: 'top');
      expect(provider.isHashtagLoading, isTrue);

      // User immediately switches to 'latest'
      final completer2 = Completer<List<PostModel>>();
      mockRepo.hashtagCompleter = completer2;
      final f2 = provider.fetchHashtagFeed('tech', sort: 'latest');

      // 'top' resolves late
      completer1.complete([
        PostModel(
          id: 999,
          userId: 1,
          content: 'Stale top post',
          type: PostType.post,
          createdAt: DateTime.now(),
        )
      ]);
      await Future.delayed(Duration.zero);

      // 'top' should be ignored
      expect(provider.hashtagPosts, isEmpty);

      // 'latest' resolves
      completer2.complete([
        PostModel(
          id: 111,
          userId: 1,
          content: 'Fresh latest post',
          type: PostType.post,
          createdAt: DateTime.now(),
        )
      ]);
      await Future.wait([f1, f2]);

      expect(provider.hashtagPosts.length, 1);
      expect(provider.hashtagPosts.first.content, 'Fresh latest post');
      expect(provider.isHashtagLoading, isFalse);
    });
  });
}
