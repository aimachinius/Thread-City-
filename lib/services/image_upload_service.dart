import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';

class ImageUploadService {
  /*
  // ==========================================
  // PHƯƠNG PHÁP 1: UPLOAD LÊN IMGBB (BACKUP)
  // ==========================================
  static const String _imgBbApiKey = '40a1b6d0ad2132e0e47dafaefeddf4f2'; 

  static Future<String?> uploadImageImgBB(File imageFile) async {
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
  */

  // ==========================================
  // PHƯƠNG PHÁP 2: UPLOAD LÊN FIREBASE STORAGE (SDK CHÍNH THỨC)
  // ==========================================
  /// Uploads an image to Firebase Storage and returns the direct download URL.
  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Tạo tên file độc nhất bằng timestamp + tên file gốc để không bị đè dữ liệu
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('posts')
          .child(fileName);

      // Thực hiện upload trực tiếp bằng putFile
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Lấy link tải xuống trực tiếp từ Firebase Storage
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('[STORAGE] 🎉 Tải ảnh Post Media lên Firebase Storage thành công: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Lỗi upload Firebase Storage chi tiết: $e');
      return null;
    }
  }
}
