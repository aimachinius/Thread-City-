/// Helper function để lấy tên enum tương thích mọi phiên bản Dart.
/// Thay thế `.name` (chỉ có từ Dart 2.15+).
String enumName(dynamic enumValue) => enumValue.toString().split('.').last;
