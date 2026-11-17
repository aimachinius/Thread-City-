import 'package:flutter/foundation.dart';

class AppConfig {
  // Tự động dùng localhost trên Web để tránh ngrok chặn request OPTIONS (CORS preflight).
  // Trên Mobile, vẫn dùng ngrok để test mạng ngoài.
  static const String _envServerUrl = String.fromEnvironment('SERVER_URL',defaultValue: '');
  static String get serverUrl{
    if(_envServerUrl.isNotEmpty){
      return _envServerUrl;
    }
    if(kDebugMode){
      if(kIsWeb){
      return 'http://localhost:3000';
      }
      return 'http://10.0.2.2:3000';
    }
    return 'https://thread-city.onrender.com';
  }

  static String get baseUrl => '$serverUrl/api';
  static String get authUrl => '$baseUrl/auth';
  static String get postsUrl => '$baseUrl/posts';

  // Public URL cho người dùng mở bằng Web Browser hoặc Share
  static const String _envPublicAppUrl = String.fromEnvironment('PUBLIC_APP_URL', defaultValue: '');
  static String get publicAppUrl {
    if (_envPublicAppUrl.isNotEmpty) {
      return _envPublicAppUrl;
    }
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null') {
        return origin;
      }
    }
    return 'https://thread-b4d7b.web.app';
  }

  /// URL chuẩn để chia sẻ bài viết (Copy Link, Native OS Share)
  /// Ví dụ: https://thread-b4d7b.web.app/post/123
  static String getPostShareUrl(int postId) => '$publicAppUrl/post/$postId';

  /// URL chuẩn để chia sẻ trang cá nhân (Copy Link, Native OS Share)
  /// Ví dụ: https://thread-b4d7b.web.app/user/alex
  static String getProfileShareUrl(String username) => '$publicAppUrl/user/$username';
}

