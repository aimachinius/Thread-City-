import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart'; // Quan trọng nhất để có notifyListeners
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../data/repositories/post_repository.dart';
import '../data/repositories/user_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final IUserRepository _userRepository;
  final IPostRepository _postRepository;

  Map<String, dynamic>? _userData;
  List<PostModel> _userPosts = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProfileProvider(this._userRepository, this._postRepository);

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
      _errorMessage = 'Không thể tải thông tin cá nhân. Vui lòng thử lại.';
      print('Lỗi fetchProfile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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

      // 1. Tải lên Firebase Storage qua SDK gốc (Không dùng ẩn danh nữa vì Firebase của bạn đang tắt tính năng này)
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('$firebaseUid.jpg');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final mimeType = image.mimeType ?? 'image/jpeg';
        uploadTask = storageRef.putData(
          bytes, 
          SettableMetadata(contentType: mimeType)
        );
      } else {
        uploadTask = storageRef.putFile(File(image.path));
      }
      
      // Chờ quá trình upload hoàn tất
      final snapshot = await uploadTask.whenComplete(() => null);
      
      // Kiểm tra xem Firebase Storage có chặn upload không (do luật bảo mật)
      if (snapshot.state == TaskState.error) {
        throw Exception('Firebase Storage từ chối lưu file. Hãy kiểm tra lại Rules.');
      }
      
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Cập nhật vào MySQL (thông qua updateProfile)
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
}
