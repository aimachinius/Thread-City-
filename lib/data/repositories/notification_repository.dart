import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../models/notification_model.dart';

abstract class INotificationRepository {
  Future<List<NotificationModel>> getNotifications({required String firebaseUid});
  Future<void> markAsRead(int notificationId);
}

class NotificationRepository implements INotificationRepository {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  @override
  Future<List<NotificationModel>> getNotifications({required String firebaseUid}) async {
    final url = Uri.parse('${AppConfig.baseUrl}/notifications?firebase_uid=$firebaseUid');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationModel.fromMap(json)).toList();
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/notifications/$notificationId/read');
    final response = await http.patch(url, headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read: ${response.statusCode}');
    }
  }
}
