import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

import '../utils/password_validator.dart';
import '../l10n/app_localizations.dart';

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
          _user = user;
          
          if (user != null) {
            // Tự động khôi phục dữ liệu MySQL nếu đã login Firebase nhưng chưa có data local
            if (_currentUserData == null) {
              final mysqlUser = await _authRepository.getUserByFirebaseUid(user.uid);
              if (mysqlUser != null) {
                _currentUserData = mysqlUser;
              }
            }
          } else {
            _currentUserData = null;
          }
          notifyListeners();
        });
      } catch (_) {}
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

    // 1. Client application-layer validation
    final passwordValidation = PasswordValidator.validate(password);
    if (!passwordValidation.isValid) {
      _errorMessage = passwordValidation.errors.first;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (nickname.isEmpty) {
      _errorMessage = AppLocalizations.current.pleaseEnterFullName;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // BƯỚC 1: Đăng ký qua Firebase SDK (Source of Truth)
      final Map<String, dynamic> result = await _authRepository.signUpWithSDK(
        email: email,
        password: password,
      );

      final String uid = result['localId'];

      // BƯỚC 2: Backend registration & final password validation
      Map<String, dynamic>? mysqlUserData;
      try {
        mysqlUserData = await _authRepository.registerUserToMySQL(
          uid: uid,
          email: email,
          username: nickname,
          nickname: nickname,
          password: password,
        );
      } on BackendPolicyException catch (e) {
        // TRƯỜNG HỢP 2: HTTP 400 (Explicit Policy Rejection trước khi ghi DB)
        // Kích hoạt Safe Rollback xoá Firebase user vừa tạo để tránh tài khoản mồ côi
        try {
          await _authRepository.deleteCurrentFirebaseUser();
        } catch (delError) {
          // Log phi nhạy cảm: tuyệt đối không log password
          debugPrint('[AuthRollback] Warning: Could not delete orphan Firebase user ($uid): $delError');
        }
        _currentUserData = null;
        _errorMessage = e.errors.isNotEmpty ? e.errors.join('\n') : e.message;
        _isLoading = false;
        notifyListeners();
        return false;
      } on EmailConflictException catch (e) {
        // TRƯỜNG HỢP 2B: HTTP 409 (Email Conflict với tài khoản khác)
        try {
          await _authRepository.deleteCurrentFirebaseUser();
        } catch (delError) {
          debugPrint('[AuthRollback] Warning: Could not delete orphan Firebase user ($uid): $delError');
        }
        _currentUserData = null;
        _errorMessage = e.message;
        _isLoading = false;
        notifyListeners();
        return false;
      } on ServerUncertainException {
        // TRƯỜNG HỢP 3: HTTP 500 / Timeout / Rớt mạng (Uncertain state)
        // TUYỆT ĐỐI KHÔNG XÓA MÙ QUÁNG TÀI KHOẢN FIREBASE!
        // Thực hiện RECONCILIATION:
        final existingUser = await _authRepository.getUserByFirebaseUid(uid);
        if (existingUser != null) {
          // 3A: MySQL thực tế đã lưu thành công!
          mysqlUserData = existingUser;
        } else {
          // 3B: Chưa có trong MySQL hoặc server chưa phục hồi
          // Giữ Firebase an toàn, signOut phiên tạm thời để retry/recover theo cùng firebase_uid
          await _authRepository.signOut();
          _currentUserData = null;
          _errorMessage = AppLocalizations.current.cannotConnectServerCompleteRegistration;
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _currentUserData = mysqlUserData ?? {
        'firebase_uid': uid,
        'email': email,
        'nickname': nickname,
        'username': nickname,
      };

      _isLoading = false;
      notifyListeners();
      return true;

    } on Exception catch (e) {
      final errorMsg = e.toString();

      // Mapping lỗi Firebase thân thiện với người dùng
      if (errorMsg.contains('EMAIL_EXISTS')) {
        _errorMessage = AppLocalizations.current.emailAlreadyInUse;
      } else if (errorMsg.contains('WEAK_PASSWORD')) {
        _errorMessage = AppLocalizations.current.weakPassword;
      } else if (errorMsg.contains('INVALID_EMAIL')) {
        _errorMessage = AppLocalizations.current.invalidEmailFormat;
      } else {
        _errorMessage = '${AppLocalizations.current.failure}: $errorMsg';
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
      // BƯỚC 1: Đăng nhập Firebase SDK
      final Map<String, dynamic> result = await _authRepository.signInWithSDK(
        email: email,
        password: password,
      );

      final String uid = result['localId'];

      // BƯỚC 2: Kiểm tra User trong MySQL
      final mysqlUser = await _authRepository.getUserByFirebaseUid(uid);
      
      if (mysqlUser != null) {
        _currentUserData = mysqlUser;
      } else {
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
      
      if (errorMsg.contains('INVALID_LOGIN_CREDENTIALS') || errorMsg.contains('INVALID_PASSWORD')) {
        _errorMessage = AppLocalizations.current.invalidCredentials;
      } else if (errorMsg.contains('USER_NOT_FOUND')) {
        _errorMessage = AppLocalizations.current.accountNotFound;
      } else {
        _errorMessage = '${AppLocalizations.current.failure}: $errorMsg';
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

      // Nếu người dùng đóng popup/hủy đăng nhập -> Dừng xoay loading ngay và trả về bình thường, không báo lỗi
      if (result == null) {
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return false;
      }

      final String uid = result['localId'];
      final String email = result['email'] ?? '';
      final String displayName = result['displayName'] ?? email.split('@').first;

      // Kiểm tra user trong MySQL
      final mysqlUser = await _authRepository.getUserByFirebaseUid(uid);

      if (mysqlUser != null) {
        // User đã tồn tại → load data MySQL
        _currentUserData = mysqlUser;
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
        } catch (_) {
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
      final errorStr = e.toString().replaceAll('Exception: ', '');
      final lower = errorStr.toLowerCase();
      // Nếu là thông báo đóng popup, không lưu vào errorMessage
      if (lower.contains('popup has been closed') ||
          lower.contains('closed by the user') ||
          lower.contains('canceled') ||
          lower.contains('cancelled')) {
        _errorMessage = null;
      } else {
        _errorMessage = errorStr;
      }
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
      final errStr = e.toString().toUpperCase();
      if (errStr.contains('EMAIL_NOT_FOUND') || errStr.contains('USER_NOT_FOUND')) {
        _errorMessage = AppLocalizations.current.accountNotFoundForEmail;
      } else if (errStr.contains('OAUTH_ACCOUNT') || errStr.contains('OPERATION_NOT_ALLOWED')) {
        _errorMessage = AppLocalizations.current.googleAccountSignInPrompt;
      } else if (errStr.contains('INVALID_EMAIL')) {
        _errorMessage = AppLocalizations.current.invalidEmailFormat;
      } else if (errStr.contains('TOO_MANY_REQUESTS')) {
        _errorMessage = AppLocalizations.current.tooManyRequests;
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Gửi mã xác thực OTP 6 số qua email (100% trong App)
  Future<bool> sendForgotPasswordOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.sendForgotPasswordOtp(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Xác thực mã OTP 6 số từ người dùng
  Future<bool> verifyForgotPasswordOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.verifyForgotPasswordOtp(email, otp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đặt lại mật khẩu mới bằng OTP kèm kiểm tra 7 quy tắc bảo mật
  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // 1. Kiểm tra 7 quy tắc bảo mật
      final validation = PasswordValidator.validate(newPassword);
      if (!validation.isValid) {
        _errorMessage = validation.errors.first;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _authRepository.resetPasswordWithOtp(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đổi mật khẩu cho người dùng đang đăng nhập (in-app qua Firebase)
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (currentPassword == newPassword) {
        _errorMessage = AppLocalizations.current.passwordCannotMatchOld;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 1. Kiểm tra 7 quy tắc bảo mật
      final validation = PasswordValidator.validate(newPassword);
      if (!validation.isValid) {
        _errorMessage = validation.errors.first;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _authRepository.changePasswordLoggedIn(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('mật khẩu hiện tại') || errStr.contains('wrong-password') || errStr.contains('invalid_login_credentials')) {
        _errorMessage = AppLocalizations.current.currentPasswordIncorrect;
      } else if (errStr.contains('hết hạn') || errStr.contains('requires-recent-login')) {
        _errorMessage = AppLocalizations.current.sessionExpiredReLogin;
      } else if (errStr.contains('google')) {
        _errorMessage = AppLocalizations.current.googleAccountNoPassword;
      } else if (errStr.contains('không đủ mạnh') || errStr.contains('weak-password')) {
        _errorMessage = AppLocalizations.current.weakPassword;
      } else {
        _errorMessage = AppLocalizations.current.changePasswordFailure;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

