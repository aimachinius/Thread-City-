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
    required String firstName,
    required String lastName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final nickname = '$firstName $lastName'.trim();

    if (password.length < 6) {
      _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    if (nickname.isEmpty) {
      _errorMessage = 'Vui lòng nhập họ và tên';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      debugPrint('---------------------------------------');
      debugPrint('[AUTH] 🚀 Bắt đầu đăng ký qua Firebase SDK...');

      // BƯỚC 1: Đăng ký qua Firebase SDK
      final Map<String, dynamic> result = await _authRepository.signUpWithSDK(
        email: email,
        password: password,
      );

      final String uid = result['localId'];
      debugPrint('[AUTH] ✅ Firebase UID: $uid');

      // BƯỚC 2: Đồng bộ sang MySQL — nếu fail vẫn cho vào app
      bool mysqlOk = false;
      String? mysqlWarning;
      try {
        debugPrint('[AUTH] 🌐 Đang đồng bộ sang MySQL...');
        await _authRepository.registerUserToMySQL(
          uid: uid,
          email: email,
          username: nickname, // Placeholder; server sẽ sinh username thực từ nickname
          nickname: nickname,
        );
        mysqlOk = true;
        debugPrint('[AUTH] 🎉 Đăng ký hoàn tất!');
      } catch (mysqlError) {
        // Firebase đã tạo user thành công, nhưng MySQL thất bại
        // → Vẫn cho vào app, hiện cảnh báo thay vì block
        debugPrint('[AUTH] ⚠️ MySQL sync thất bại: $mysqlError');
        mysqlWarning = 'Tạo tài khoản thành công nhưng server đang bận. '
            'Một số tính năng có thể bị giới hạn tạm thời.';
      }

      // Thiết lập data local dù MySQL fail hay không
      _currentUserData = {
        'firebase_uid': uid,
        'email': email,
        'nickname': nickname,
        'username': nickname, // Sẽ bị ghi đè bởi auth listener khi MySQL sync xong
        'mysql_synced': mysqlOk,
      };

      if (mysqlWarning != null) {
        _errorMessage = mysqlWarning; // Dùng như warning, không block login
      }

      _isLoading = false;
      notifyListeners();
      return true; // ✅ Luôn trả true nếu Firebase ok

    } on Exception catch (e, stackTrace) {
      final errorMsg = e.toString();
      debugPrint('=================================');
      debugPrint('[AUTH][ERROR] $errorMsg');
      debugPrint('[AUTH] StackTrace: $stackTrace');
      debugPrint('=================================');

      // Lỗi này chỉ từ Firebase (email tồn tại, mật khẩu yếu,...)
      if (errorMsg.contains('EMAIL_EXISTS')) {
        _errorMessage = 'Email này đã được sử dụng rồi!';
      } else if (errorMsg.contains('WEAK_PASSWORD')) {
        _errorMessage = 'Mật khẩu quá yếu (cần ít nhất 6 ký tự)!';
      } else if (errorMsg.contains('INVALID_EMAIL')) {
        _errorMessage = 'Địa chỉ email không hợp lệ!';
      } else {
        _errorMessage = 'Lỗi đăng ký: $errorMsg';
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
        debugPrint('[AUTH] ✅ Đã tìm thấy user trong MySQL: ${mysqlUser['username']}');
        _currentUserData = mysqlUser;
      } else {
        debugPrint('[AUTH] ⚠️ Không tìm thấy user trong MySQL (Có thể chưa đồng bộ)');
        // Fallback: dùng phần trước @ của email thay vì uid xấu
        final emailPrefix = email.split('@').first;
        _currentUserData = {
          'firebase_uid': uid,
          'email': email,
          'username': emailPrefix,
          'nickname': emailPrefix,
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

  /// Đăng nhập / Đăng ký bằng Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.signInWithGoogle();
      final String uid = result['localId'];
      final String email = result['email'] ?? '';
      final String displayName = result['displayName'] ?? email.split('@').first;
      final bool isNewUser = result['isNewUser'] ?? false;

      debugPrint('[AUTH] Google UID: $uid, isNew: $isNewUser, name: $displayName');

      // Kiểm tra user trong MySQL
      final mysqlUser = await _authRepository.getUserByFirebaseUid(uid);

      if (mysqlUser != null) {
        // User đã tồn tại → load data MySQL
        _currentUserData = mysqlUser;
        debugPrint('[AUTH] ✅ Google user đã có trong MySQL');
      } else {
        // User mới → đăng ký vào MySQL với displayName làm nickname
        try {
          await _authRepository.registerUserToMySQL(
            uid: uid,
            email: email,
            username: displayName,    // Server sẽ sinh username từ nickname
            nickname: displayName,
          );
          // Reload sau khi đăng ký
          final newMysqlUser = await _authRepository.getUserByFirebaseUid(uid);
          _currentUserData = newMysqlUser ?? {
            'firebase_uid': uid,
            'email': email,
            'nickname': displayName,
            'username': displayName.replaceAll(' ', '').toLowerCase(),
          };
        } catch (regError) {
          debugPrint('[AUTH] ⚠️ MySQL sync thất bại: $regError');
          _currentUserData = {
            'firebase_uid': uid,
            'email': email,
            'nickname': displayName,
            'username': email.split('@').first,
          };
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;

    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('[AUTH] ❌ Google Sign-In lỗi: $_errorMessage');
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
