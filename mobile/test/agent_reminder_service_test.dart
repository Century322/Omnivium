import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/agent/agent_reminder_service.dart';

void main() {
  group('ReminderType', () {
    test('has all expected values', () {
      expect(ReminderType.values.length, 4);
      expect(ReminderType.values, contains(ReminderType.messageNotification));
      expect(ReminderType.values, contains(ReminderType.recurring));
      expect(ReminderType.values, contains(ReminderType.scheduled));
      expect(ReminderType.values, contains(ReminderType.aiSmart));
    });
  });

  group('ReminderStatus', () {
    test('has all expected values', () {
      expect(ReminderStatus.values.length, 4);
      expect(ReminderStatus.values, contains(ReminderStatus.active));
      expect(ReminderStatus.values, contains(ReminderStatus.paused));
      expect(ReminderStatus.values, contains(ReminderStatus.completed));
      expect(ReminderStatus.values, contains(ReminderStatus.cancelled));
    });
  });

  group('ReminderFrequency', () {
    test('everyMinute has 1 minute interval', () {
      expect(
        ReminderFrequency.everyMinute.interval,
        const Duration(minutes: 1),
      );
    });

    test('every30Minutes has 30 minute interval', () {
      expect(
        ReminderFrequency.every30Minutes.interval,
        const Duration(minutes: 30),
      );
    });

    test('every2Hours has 2 hour interval', () {
      expect(ReminderFrequency.every2Hours.interval, const Duration(hours: 2));
    });

    test('every6Hours has 6 hour interval', () {
      expect(ReminderFrequency.every6Hours.interval, const Duration(hours: 6));
    });

    test('everyDay has 1 day interval', () {
      expect(ReminderFrequency.everyDay.interval, const Duration(days: 1));
    });

    test('custom creates custom frequency', () {
      final custom = ReminderFrequency.custom(const Duration(hours: 3));
      expect(custom.interval, const Duration(hours: 3));
      expect(custom.isCustom, isTrue);
    });
  });

  group('Reminder', () {
    test('constructor sets all fields', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'r1',
        type: ReminderType.recurring,
        title: 'Test Reminder',
        description: 'Test description',
        frequency: ReminderFrequency.everyDay,
        createdAt: now,
      );
      expect(reminder.id, 'r1');
      expect(reminder.type, ReminderType.recurring);
      expect(reminder.title, 'Test Reminder');
      expect(reminder.description, 'Test description');
      expect(reminder.frequency, ReminderFrequency.everyDay);
      expect(reminder.createdAt, now);
      expect(reminder.status, ReminderStatus.active);
      expect(reminder.nextTriggerAt, isNull);
      expect(reminder.metadata, isEmpty);
    });

    test('copyWith updates status', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'r1',
        type: ReminderType.scheduled,
        title: 'Test',
        description: 'Desc',
        frequency: ReminderFrequency.everyDay,
        createdAt: now,
      );
      final updated = reminder.copyWith(status: ReminderStatus.completed);
      expect(updated.status, ReminderStatus.completed);
      expect(updated.id, 'r1');
    });

    test('copyWith updates nextTriggerAt', () {
      final now = DateTime.now();
      final next = now.add(const Duration(hours: 1));
      final reminder = Reminder(
        id: 'r1',
        type: ReminderType.recurring,
        title: 'Test',
        description: 'Desc',
        frequency: ReminderFrequency.everyDay,
        createdAt: now,
      );
      final updated = reminder.copyWith(nextTriggerAt: next);
      expect(updated.nextTriggerAt, next);
    });

    test('toJson returns valid map', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'r1',
        type: ReminderType.aiSmart,
        title: 'AI Reminder',
        description: 'Smart',
        frequency: ReminderFrequency.every2Hours,
        createdAt: now,
        metadata: {'key': 'value'},
      );
      final json = reminder.toJson();
      expect(json['id'], 'r1');
      expect(json['type'], 'aiSmart');
      expect(json['title'], 'AI Reminder');
      expect(json['status'], 'active');
    });

    test('with matrixRoomId', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'r1',
        type: ReminderType.messageNotification,
        title: 'New message',
        description: 'From Alice',
        frequency: ReminderFrequency.everyMinute,
        createdAt: now,
        matrixRoomId: '!room:matrix.org',
      );
      expect(reminder.matrixRoomId, '!room:matrix.org');
    });

    test('with aiPrompt', () {
      final now = DateTime.now();
      final reminder = Reminder(
        id: 'r1',
        type: ReminderType.aiSmart,
        title: 'Smart reminder',
        description: 'AI generated',
        frequency: ReminderFrequency.every6Hours,
        createdAt: now,
        aiPrompt: 'Remind me to take medicine',
      );
      expect(reminder.aiPrompt, 'Remind me to take medicine');
    });
  });
}
