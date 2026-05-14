import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart'; // Quan trọng nhất để có notifyListeners
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../data/repositories/post_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final IPostRepository _postRepository;

  Map<String, dynamic>? _userData;
  List<PostModel> _userPosts = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProfileProvider(this._postRepository);

  Map<String, dynamic>? get userData => _userData;
  List<PostModel> get userPosts => _userPosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile(String firebaseUid, {String? viewerUid}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _postRepository.getUserProfile(firebaseUid, viewerUid: viewerUid);
      _userData = result['user'];
      _userPosts = result['posts'];
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
      await _postRepository.updateProfile(
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

      final uploadTask = storageRef.putFile(File(image.path));
      
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
