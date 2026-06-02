import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/notification/notification_cubit.dart';
import 'package:omnivium/core/notification/app_notification.dart';

void main() {
  group('NotificationState', () {
    test('initial state has empty notifications and zero unread', () {
      const state = NotificationState();
      expect(state.notifications, isEmpty);
      expect(state.unreadCount, 0);
    });

    test('copyWith updates notifications and recalculates unreadCount', () {
      final notif = AppNotification(
        id: 'test1',
        title: 'Test',
        body: 'Body',
        type: NotificationType.system,
        timestamp: DateTime.now(),
      );
      const state = NotificationState();
      final updated = state.copyWith(notifications: [notif]);
      expect(updated.notifications.length, 1);
      expect(updated.unreadCount, 1);
    });

    test('unreadCount counts unread notifications', () {
      final notifs = [
        AppNotification(
          id: 'a',
          title: 'A',
          body: '',
          type: NotificationType.system,
          timestamp: DateTime.now(),
          read: true,
        ),
        AppNotification(
          id: 'b',
          title: 'B',
          body: '',
          type: NotificationType.message,
          timestamp: DateTime.now(),
        ),
      ];
      final state = const NotificationState().copyWith(notifications: notifs);
      expect(state.unreadCount, 1);
    });

    test('unreadCount is zero when all read', () {
      final notifs = [
        AppNotification(
          id: 'a',
          title: 'A',
          body: '',
          type: NotificationType.system,
          timestamp: DateTime.now(),
          read: true,
        ),
      ];
      final state = const NotificationState().copyWith(notifications: notifs);
      expect(state.unreadCount, 0);
    });

    test('unreadCount equals total when none read', () {
      final notifs = [
        AppNotification(
          id: 'a',
          title: 'A',
          body: '',
          type: NotificationType.system,
          timestamp: DateTime.now(),
        ),
        AppNotification(
          id: 'b',
          title: 'B',
          body: '',
          type: NotificationType.message,
          timestamp: DateTime.now(),
        ),
      ];
      final state = const NotificationState().copyWith(notifications: notifs);
      expect(state.unreadCount, 2);
    });

    test('copyWith preserves existing values', () {
      final notif = AppNotification(
        id: 'a',
        title: 'A',
        body: '',
        type: NotificationType.system,
        timestamp: DateTime.now(),
      );
      final state = const NotificationState().copyWith(notifications: [notif]);
      final updated = state.copyWith();
      expect(updated.notifications, state.notifications);
      expect(updated.unreadCount, state.unreadCount);
    });
  });

  group('NotificationCubit pure state', () {
    late NotificationCubit cubit;

    setUp(() {
      cubit = NotificationCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is empty', () {
      expect(cubit.state.notifications, isEmpty);
      expect(cubit.state.unreadCount, 0);
    });

    test('shortcut getters match state', () {
      expect(cubit.notifications, cubit.state.notifications);
      expect(cubit.unreadCount, cubit.state.unreadCount);
    });

    test('emit updates state correctly', () {
      final notif = AppNotification(
        id: 'test1',
        title: 'Test',
        body: 'Body',
        type: NotificationType.system,
        timestamp: DateTime.now(),
      );
      cubit.emit(cubit.state.copyWith(notifications: [notif]));
      expect(cubit.state.notifications.length, 1);
      expect(cubit.state.unreadCount, 1);
    });
  });
}
