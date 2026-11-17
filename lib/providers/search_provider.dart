import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:thread_app/data/repositories/search_repository.dart';
import 'package:thread_app/models/post_model.dart';
import 'package:thread_app/models/search_result_model.dart';
import 'package:thread_app/providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

class SearchProvider extends ChangeNotifier {
  final ISearchRepository _searchRepository;
  final AuthProvider? _authProvider;

  String _currentQuery = '';
  String _activeTab = 'all';

  SearchResultModel? _searchResult;
  bool _isSearching = false;
  String? _searchError;

  List<TrendingHashtagModel> _trending = [];
  bool _isTrendingLoading = false;

  List<PostModel> _hashtagFeed = [];
  bool _isHashtagFeedLoading = false;
  String? _hashtagError;
  String? _activeHashtag;
  String _hashtagSort = 'latest';

  int _searchGeneration = 0;
  int _hashtagFeedGeneration = 0;
  Timer? _debounceTimer;

  final Set<int> _followLoadingUserIds = {};

  SearchProvider({
    required ISearchRepository searchRepository,
    AuthProvider? authProvider,
  })  : _searchRepository = searchRepository,
        _authProvider = authProvider;

  bool isFollowLoading(int userId) => _followLoadingUserIds.contains(userId);

  void onQueryChanged(String query) {
    _currentQuery = query;
    _debounceTimer?.cancel();
    _searchGeneration++; // Invalidate ngay lập tức request đang chạy của query cũ

    if (query.trim().length < 2) {
      _searchResult = null;
      _isSearching = false;
      _searchError = null;
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _doSearch(query);
    });
  }

  void clearSearch() {
    _currentQuery = '';
    _debounceTimer?.cancel();
    _searchGeneration++;
    _searchResult = null;
    _isSearching = false;
    _searchError = null;
    notifyListeners();
  }

  void setActiveTab(String tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _debounceTimer?.cancel();
    _searchGeneration++; // Invalidate request của tab cũ ngay lập tức
    notifyListeners();
    if (_currentQuery.trim().length >= 2) {
      _doSearch(_currentQuery);
    }
  }

  Future<void> _doSearch(String query) async {
    final generation = ++_searchGeneration;
    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      final result = await _searchRepository.search(
        query: query,
        type: _activeTab,
        viewerUid: _authProvider?.currentUserData?['firebase_uid'],
      );
      if (generation != _searchGeneration) return;
      _searchResult = result;
    } catch (e) {
      if (generation != _searchGeneration) return;
      _searchError = AppLocalizations.current.failedToSearch;
    } finally {
      if (generation == _searchGeneration) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchHashtagFeed(String tag, {String sort = 'latest'}) async {
    _activeHashtag = tag;
    _hashtagSort = sort;
    final generation = ++_hashtagFeedGeneration;
    _isHashtagFeedLoading = true;
    _hashtagError = null;
    notifyListeners();

    try {
      final posts = await _searchRepository.getPostsByHashtag(
        tag,
        sort: sort,
        viewerUid: _authProvider?.currentUserData?['firebase_uid'],
      );
      if (generation != _hashtagFeedGeneration) return;
      _hashtagFeed = posts;
    } catch (_) {
      if (generation != _hashtagFeedGeneration) return;
      _hashtagError = AppLocalizations.current.failedToLoadHashtagPosts;
    } finally {
      if (generation == _hashtagFeedGeneration) {
        _isHashtagFeedLoading = false;
        notifyListeners();
      }
    }
  }

  void setHashtagSort(String sort) {
    if (_hashtagSort == sort) return;
    _hashtagSort = sort;
    notifyListeners();
    if (_activeHashtag != null) {
      fetchHashtagFeed(_activeHashtag!, sort: sort);
    }
  }

  Future<void> toggleFollowUser({
    required int userId,
    required Future<void> Function(int userId, bool newStatus) apiCall,
  }) async {
    if (_followLoadingUserIds.contains(userId)) return;

    UserSearchModel? currentUser;
    if (_searchResult != null) {
      for (final u in _searchResult!.users) {
        if (u.id == userId) {
          currentUser = u;
          break;
        }
      }
    }
    if (currentUser == null) return;

    final newStatus = !currentUser.isFollowing;
    _followLoadingUserIds.add(userId);

    // Optimistic UI update
    updateUserFollowStatus(userId, newStatus);

    try {
      await apiCall(userId, newStatus);
    } catch (e) {
      updateUserFollowStatus(userId, !newStatus);
    } finally {
      _followLoadingUserIds.remove(userId);
      notifyListeners();
    }
  }

  void updateUserFollowStatus(int userId, bool isFollowing) {
    if (_searchResult == null) return;
    final updatedUsers = _searchResult!.users.map((user) {
      if (user.id == userId) {
        if (user.isFollowing == isFollowing) return user;
        return user.copyWith(
          isFollowing: isFollowing,
          followerCount: isFollowing 
            ? user.followerCount + 1 
            : (user.followerCount > 0 ? user.followerCount - 1 : 0),
        );
      }
      return user;
    }).toList();

    _searchResult = _searchResult!.copyWith(users: updatedUsers);
    notifyListeners();
  }

  String? _trendingError;

  Future<void> fetchTrending({bool force = false}) async {
    if (_trending.isNotEmpty && !force && !_isTrendingLoading) return;
    _isTrendingLoading = true;
    _trendingError = null;
    notifyListeners();
    try {
      _trending = await _searchRepository.getTrendingHashtags();
    } catch (_) {
      _trendingError = AppLocalizations.current.failedToLoadTrending;
    } finally {
      _isTrendingLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Getters
  String get currentQuery => _currentQuery;
  String get activeTab => _activeTab;
  String get hashtagSort => _hashtagSort;
  List<PostModel> get hashtagFeed => _hashtagFeed;
  List<PostModel> get hashtagPosts => _hashtagFeed;
  SearchResultModel? get searchResult => _searchResult;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  String? get hashtagError => _hashtagError;
  String? get trendingError => _trendingError;
  List<TrendingHashtagModel> get trending => _trending;
  bool get isTrendingLoading => _isTrendingLoading;
  bool get isHashtagFeedLoading => _isHashtagFeedLoading;
  bool get isHashtagLoading => _isHashtagFeedLoading;
}
