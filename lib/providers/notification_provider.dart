import 'package:flutter/material.dart';
import '../data/repositories/notification_repository.dart';
import '../models/notification_model.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final INotificationRepository _notificationRepository;
  AuthProvider _authProvider;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _socketListenerAttached = false;

  NotificationProvider(this._notificationRepository, this._authProvider) {
    _initSocket();
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnread => _notifications.any((n) => !n.isRead);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool _isDisposed = false;

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
    if (auth.isAuthenticated && auth.currentUserData != null) {
      _initSocket();
      fetchNotifications(isSilent: true);
    }
  }

  void _initSocket() {
    if (_socketListenerAttached) return;
    _socketListenerAttached = true;
    SocketService().onNewNotification((_) {
      // Cập nhật ngầm danh sách thông báo, không hiện popup/banner
      fetchNotifications(isSilent: true);
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> fetchNotifications({bool isSilent = false}) async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return;

    if (!isSilent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final list = await _notificationRepository.getNotifications(firebaseUid: firebaseUid);
      if (!_isDisposed) {
        _notifications = list;
      }
    } catch (e) {
      if (!_isDisposed && !isSilent) {
        _errorMessage = e.toString();
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;

    // Optimistic UI update
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    try {
      await _notificationRepository.markAsRead(notificationId);
    } catch (e) {
      debugPrint('Error markAsRead: $e');
    }
  }
}
