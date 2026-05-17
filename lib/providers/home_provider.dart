import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../data/repositories/post_repository.dart';
import 'auth_provider.dart';

class HomeProvider extends ChangeNotifier {
  final IPostRepository _postRepository;
  final AuthProvider _authProvider;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  HomeProvider(this._postRepository, this._authProvider) {
    fetchFeed(); 
  }

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearData() {
    _posts = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchFeed() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
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

  /// Cập nhật trạng thái thả tim cục bộ trên danh sách bảng tin
  void updatePostLike(int postId, bool isLiked) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(
        isLiked: isLiked,
        likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
      );
      notifyListeners();
    }
  }

  /// Tăng số lượng bình luận cục bộ trên danh sách bảng tin
  void incrementCommentCount(int postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(
        commentCount: post.commentCount + 1,
      );
      notifyListeners();
    }
  }
}
