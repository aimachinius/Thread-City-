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
}
