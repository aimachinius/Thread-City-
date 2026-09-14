import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../data/repositories/post_repository.dart';
import 'auth_provider.dart';

class HomeProvider extends ChangeNotifier {
  final IPostRepository _postRepository;
  final AuthProvider _authProvider;
  String? _lastFetchedUid;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PostModel> _followingPosts = [];
  bool _isFollowingLoading = false;
  String? _followingErrorMessage;

  HomeProvider(this._postRepository, this._authProvider) {
    // BUG-03 FIX: Listen auth changes → refresh feed khi user đăng nhập xong
    _authProvider.addListener(_onAuthChanged);
    fetchFeed();
    fetchFollowingFeed();
  }

  /// Gọi khi AuthProvider có thay đổi
  void _onAuthChanged() {
    final currentUid = _authProvider.currentUserData?['firebase_uid'];
    // Chỉ refresh khi UID thực sự thay đổi (tránh gọi lại vô ích)
    if (currentUid != _lastFetchedUid) {
      fetchFeed();
      fetchFollowingFeed();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }


  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PostModel> get followingPosts => _followingPosts;
  bool get isFollowingLoading => _isFollowingLoading;
  String? get followingErrorMessage => _followingErrorMessage;

  void clearData() {
    _posts = [];
    _followingPosts = [];
    _errorMessage = null;
    _followingErrorMessage = null;
    notifyListeners();
  }

  Future<void> fetchFeed() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
      _lastFetchedUid = firebaseUid; // Lưu UID đã fetch để tránh gọi lại trùng
      _posts = await _postRepository.getFeed(firebaseUid: firebaseUid);
    } catch (e) {
      _errorMessage = 'Không thể tải bảng tin. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFeed() async {
    await fetchFeed();
  }

  Future<void> fetchFollowingFeed() async {
    _isFollowingLoading = true;
    _followingErrorMessage = null;
    notifyListeners();

    try {
      final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
      _followingPosts = await _postRepository.getFeed(
        firebaseUid: firebaseUid,
        following: true,
      );
    } catch (e) {
      _followingErrorMessage = 'Không thể tải bảng tin đang theo dõi.';
    } finally {
      _isFollowingLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFollowingFeed() async {
    await fetchFollowingFeed();
  }

  /// Cập nhật trạng thái thả tim cục bộ trên danh sách bảng tin (đồng bộ cả 2 list)
  void updatePostLike(int postId, bool isLiked) {
    bool changed = false;

    // 1. Update For You posts
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(
        isLiked: isLiked,
        likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
      );
      changed = true;
    }

    // 2. Update Following posts
    final followingIndex = _followingPosts.indexWhere((p) => p.id == postId);
    if (followingIndex != -1) {
      final post = _followingPosts[followingIndex];
      _followingPosts[followingIndex] = post.copyWith(
        isLiked: isLiked,
        likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
      );
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void updatePostRepost(int postId, bool isReposted) {
    bool changed = false;

    // 1. Update For You posts
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(
        isReposted: isReposted,
        repostCount: isReposted ? post.repostCount + 1 : post.repostCount - 1,
      );
      changed = true;
    }

    // 2. Update Following posts
    final followingIndex = _followingPosts.indexWhere((p) => p.id == postId);
    if (followingIndex != -1) {
      final post = _followingPosts[followingIndex];
      _followingPosts[followingIndex] = post.copyWith(
        isReposted: isReposted,
        repostCount: isReposted ? post.repostCount + 1 : post.repostCount - 1,
      );
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Tăng số lượng bình luận cục bộ trên danh sách bảng tin (đồng bộ cả 2 list)
  void incrementCommentCount(int postId) {
    bool changed = false;

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(
        commentCount: post.commentCount + 1,
      );
      changed = true;
    }

    final followingIndex = _followingPosts.indexWhere((p) => p.id == postId);
    if (followingIndex != -1) {
      final post = _followingPosts[followingIndex];
      _followingPosts[followingIndex] = post.copyWith(
        commentCount: post.commentCount + 1,
      );
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }
}
