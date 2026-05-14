import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../data/repositories/post_repository.dart';
import 'auth_provider.dart';

class HomeProvider extends ChangeNotifier {
  final IPostRepository _postRepository;
  final AuthProvider _authProvider; // Thêm AuthProvider

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  HomeProvider(this._postRepository, this._authProvider) {
    fetchFeed(); 
  }

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  // Logic pull to refresh
  Future<void> refreshFeed() async {
    await fetchFeed();
  }

  // Logic tạo bài viết mới hoặc Bình luận
  Future<bool> createPost({
    required String firebaseUid,
    required String content,
    int? parentId,
    String? type,
    List<Map<String, String>>? media,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _postRepository.createPost(
        firebaseUid: firebaseUid,
        content: content,
        parentId: parentId,
        type: type,
        media: media,
      );
      
      if (parentId == null) {
        // Đăng bài mới thì load lại toàn bộ feed
        await fetchFeed();
      } else {
        // Nếu là bình luận, cập nhật số lượng comment của bài viết đó trong UI cục bộ
        final index = _posts.indexWhere((p) => p.id == parentId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = post.copyWith(
            commentCount: (post.commentCount) + 1,
          );
        }
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logic thả tim bài viết - cập nhật local state ngay, không reload toàn bộ feed
  Future<bool> toggleLike(int postId, String firebaseUid) async {
    try {
      final isLiked = await _postRepository.toggleLike(
        postId: postId,
        firebaseUid: firebaseUid,
      );

      // Cập nhật local state trong feed list
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = post.copyWith(
          isLiked: isLiked,
          likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
        );
        notifyListeners();
      }
      return isLiked;
    } catch (e) {
      print('Lỗi toggleLike: $e');
      return false;
    }
  }

  // Lấy danh sách bình luận
  Future<List<PostModel>> getReplies(int postId) async {
    try {
      final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
      return await _postRepository.getReplies(postId, firebaseUid: firebaseUid);
    } catch (e) {
      print('Lỗi getReplies: $e');
      return [];
    }
  }
}
