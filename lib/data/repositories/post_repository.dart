import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import '../../core/config/app_config.dart';

abstract class IPostRepository {
  Future<List<PostModel>> getFeed({String? firebaseUid, String? cursor, bool following = false});
  Future<PostModel> createPost({
    required String firebaseUid, 
    required String content, 
    int? parentId, 
    String? type,
    List<Map<String, String>>? media,
  });
  Future<bool> toggleLike({required int postId, required String firebaseUid});
  Future<List<PostModel>> getReplies(int postId, {String? firebaseUid});
  Future<List<PostModel>> getPostsByUserUid(String firebaseUid, {String? viewerUid});
  Future<List<PostModel>> getUserReposts(String firebaseUid, {String? viewerUid});
  Future<bool> toggleRepost({required int postId, required String firebaseUid});
  Future<PostModel> getPostById(int postId, {String? viewerUid});
  Future<bool> deletePost(int postId);
}

class PostRepository implements IPostRepository {
  final String baseUrl = AppConfig.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

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
        headers: await _authHeaders(),
        body: jsonEncode({
          'firebase_uid': firebaseUid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['liked'] as bool;
      } else {
        throw Exception('Không thể thực hiện like (status: ${response.statusCode}, body: ${response.body})');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> toggleRepost({required int postId, required String firebaseUid}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/repost'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'firebase_uid': firebaseUid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reposted'] as bool;
      } else {
        throw Exception('Không thể thực hiện repost (status: ${response.statusCode}, body: ${response.body})');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PostModel> createPost({
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
        headers: await _authHeaders(),
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PostModel.fromMap(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? errorData['message'] ?? 'Không thể tạo bài viết');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PostModel>> getFeed({String? firebaseUid, String? cursor, bool following = false}) async {
    try {
      String url = '$baseUrl/posts';
      final params = <String>[];
      if (firebaseUid != null) params.add('firebase_uid=$firebaseUid');
      if (following) params.add('following=true');
      if (cursor != null) params.add('cursor=$cursor');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
          
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
  Future<List<PostModel>> getPostsByUserUid(String firebaseUid, {String? viewerUid}) async {
    try {
      final url = viewerUid != null 
          ? '$baseUrl/posts/user/$firebaseUid?viewer_uid=$viewerUid'
          : '$baseUrl/posts/user/$firebaseUid';
          
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PostModel.fromMap(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách bài viết của người dùng');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PostModel>> getUserReposts(String firebaseUid, {String? viewerUid}) async {
    try {
      final url = viewerUid != null 
          ? '$baseUrl/posts/user/$firebaseUid/reposts?viewer_uid=$viewerUid'
          : '$baseUrl/posts/user/$firebaseUid/reposts';
          
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PostModel.fromMap(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách bài đăng lại');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PostModel> getPostById(int postId, {String? viewerUid}) async {
    try {
      final url = viewerUid != null 
          ? '$baseUrl/posts/$postId?viewer_uid=$viewerUid'
          : '$baseUrl/posts/$postId';
          
      final response = await http.get(
        Uri.parse(url),
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        return PostModel.fromMap(data);
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception('Không thể tải bài viết (status: ${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> deletePost(int postId) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final headers = await _authHeaders();
      if (currentUid != null && currentUid.isNotEmpty) {
        headers['x-firebase-uid'] = currentUid;
      }

      final url = currentUid != null && currentUid.isNotEmpty
          ? '$baseUrl/posts/$postId?firebase_uid=$currentUid'
          : '$baseUrl/posts/$postId';

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        String msg = 'Không thể xóa bài viết (status: ${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData['message'] != null) {
            msg = errorData['message'];
          }
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      rethrow;
    }
  }
}


