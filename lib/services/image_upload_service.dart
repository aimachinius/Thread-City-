import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  // ==========================================
  // PHƯƠNG PHÁP 2: UPLOAD LÊN FIREBASE STORAGE (SDK CHÍNH THỨC)
  // ==========================================
  /// Uploads an image to Firebase Storage and returns the direct download URL.
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      // Tạo tên file độc nhất bằng timestamp + tên file gốc để không bị đè dữ liệu
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('posts')
          .child(fileName);

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        // Lấy mimetype từ XFile (vd: video/mp4, image/jpeg)
        final mimeType = imageFile.mimeType ?? (fileName.endsWith('.mp4') ? 'video/mp4' : 'image/jpeg');
        uploadTask = storageRef.putData(
          bytes, 
          SettableMetadata(contentType: mimeType)
        );
      } else {
        uploadTask = storageRef.putFile(File(imageFile.path));
      }
      
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
