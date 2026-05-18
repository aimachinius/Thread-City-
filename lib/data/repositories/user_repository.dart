import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';

abstract class IUserRepository {
  Future<Map<String, dynamic>> getUserProfile(String firebaseUid, {String? viewerUid});
  Future<void> updateProfile({
    required String firebaseUid,
    String? bio,
    String? avatarUrl,
    String? nickname,
  });
  Future<void> followUser({required String followerUid, required int followingId});
  Future<void> unfollowUser({required String followerUid, required int followingId});
  Future<List<Map<String, dynamic>>> getUserFollowers(String userId);
  Future<List<Map<String, dynamic>>> getUserFollowing(String userId);
}

class UserRepository implements IUserRepository {
  final String baseUrl = AppConfig.baseUrl;

  @override
  Future<Map<String, dynamic>> getUserProfile(String firebaseUid, {String? viewerUid}) async {
    try {
      var url = '$baseUrl/users/$firebaseUid';
      if (viewerUid != null) {
        url += '?viewer_uid=$viewerUid';
      }
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

  @override
  Future<void> followUser({required String followerUid, required int followingId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'follower_uid': followerUid,
          'following_id': followingId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể theo dõi người dùng');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> unfollowUser({required String followerUid, required int followingId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/unfollow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'follower_uid': followerUid,
          'following_id': followingId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể bỏ theo dõi người dùng');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserFollowers(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/followers')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> users = data['users'] ?? [];
        return users.map((u) => u as Map<String, dynamic>).toList();
      } else {
        throw Exception('Không thể tải danh sách người theo dõi');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserFollowing(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId/following')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> users = data['users'] ?? [];
        return users.map((u) => u as Map<String, dynamic>).toList();
      } else {
        throw Exception('Không thể tải danh sách đang theo dõi');
      }
    } catch (e) {
      rethrow;
    }
  }
}
