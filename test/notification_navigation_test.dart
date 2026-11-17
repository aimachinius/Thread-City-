import 'package:flutter_test/flutter_test.dart';
import 'package:thread_app/models/user_model.dart';
import 'package:thread_app/models/notification_model.dart';
import 'package:thread_app/data/repositories/notification_repository.dart';
import 'package:thread_app/providers/notification_provider.dart';
import 'package:thread_app/providers/auth_provider.dart';

class FakeNotificationRepository implements INotificationRepository {
  final List<int> markedAsReadIds = [];
  List<NotificationModel> notificationsToReturn = [];

  @override
  Future<List<NotificationModel>> getNotifications({required String firebaseUid}) async {
    return notificationsToReturn;
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    markedAsReadIds.add(notificationId);
  }
}

class FakeAuthProvider extends Fake implements AuthProvider {
  @override
  Map<String, dynamic>? get currentUserData => {
    'id': 1,
    'username': 'my_account',
    'firebase_uid': 'my_uid_123',
  };
}

void main() {
  group('Notification & Navigation Tests', () {
    test('UserModel.fromMap parses firebase_uid and nickname', () {
      final user = UserModel.fromMap({
        'id': 99,
        'username': 'alice',
        'email': 'alice@test.com',
        'nickname': 'Alice Wonder',
        'avatar_url': 'https://example.com/alice.png',
        'firebase_uid': 'uid_alice_789',
      });

      expect(user.id, 99);
      expect(user.username, 'alice');
      expect(user.nickname, 'Alice Wonder');
      expect(user.avatarUrl, 'https://example.com/alice.png');
      expect(user.firebaseUid, 'uid_alice_789');
    });

    test('NotificationModel.fromMap and copyWith update isRead', () {
      final map = {
        'id': 10,
        'user_id': 1,
        'actor_id': 99,
        'post_id': 105,
        'type': 'like',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'actor': {
          'id': 99,
          'username': 'alice',
          'email': '',
          'nickname': 'Alice Wonder',
          'firebase_uid': 'uid_alice_789',
        },
        'post': {
          'id': 105,
          'user_id': 1,
          'content': 'Test notification post',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      };

      final notif = NotificationModel.fromMap(map);
      expect(notif.id, 10);
      expect(notif.isRead, isFalse);
      expect(notif.actor.nickname, 'Alice Wonder');
      expect(notif.actor.firebaseUid, 'uid_alice_789');
      expect(notif.postId, 105);

      final updated = notif.copyWith(isRead: true);
      expect(updated.isRead, isTrue);
      expect(updated.id, 10);
      expect(updated.actor.username, 'alice');
    });

    test('NotificationProvider.markAsRead updates state optimistically and calls repository', () async {
      final repo = FakeNotificationRepository();
      final auth = FakeAuthProvider();
      final provider = NotificationProvider(repo, auth);

      final notif = NotificationModel(
        id: 42,
        userId: 1,
        actorId: 99,
        postId: 200,
        type: 'follow',
        isRead: false,
        createdAt: DateTime.now(),
        actor: UserModel(
          id: 99,
          username: 'alice',
          email: '',
          nickname: 'Alice Wonder',
          firebaseUid: 'uid_alice_789',
        ),
      );

      repo.notificationsToReturn = [notif];
      await provider.fetchNotifications();

      expect(provider.notifications.length, 1);
      expect(provider.notifications.first.isRead, isFalse);

      await provider.markAsRead(42);

      // Verify optimistic update on provider
      expect(provider.notifications.first.isRead, isTrue);
      // Verify repository call
      expect(repo.markedAsReadIds, contains(42));
    });

    test('NotificationProvider.hasUnread accurately tracks unread state and turns off after markAsRead', () async {
      final repo = FakeNotificationRepository();
      final auth = FakeAuthProvider();
      final provider = NotificationProvider(repo, auth);

      expect(provider.hasUnread, isFalse);
      expect(provider.unreadCount, 0);

      final notif1 = NotificationModel(
        id: 1,
        userId: 1,
        actorId: 99,
        type: 'like',
        isRead: false,
        createdAt: DateTime.now(),
        actor: UserModel(id: 99, username: 'alice', email: ''),
      );
      final notif2 = NotificationModel(
        id: 2,
        userId: 1,
        actorId: 100,
        type: 'follow',
        isRead: true,
        createdAt: DateTime.now(),
        actor: UserModel(id: 100, username: 'bob', email: ''),
      );

      repo.notificationsToReturn = [notif1, notif2];
      await provider.fetchNotifications(isSilent: true);

      expect(provider.hasUnread, isTrue);
      expect(provider.unreadCount, 1);

      await provider.markAsRead(1);

      // Now all notifications are read -> hasUnread must become false (red dot turns off)
      expect(provider.hasUnread, isFalse);
      expect(provider.unreadCount, 0);
    });
  });
}
