import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/post_model.dart';
import '../../core/config/app_config.dart';

abstract class IPostRepository {
  Future<List<PostModel>> getFeed({String? firebaseUid, String? cursor});
  Future<void> createPost({
    required String firebaseUid, 
    required String content, 
    int? parentId, 
    String? type,
    List<Map<String, String>>? media,
  });
  Future<bool> toggleLike({required int postId, required String firebaseUid});
  Future<List<PostModel>> getReplies(int postId, {String? firebaseUid});
  Future<Map<String, dynamic>> getUserProfile(String firebaseUid, {String? viewerUid});
  Future<void> updateProfile({
    required String firebaseUid,
    String? bio,
    String? avatarUrl,
    String? nickname,
  });
}

class PostRepository implements IPostRepository {
  final String baseUrl = AppConfig.baseUrl;

  @override
  Future<List<PostModel>> getReplies(int postId, {String? firebaseUid}) async {
    try {
      final url = firebaseUid != null 
          ? '$baseUrl/posts/$postId/replies?firebase_uid=$firebaseUid'
          : '$baseUrl/posts/$postId/replies';
          
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PostModel.fromMap(json)).toList();
      } else {
        throw Exception('Không thể lấy danh sách bình luận');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> toggleLike({required int postId, required String firebaseUid}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_uid': firebaseUid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['liked'] as bool;
      } else {
        throw Exception('Không thể thực hiện hành động like');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> createPost({
    required String firebaseUid, 
    required String content, 
    int? parentId, 
    String? type,
    List<Map<String, String>>? media,
  }) async {
    try {
      final bodyData = {
        'firebase_uid': firebaseUid,
        'content': content,
        'parent_id': parentId,
        'type': type ?? 'post',
      };
      
      if (media != null && media.isNotEmpty) {
        bodyData['media'] = media;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể tạo bài viết');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PostModel>> getFeed({String? firebaseUid, String? cursor}) async {
    try {
      final url = firebaseUid != null 
          ? '$baseUrl/posts?firebase_uid=$firebaseUid'
          : '$baseUrl/posts';
          
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PostModel.fromMap(json)).toList();
      } else {
        throw Exception('Không thể tải bảng tin (Lỗi: ${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserProfile(String firebaseUid, {String? viewerUid}) async {
    try {
      // Đổi sang đầu mút mới: /api/users/
      final url = viewerUid != null 
          ? '$baseUrl/users/$firebaseUid?viewer_uid=$viewerUid'
          : '$baseUrl/users/$firebaseUid';
          
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final List<dynamic> postsJson = data['posts'];
        final posts = postsJson.map((json) => PostModel.fromMap(json)).toList();
        
        return {
          'user': data['user'],
          'posts': posts,
        };
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
      // Đổi sang đầu mút mới: /api/users/
      final Map<String, dynamic> body = {};
      if (bio != null) body['bio'] = bio;
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;
      if (nickname != null) body['username'] = nickname;

      final response = await http.patch(
        Uri.parse('$baseUrl/users/$firebaseUid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể cập nhật thông tin');
      }
    } catch (e) {
      rethrow;
    }
  }
}
