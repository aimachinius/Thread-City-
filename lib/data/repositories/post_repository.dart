import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/post_model.dart';

abstract class IPostRepository {
  Future<List<PostModel>> getFeed({String? cursor});
}

class PostRepository implements IPostRepository {
  // Đối với môi trường Dev: 
  // - iOS Simulator: localhost
  // - Android Emulator: 10.0.2.2
  final String baseUrl = 'http://localhost:3000/api';

  @override
  Future<List<PostModel>> getFeed({String? cursor}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.statusCode.toString() == "200" ? response.body : "[]");
        // ORM trả về JSON, chúng ta map thẳng vào Model
        return data.map((json) => PostModel.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load feed');
      }
    } catch (e) {
      // Re-throw để Provider xử lý hiển thị lỗi
      rethrow;
    }
  }
}
