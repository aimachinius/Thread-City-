import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../models/notification_model.dart';

abstract class INotificationRepository {
  Future<List<NotificationModel>> getNotifications({required String firebaseUid});
}

class NotificationRepository implements INotificationRepository {
  @override
  Future<List<NotificationModel>> getNotifications({required String firebaseUid}) async {
    final url = Uri.parse('${AppConfig.baseUrl}/notifications?firebase_uid=$firebaseUid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationModel.fromMap(json)).toList();
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }
}
