import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final String authUrl;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  // API Key từ Firebase Console (Dùng cho REST API Backup)
  static const String _firebaseApiKey = 'AIzaSyBME4T6l-Pr93AdCOaELTnIF7HmLZIq9z0';

  AuthRepository(this.authUrl);

  /// Đăng ký bằng Firebase REST API
  Future<Map<String, dynamic>> signUpWithSDK({
    required String email,
    required String password,
  }) async {
    print('[AUTH] 🚀 Bắt đầu đăng ký REST API...');
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
  }

  /// Đăng nhập bằng Firebase REST API
  Future<Map<String, dynamic>> signInWithSDK({
    required String email,
    required String password,
  }) async {
    print('[AUTH] 🔑 Bắt đầu đăng nhập REST API...');
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
    try {
      final response = await http.post(
        Uri.parse('$authUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_uid': uid,
          'email': email,
          'username': username,
        }),
      ).timeout(const Duration(seconds: 10)); // Thêm timeout

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Lỗi đăng ký server');
      }
    } catch (e) {
      rethrow;
    }
  }
}
