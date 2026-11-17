import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;

class BackendPolicyException implements Exception {
  final String message;
  final List<String> errors;
  BackendPolicyException(this.message, {this.errors = const []});

  @override
  String toString() => errors.isNotEmpty ? '$message: ${errors.join(', ')}' : message;
}

class EmailConflictException implements Exception {
  final String message;
  EmailConflictException(this.message);

  @override
  String toString() => message;
}

class ServerUncertainException implements Exception {
  final String message;
  ServerUncertainException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final String authUrl;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  AuthRepository(this.authUrl);

  /// Đăng nhập / Đăng ký bằng Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      UserCredential userCredential;
      if (kIsWeb) {
        // Web: dùng Popup
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // Mobile: dùng redirect
        userCredential = await _firebaseAuth.signInWithProvider(googleProvider);
      }

      final user = userCredential.user!;

      return {
        'localId': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
      };
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Đăng nhập Google thất bại');
    } catch (e) {
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  /// Đăng ký bằng Firebase SDK
  Future<Map<String, dynamic>> signUpWithSDK({
    required String email,
    required String password,
  }) async {
    /* --- BACKUP REST API (Dùng nếu SDK bị lỗi) ---
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_firebaseApiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error']['message'] ?? 'Lỗi đăng ký REST');
    }
    return data;
    ----------------------------------------------- */

    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return {
        'localId': userCredential.user?.uid,
        'email': userCredential.user?.email,
      };
    } on FirebaseAuthException catch (e) {
      String errorCode = e.code.toUpperCase().replaceAll('-', '_');
      // Mapping để tương thích với Provider đang dùng REST API codes
      if (errorCode == 'EMAIL_ALREADY_IN_USE') errorCode = 'EMAIL_EXISTS';
      
      throw Exception(errorCode);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Đăng nhập bằng Firebase SDK
  Future<Map<String, dynamic>> signInWithSDK({
    required String email,
    required String password,
  }) async {
    /* --- BACKUP REST API (Dùng nếu SDK bị lỗi) ---
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_firebaseApiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error']['message'] ?? 'Lỗi đăng nhập REST');
    }
    return data;
    ----------------------------------------------- */

    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return {
        'localId': userCredential.user?.uid,
        'email': userCredential.user?.email,
      };
    } on FirebaseAuthException catch (e) {
      String errorCode = e.code.toUpperCase().replaceAll('-', '_');
      // Mapping để tương thích với Provider
      if (errorCode == 'USER_NOT_FOUND') errorCode = 'EMAIL_NOT_FOUND';
      if (errorCode == 'WRONG_PASSWORD') errorCode = 'INVALID_PASSWORD';

      throw Exception(errorCode);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Gửi email đặt lại mật khẩu qua Firebase Auth
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );
      debugPrint('[Auth] Password reset email sent to: ${email.trim()}');
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Firebase reset error: ${e.code} - ${e.message}');
      String errorCode = e.code.toUpperCase().replaceAll('-', '_');
      if (errorCode == 'USER_NOT_FOUND') errorCode = 'EMAIL_NOT_FOUND';
      if (errorCode == 'OPERATION_NOT_ALLOWED') errorCode = 'OAUTH_ACCOUNT';
      throw Exception(errorCode);
    } catch (e) {
      debugPrint('[Auth] Unexpected reset error: $e');
      throw Exception(e.toString());
    }
  }

  /// Gửi mã xác nhận OTP 6 số vào email (qua backend)
  Future<Map<String, dynamic>> sendForgotPasswordOtp(String email) async {
    final url = Uri.parse('$authUrl/forgot-password/send-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      debugPrint('[Auth] Lỗi gửi OTP: ${data['message']}');
      throw Exception(data['message'] ?? 'Không thể gửi mã OTP');
    }

    return data;
  }

  /// Xác thực mã OTP 6 số (qua backend)
  Future<Map<String, dynamic>> verifyForgotPasswordOtp(String email, String otp) async {
    final url = Uri.parse('$authUrl/forgot-password/verify-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'otp': otp.trim(),
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Mã OTP không chính xác');
    }
    return data;
  }

  /// Đặt lại mật khẩu mới bằng mã OTP đã xác thực (qua backend + Firebase Admin)
  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse('$authUrl/forgot-password/reset');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      if (data['errors'] != null && data['errors'] is List) {
        throw BackendPolicyException(
          data['message'] ?? 'Mật khẩu không thỏa mãn chính sách',
          errors: List<String>.from(data['errors']),
        );
      }
      throw Exception(data['message'] ?? 'Không thể đặt lại mật khẩu');
    }
    return data;
  }

  /// Đổi mật khẩu cho người dùng đang đăng nhập (in-app qua Firebase Auth SDK)
  Future<void> changePasswordLoggedIn({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    final isGoogleOnly = user.providerData.any((p) => p.providerId == 'google.com') &&
        !user.providerData.any((p) => p.providerId == 'password');
    if (isGoogleOnly) {
      throw Exception('Tài khoản này liên kết với Google, không sử dụng mật khẩu riêng.');
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      // Xác thực lại mật khẩu cũ
      await user.reauthenticateWithCredential(cred);
      // Đổi mật khẩu mới
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      String code = e.code.toUpperCase().replaceAll('-', '_');
      if (code == 'WRONG_PASSWORD' || code == 'INVALID_LOGIN_CREDENTIALS') {
        throw Exception('Mật khẩu hiện tại không chính xác');
      } else if (code == 'REQUIRES_RECENT_LOGIN') {
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để đổi mật khẩu.');
      } else if (code == 'WEAK_PASSWORD') {
        throw Exception('Mật khẩu mới không đủ mạnh.');
      }
      throw Exception(e.message ?? 'Đổi mật khẩu thất bại');
    }
  }


  /* --- BACKUP REST API (Dùng nếu SDK bị lỗi Timeout trên Android 15) ---
  Future<Map<String, dynamic>> registerWithFirebaseREST({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_firebaseApiKey');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> loginWithFirebaseREST({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_firebaseApiKey');
    final response = await http.post(url, headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
    );
    return jsonDecode(response.body);
  }
  --------------------------------------------------------------------- */

  /// Lấy thông tin user từ MySQL theo firebase_uid (có retry 1 lần khi timeout)
  Future<Map<String, dynamic>?> getUserByFirebaseUid(String uid) async {
    final url = Uri.parse('$authUrl/by-uid/$uid');

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
        return null;
      } catch (e) {
        if (attempt == 2) {
          return null;
        }
        // Lần 1 timeout → đợi 2 giây rồi thử lại (server có thể đang wake up)
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> registerUserToMySQL({
    required String uid,
    required String email,
    required String username,
    String? nickname,
    String? password,
  }) async {
    final url = Uri.parse('$authUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'firebase_uid': uid,
          'email': email,
          'username': username,
          if (nickname != null) 'nickname': nickname,
          if (password != null) 'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      // 201 = mới tạo, 200 = đã tồn tại (idempotent)
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'] as Map<String, dynamic>?;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final msg = errorData['message'] as String? ?? 'Mật khẩu không thỏa mãn chính sách bảo mật';
        final rawErrors = errorData['errors'];
        final errors = rawErrors is List ? rawErrors.map((e) => e.toString()).toList() : <String>[];
        throw BackendPolicyException(msg, errors: errors);
      } else if (response.statusCode == 409) {
        final errorData = jsonDecode(response.body);
        final msg = errorData['message'] as String? ?? 'Email này đã được sử dụng bởi một tài khoản khác';
        throw EmailConflictException(msg);
      } else {
        final errorData = jsonDecode(response.body);
        throw ServerUncertainException(errorData['message'] ?? 'Lỗi máy chủ (${response.statusCode})');
      }
    } on BackendPolicyException {
      rethrow;
    } on EmailConflictException {
      rethrow;
    } catch (e) {
      throw ServerUncertainException(e.toString());
    }
  }

  /// Xóa tài khoản Firebase hiện tại (dùng cho rollback khi đăng ký backend thất bại)
  Future<void> deleteCurrentFirebaseUser() async {
    try {
      await _firebaseAuth.currentUser?.delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

