import 'package:flutter/material.dart';
import '../data/repositories/notification_repository.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final INotificationRepository _notificationRepository;
  final AuthProvider _authProvider;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  NotificationProvider(this._notificationRepository, this._authProvider);

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

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

  Future<void> fetchNotifications() async {
    final firebaseUid = _authProvider.currentUserData?['firebase_uid'];
    if (firebaseUid == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _notificationRepository.getNotifications(firebaseUid: firebaseUid);
      if (!_isDisposed) {
        _notifications = list;
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = e.toString();
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
