import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/notification/app_notification.dart';

void main() {
  group('AppNotification', () {
    test('creates with required fields', () {
      final notif = AppNotification(
        id: 'n1', title: 'Test', body: 'Body',
        type: NotificationType.message, timestamp: DateTime(2024),
      );
      expect(notif.id, 'n1');
      expect(notif.title, 'Test');
      expect(notif.body, 'Body');
      expect(notif.type, NotificationType.message);
      expect(notif.read, false);
    });

    test('creates with optional fields', () {
      final notif = AppNotification(
        id: 'n1', title: 'Test', body: 'Body',
        type: NotificationType.invite, timestamp: DateTime(2024),
        roomId: 'room1', senderId: 'user1',
      );
      expect(notif.roomId, 'room1');
      expect(notif.senderId, 'user1');
    });

    test('can be copied as read', () {
      final notif = AppNotification(
        id: 'n1', title: 'Test', body: 'Body',
        type: NotificationType.message, timestamp: DateTime(2024),
      );
      expect(notif.read, false);
      final readNotif = notif.copyWith(read: true);
      expect(readNotif.read, true);
      expect(notif.read, false);
    });

    test('supports optional roomId and senderId', () {
      final notif = AppNotification(
        id: 'n1', title: 'Test', body: 'Body',
        type: NotificationType.message, timestamp: DateTime(2024),
      );
      expect(notif.roomId, isNull);
      expect(notif.senderId, isNull);
    });

    test('toJson returns correct map', () {
      final ts = DateTime(2024, 1, 15);
      final notif = AppNotification(
        id: 'n1', title: 'Test', body: 'Body',
        type: NotificationType.message, timestamp: ts,
        roomId: 'room1', senderId: 'user1',
      );
      final json = notif.toJson();
      expect(json['id'], 'n1');
      expect(json['title'], 'Test');
      expect(json['body'], 'Body');
      expect(json['type'], 'message');
      expect(json['read'], false);
      expect(json['roomId'], 'room1');
      expect(json['senderId'], 'user1');
    });

    test('fromJson creates correct object', () {
      final json = {
        'id': 'n1', 'title': 'Test', 'body': 'Body',
        'type': 'message', 'timestamp': '2024-01-15T00:00:00.000',
        'read': true, 'roomId': 'room1', 'senderId': 'user1',
      };
      final notif = AppNotification.fromJson(json);
      expect(notif.id, 'n1');
      expect(notif.title, 'Test');
      expect(notif.body, 'Body');
      expect(notif.type, NotificationType.message);
      expect(notif.read, true);
      expect(notif.roomId, 'room1');
      expect(notif.senderId, 'user1');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'n1', 'title': 'Test', 'body': 'Body',
        'type': 'message', 'timestamp': '2024-01-15T00:00:00.000',
      };
      final notif = AppNotification.fromJson(json);
      expect(notif.read, false);
      expect(notif.roomId, isNull);
      expect(notif.senderId, isNull);
    });

    test('toJson and fromJson round-trip', () {
      final notif = AppNotification(
        id: 'n1', title: 'Test', body: 'Body',
        type: NotificationType.invite, timestamp: DateTime(2024, 1, 15),
        roomId: 'room1', senderId: 'user1', read: true,
      );
      final json = notif.toJson();
      final restored = AppNotification.fromJson(json);
      expect(restored.id, notif.id);
      expect(restored.title, notif.title);
      expect(restored.body, notif.body);
      expect(restored.type, notif.type);
      expect(restored.read, true);
      expect(restored.roomId, notif.roomId);
      expect(restored.senderId, notif.senderId);
    });

    test('different notification types', () {
      final messageNotif = AppNotification(
        id: 'n1', title: 'Msg', body: 'Hello',
        type: NotificationType.message, timestamp: DateTime(2024),
      );
      final inviteNotif = AppNotification(
        id: 'n2', title: 'Invite', body: 'Invited',
        type: NotificationType.invite, timestamp: DateTime(2024),
      );
      expect(messageNotif.type, NotificationType.message);
      expect(inviteNotif.type, NotificationType.invite);
    });
  });
}
