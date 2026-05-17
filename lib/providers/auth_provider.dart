import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  User? _user;
  Map<String, dynamic>? _currentUserData;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authRepository) {
    // Chúng ta sẽ không gọi Firebase ngay trong constructor để tránh treo App lúc khởi động
    _initAuthListener();
  }

  void _initAuthListener() {
    // Đợi 1 chút cho Firebase khởi tạo xong rồi mới lắng nghe
    Future.delayed(const Duration(seconds: 1), () {
      try {
        _firebaseAuth.authStateChanges().listen((User? user) async {
          print('[AUTH] 🔄 Trạng thái Auth thay đổi: ${user?.email ?? 'Chưa đăng nhập'}');
          _user = user;
          
          if (user != null) {
            // Tự động khôi phục dữ liệu MySQL nếu đã login Firebase nhưng chưa có data local
            if (_currentUserData == null) {
              final mysqlUser = await _authRepository.getUserByFirebaseUid(user.uid);
              if (mysqlUser != null) {
                print('[AUTH] ✅ Đã tự động khôi phục dữ liệu MySQL cho: ${mysqlUser['username']}');
                _currentUserData = mysqlUser;
              }
            }
          } else {
            _currentUserData = null;
          }
          notifyListeners();
        });
      } catch (e) {
        print('⚠️ AuthListener gặp lỗi: $e');
      }
    });
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  Map<String, dynamic>? get currentUserData => _currentUserData;
  
  // Kiểm tra đăng nhập qua SDK HOẶC qua dữ liệu MySQL đã lưu
  bool get isAuthenticated => _user != null || _currentUserData != null;

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (password.length < 6) {
      _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      print('---------------------------------------');
      print('[AUTH] 🚀 Bắt đầu đăng ký qua Firebase SDK...');
      print('[AUTH] 📧 Email: $email');
      print('[AUTH] ⏰ Time: ${DateTime.now()}');

      // BƯỚC 1: Đăng ký qua Firebase SDK
      final Map<String, dynamic> result = await _authRepository.signUpWithSDK(
        email: email,
        password: password,
      );

      final String uid = result['localId'];

      print('[AUTH] ✅ Firebase UID: $uid');
      print('[AUTH] 🌐 Đang đồng bộ sang MySQL...');

      await _authRepository.registerUserToMySQL(
        uid: uid,
        email: email,
        username: username,
      );

      _currentUserData = {
        'firebase_uid': uid,
        'email': email,
        'username': username,
      };

      print('[AUTH] 🎉 Đăng ký hoàn tất!');

      _isLoading = false;
      notifyListeners();
      return true;

    } on Exception catch (e, stackTrace) {
      final errorMsg = e.toString();
      print('=================================');
      print('[AUTH][ERROR] $errorMsg');
      print('[AUTH] StackTrace: $stackTrace');
      print('=================================');

      if (errorMsg.contains('EMAIL_EXISTS')) {
        _errorMessage = 'Email này đã được sử dụng rồi!';
      } else if (errorMsg.contains('WEAK_PASSWORD')) {
        _errorMessage = 'Mật khẩu quá yếu (cần ít nhất 6 ký tự)!';
      } else if (errorMsg.contains('INVALID_EMAIL')) {
        _errorMessage = 'Địa chỉ email không hợp lệ!';
      } else {
        _errorMessage = 'Lỗi: $errorMsg';
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('---------------------------------------');
      print('[AUTH] 🔑 Bắt đầu đăng nhập Firebase SDK...');
      
      // BƯỚC 1: Đăng nhập Firebase SDK
      final Map<String, dynamic> result = await _authRepository.signInWithSDK(
        email: email,
        password: password,
      );

      final String uid = result['localId'];
      print('[AUTH] ✅ Firebase Login thành công. UID: $uid');

      // BƯỚC 2: Kiểm tra User trong MySQL
      final mysqlUser = await _authRepository.getUserByFirebaseUid(uid);
      
      if (mysqlUser != null) {
        print('[AUTH] ✅ Đã tìm thấy user trong MySQL: ${mysqlUser['username']}');
        _currentUserData = mysqlUser;
      } else {
        print('[AUTH] ⚠️ Không tìm thấy user trong MySQL (Có thể chưa đồng bộ)');
        // Nếu không có trong MySQL, tạo một object cơ bản để app không crash
        _currentUserData = {
          'firebase_uid': uid,
          'email': email,
          'username': 'User_$uid',
        };
      }

      _isLoading = false;
      notifyListeners();
      return true;

    } on Exception catch (e) {
      final errorMsg = e.toString();
      print('[AUTH] ❌ Lỗi đăng nhập: $errorMsg');
      
      if (errorMsg.contains('INVALID_LOGIN_CREDENTIALS') || errorMsg.contains('INVALID_PASSWORD')) {
        _errorMessage = 'Email hoặc mật khẩu không chính xác';
      } else if (errorMsg.contains('USER_NOT_FOUND')) {
        _errorMessage = 'Tài khoản không tồn tại';
      } else {
        _errorMessage = 'Lỗi: $errorMsg';
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _user = null;
    _currentUserData = null;
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
