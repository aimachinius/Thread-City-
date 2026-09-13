import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../core/config/app_config.dart';

abstract class IMessageRepository {
  Future<List<ConversationModel>> getConversations(
      {required String firebaseUid});
  Future<List<ConversationModel>> getMessageRequests(
      {required String firebaseUid});

  Future<ConversationModel> createOrOpenConversation({
    required String firebaseUid,
    required int receiverId,
  });

  Future<List<MessageModel>> getMessages({
    required int conversationId,
    required String firebaseUid,
    int page = 1,
    int limit = 30,
  });

  Future<MessageModel> sendMessage({
    required String firebaseUid,
    required int receiverId,
    String type = 'TEXT',
    String? content,
    String? mediaUrl,
    int? sharedPostId,
  });

  Future<ConversationModel> acceptRequest({
    required int conversationId,
    required String firebaseUid,
  });

  Future<void> declineRequest({
    required int conversationId,
    required String firebaseUid,
  });

  Future<void> markMessagesAsRead({
    required int conversationId,
    required String firebaseUid,
  });

  Future<void> blockConversation({
    required int conversationId,
    required String firebaseUid,
  });

  Future<void> deleteMessage({
    required int messageId,
    required String firebaseUid,
  });

  Future<void> hideMessageForMe({
    required int messageId,
    required String firebaseUid,
  });
}

class MessageRepository implements IMessageRepository {
  final String baseUrl = '${AppConfig.baseUrl}/messages';
  Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Phiên đăng nhập không hợp lệ, vui lòng đăng nhập lại');
    }
    return {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $token',
      };
  }

  @override
  Future<List<ConversationModel>> getConversations(
      {required String firebaseUid}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ConversationModel.fromMap(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Không thể tải danh sách cuộc trò chuyện');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ConversationModel>> getMessageRequests(
      {required String firebaseUid}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/requests'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ConversationModel.fromMap(json)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          errorData['message'] ?? 'Không thể tải danh sách yêu cầu tin nhắn');
    }
  }

  @override
  Future<ConversationModel> createOrOpenConversation({
    required String firebaseUid,
    required int receiverId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: await _headers(),
      body: jsonEncode({'receiver_id': receiverId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ConversationModel.fromMap(data);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          errorData['message'] ?? 'Không thể tạo/mở cuộc trò chuyện');
    }
  }

  @override
  Future<List<MessageModel>> getMessages({
    required int conversationId,
    required String firebaseUid,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$conversationId?page=$page&limit=$limit'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MessageModel.fromMap(json)).toList();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Không thể tải danh sách tin nhắn');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String firebaseUid,
    required int receiverId,
    String type = 'TEXT',
    String? content,
    String? mediaUrl,
    int? sharedPostId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: await _headers(),
        body: jsonEncode({
          'receiver_id': receiverId,
          'type': type,
          if (content != null) 'content': content,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (sharedPostId != null) 'shared_post_id': sharedPostId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageModel.fromMap(data['newMessage']);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Không thể gửi tin nhắn');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ConversationModel> acceptRequest({
    required int conversationId,
    required String firebaseUid,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$conversationId/accept'),
        headers: await _headers(),
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ConversationModel.fromMap(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Không thể chấp nhận yêu cầu tin nhắn');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> declineRequest({
    required int conversationId,
    required String firebaseUid,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$conversationId/decline'),
        headers: await _headers(),
        body: jsonEncode({}),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Không thể từ chối yêu cầu tin nhắn');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markMessagesAsRead({
    required int conversationId,
    required String firebaseUid,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$conversationId/read'),
        headers: await _headers(),
        body: jsonEncode({}),
      );

      if (response.statusCode != 200) {
        throw Exception('Không thể đánh dấu đã đọc');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> blockConversation({
    required int conversationId,
    required String firebaseUid,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$conversationId/block'),
        headers: await _headers(),
        body: jsonEncode({}),
      );

      if (response.statusCode != 200) {
        throw Exception('Không thể chặn cuộc trò chuyện');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage({
    required int messageId,
    required String firebaseUid,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$messageId'),
        headers: await _headers(),
        body: jsonEncode({}),
      );

      if (response.statusCode != 200) {
        throw Exception('Không thể xóa tin nhắn');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> hideMessageForMe({
    required int messageId,
    required String firebaseUid,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$messageId/hide'),
        headers: await _headers(),
        body: jsonEncode({}),
      );

      if (response.statusCode != 200) {
        throw Exception('Không thể ẩn tin nhắn phía bạn');
      }
    } catch (e) {
      rethrow;
    }
  }
}
