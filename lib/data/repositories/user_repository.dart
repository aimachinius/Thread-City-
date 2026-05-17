import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

abstract class IUserRepository {
  Future<Map<String, dynamic>> getUserProfile(String firebaseUid);
  Future<void> updateProfile({
    required String firebaseUid,
    String? bio,
    String? avatarUrl,
    String? nickname,
  });
}

class UserRepository implements IUserRepository {
  final String baseUrl = AppConfig.baseUrl;

  @override
  Future<Map<String, dynamic>> getUserProfile(String firebaseUid) async {
    try {
      final url = '$baseUrl/users/$firebaseUid';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'] as Map<String, dynamic>;
      } else {
        throw Exception('Không thể tải thông tin cá nhân');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateProfile({
    required String firebaseUid,
    String? bio,
    String? avatarUrl,
    String? nickname,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (bio != null) body['bio'] = bio;
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;
      if (nickname != null) body['username'] = nickname;

      final response = await http.patch(
        Uri.parse('$baseUrl/users/$firebaseUid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể cập nhật thông tin');
      }
    } catch (e) {
      rethrow;
    }
  }
}
