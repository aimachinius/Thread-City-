import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final String authUrl;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  // API Key từ Firebase Console (Dùng cho REST API Backup)
  static const String _firebaseApiKey = 'AIzaSyBME4T6l-Pr93AdCOaELTnIF7HmLZIq9z0';

  AuthRepository(this.authUrl);

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

  /// Lấy thông tin user từ MySQL theo firebase_uid
  Future<Map<String, dynamic>?> getUserByFirebaseUid(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$authUrl/by-uid/$uid'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10)); // Thêm timeout
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('[AUTH] ⚠️ Lỗi kết nối MySQL: $e');
      return null;
    }
  }

  Future<void> registerUserToMySQL({
    required String uid,
    required String email,
    required String username,
  }) async {
    final url = Uri.parse('$authUrl/register');
    print('[AUTH] 🌐 Đang gọi API MySQL: $url');
    print('[AUTH] 📦 Body: ${{
      'firebase_uid': uid,
      'email': email,
      'username': username,
    }}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_uid': uid,
          'email': email,
          'username': username,
        }),
      ).timeout(const Duration(seconds: 10));

      print('[AUTH] 📥 Phản hồi MySQL: ${response.statusCode}');

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        print('[AUTH] ❌ Lỗi MySQL: ${errorData['message']}');
        throw Exception(errorData['message'] ?? 'Lỗi đăng ký server');
      }
    } catch (e) {
      print('[AUTH] 🚨 Lỗi kết nối/timeout MySQL: $e');
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
