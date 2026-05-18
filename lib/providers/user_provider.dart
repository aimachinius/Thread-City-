import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../data/repositories/post_repository.dart';
import '../data/repositories/user_repository.dart';


class UserProvider extends ChangeNotifier {
  final IUserRepository _userRepository;
  final IPostRepository _postRepository;

  Map<String, dynamic>? _userData;
  List<PostModel> _userPosts = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserProvider(this._userRepository, this._postRepository);

  Map<String, dynamic>? get userData => _userData;
  List<PostModel> get userPosts => _userPosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearData() {
    _userData = null;
    _userPosts = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchProfile(String firebaseUid, {String? viewerUid}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi song song hoặc tuần tự để lấy thông tin Profile và Bài viết riêng biệt
      final userResult = await _userRepository.getUserProfile(firebaseUid);
      final postsResult = await _postRepository.getPostsByUserUid(firebaseUid, viewerUid: viewerUid);
      
      _userData = userResult;
      _userPosts = postsResult;
    } catch (e) {
      _userData = null;
      _userPosts = [];
      _errorMessage = 'Không thể tải thông tin cá nhân. Vui lòng thử lại.';
      print('Lỗi fetchProfile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getProfileDataOnly(String firebaseUid, {String? viewerUid}) async {
    try {
      return await _userRepository.getUserProfile(firebaseUid, viewerUid: viewerUid);
    } catch (e) {
      print('Lỗi getProfileDataOnly: $e');
      return null;
    }
  }

  Future<List<PostModel>> getUserPostsOnly(String firebaseUid, {String? viewerUid}) async {
    try {
      return await _postRepository.getPostsByUserUid(firebaseUid, viewerUid: viewerUid);
    } catch (e) {
      print('Lỗi getUserPostsOnly: $e');
      return [];
    }
  }

  Future<bool> followUser({required String followerUid, required int followingId}) async {
    try {
      await _userRepository.followUser(followerUid: followerUid, followingId: followingId);
      return true;
    } catch (e) {
      print('Lỗi followUser: $e');
      return false;
    }
  }

  Future<bool> unfollowUser({required String followerUid, required int followingId}) async {
    try {
      await _userRepository.unfollowUser(followerUid: followerUid, followingId: followingId);
      return true;
    } catch (e) {
      print('Lỗi unfollowUser: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    required String firebaseUid,
    String? bio,
    String? avatarUrl,
    String? nickname,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _userRepository.updateProfile(
        firebaseUid: firebaseUid,
        bio: bio,
        avatarUrl: avatarUrl,
        nickname: nickname,
      );
      
      // Sau khi update thành công, tải lại profile để cập nhật UI
      await fetchProfile(firebaseUid, viewerUid: firebaseUid);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật thông tin. Vui lòng thử lại.';
      print('Lỗi updateProfile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> pickAndUploadAvatar(String firebaseUid) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return false;

      _isLoading = true;
      notifyListeners();

      // 1. Tải lên Firebase Storage qua SDK gốc
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('$firebaseUid.jpg');

      final uploadTask = storageRef.putFile(File(image.path));
      
      // Chờ quá trình upload hoàn tất trực tiếp và an toàn
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('[STORAGE] 🎉 Tải ảnh lên thành công. URL: $downloadUrl');

      // 2. Cập nhật vào MySQL
      return await updateProfile(
        firebaseUid: firebaseUid,
        avatarUrl: downloadUrl,
      );
    } catch (e) {
      _errorMessage = 'Lỗi tải ảnh lên: $e';
      print('Lỗi upload avatar chi tiết: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _userData = null;
    _userPosts = [];
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getUserFollowers(String userId) async {
    try {
      return await _userRepository.getUserFollowers(userId);
    } catch (e) {
      print('Lỗi getUserFollowers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserFollowing(String userId) async {
    try {
      return await _userRepository.getUserFollowing(userId);
    } catch (e) {
      print('Lỗi getUserFollowing: $e');
      return [];
    }
  }

  /// Cập nhật trạng thái thả tim cục bộ trên danh sách bài đăng của User
  void updatePostLike(int postId, bool isLiked) {
    final index = _userPosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _userPosts[index];
      _userPosts[index] = post.copyWith(
        isLiked: isLiked,
        likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
      );
      notifyListeners();
    }
  }

  /// Tăng số lượng bình luận cục bộ trên danh sách bài đăng của User
  void incrementCommentCount(int postId) {
    final index = _userPosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _userPosts[index];
      _userPosts[index] = post.copyWith(
        commentCount: post.commentCount + 1,
      );
      notifyListeners();
    }
  }
}
