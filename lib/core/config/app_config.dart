class AppConfig {
  // Bạn chỉ cần sửa 1 dòng này duy nhất khi đổi mạng
  static const String ipAddress = '192.168.1.9'; 
  
  static const String baseUrl = 'http://$ipAddress:3000/api';
  static const String authUrl = '$baseUrl/auth';
  static const String postsUrl = '$baseUrl/posts';
}
