import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../data/repositories/post_repository.dart';
import 'auth_provider.dart';

class PostProvider extends ChangeNotifier {
  final IPostRepository _postRepository;
  final AuthProvider _authProvider;

  bool _isLoading = false;
  String? _errorMessage;

  PostProvider(this._postRepository, this._authProvider);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleLike(int postId, String firebaseUid) async {
    try {
      final isLiked = await _postRepository.toggleLike(
        postId: postId,
        firebaseUid: firebaseUid,
      );
      return isLiked;
    } catch (e) {
      print('Lỗi toggleLike: $e');
      return false;
    }
  }

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
