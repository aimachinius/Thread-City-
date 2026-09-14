import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class AuthRepository {
  final String authUrl;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  // API Key từ Firebase Console (Dùng cho REST API Backup)
  static const String _firebaseApiKey = 'AIzaSyBME4T6l-Pr93AdCOaELTnIF7HmLZIq9z0';

  AuthRepository(this.authUrl);

  /// Đăng nhập / Đăng ký bằng Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    debugPrint('[AUTH] 🔑 Bắt đầu Google Sign-In...');
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
      debugPrint('[AUTH] ✅ Google Sign-In thành công: ${user.displayName}');

      return {
        'localId': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH][GOOGLE_ERROR] ${e.code}: ${e.message}');
      throw Exception(e.message ?? 'Đăng nhập Google thất bại');
    } catch (e) {
      debugPrint('[AUTH][GOOGLE_UNKNOWN] $e');
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  /// Đăng ký bằng Firebase SDK
  Future<Map<String, dynamic>> signUpWithSDK({
    required String email,
    required String password,
  }) async {
    print('[AUTH] 🚀 Bắt đầu đăng ký bằng Firebase SDK...');
    
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
      
      print('[AUTH][SDK_ERROR] $errorCode: ${e.message}');
      throw Exception(errorCode);
    } catch (e) {
      print('[AUTH][UNKNOWN_ERROR] $e');
      throw Exception(e.toString());
    }
  }

  /// Đăng nhập bằng Firebase SDK
  Future<Map<String, dynamic>> signInWithSDK({
    required String email,
    required String password,
  }) async {
    print('[AUTH] 🔑 Bắt đầu đăng nhập bằng Firebase SDK...');

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

      print('[AUTH][SDK_ERROR] $errorCode: ${e.message}');
      throw Exception(errorCode);
    } catch (e) {
      print('[AUTH][UNKNOWN_ERROR] $e');
      throw Exception(e.toString());
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
  --- */

  /// Lấy thông tin user từ MySQL theo firebase_uid (có retry 1 lần khi timeout)
  Future<Map<String, dynamic>?> getUserByFirebaseUid(String uid) async {
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final response = await http.get(
          Uri.parse('$authUrl/by-uid/$uid'),
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
          print('[AUTH] ⚠️ Lỗi kết nối MySQL (sau $attempt lần thử): $e');
          return null;
        }
        // Lần 1 timeout → đợi 2 giây rồi thử lại (server có thể đang wake up)
        print('[AUTH] 🔄 Retry kết nối MySQL (lần $attempt)...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  Future<void> registerUserToMySQL({
    required String uid,
    required String email,
    required String username,
    String? nickname,
  }) async {
    final url = Uri.parse('$authUrl/register');
    debugPrint('[AUTH] 🌐 Đang gọi API MySQL: $url');

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
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('[AUTH] 📥 Phản hồi MySQL: ${response.statusCode}');

      // 201 = mới tạo, 200 = đã tồn tại (Google re-login) — cả 2 đều OK
      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        debugPrint('[AUTH] ❌ Lỗi MySQL: ${errorData['message']}');
        throw Exception(errorData['message'] ?? 'Lỗi đăng ký server');
      }
    } catch (e) {
      debugPrint('[AUTH] 🚨 Lỗi kết nối/timeout MySQL: $e');
      rethrow;
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    print('[AUTH] 🚪 Đăng xuất khỏi Firebase SDK...');
    await _firebaseAuth.signOut();
  }

  /// Quên mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    print('[AUTH] 📧 Gửi email khôi phục mật khẩu cho: $email');
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('[AUTH][SDK_ERROR] ${e.code}: ${e.message}');
      throw Exception(e.code.toUpperCase().replaceAll('-', '_'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
