import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageUploadService {
  // Free API Key from ImgBB for temporary/development image hosting
  // It allows us to bypass Firebase Storage setup requirements
  static const String _imgBbApiKey = '40a1b6d0ad2132e0e47dafaefeddf4f2'; 

  /// Uploads an image to ImgBB and returns the direct URL.
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse('https://api.imgbb.com/1/upload');
      final response = await http.post(url, body: {
        'key': _imgBbApiKey,
        'image': base64Image,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      } else {
        print('ImgBB Upload Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ImageUploadService Exception: $e');
      return null;
    }
  }
}
