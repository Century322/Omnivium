import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/notification_center.dart';

void main() {
  tearDown(() {
    for (final event in Event.values) {
      NotificationCenter.removeObserver(event);
    }
  });

  group('NotificationCenter', () {
    test('observe and post', () {
      Map<String, dynamic>? received;
      NotificationCenter.observe(Event.messageReceived, (data) {
        received = data;
      });
      NotificationCenter.post(Event.messageReceived, data: {'key': 'value'});
      expect(received, {'key': 'value'});
    });

    test('observeOnce fires only once', () {
      var count = 0;
      NotificationCenter.observeOnce(Event.messageSent, (data) {
        count++;
      });
      NotificationCenter.post(Event.messageSent);
      NotificationCenter.post(Event.messageSent);
      expect(count, 1);
    });

    test('removeObserver stops notifications', () {
      var count = 0;
      void callback(Map<String, dynamic>? data) => count++;
      NotificationCenter.observe(Event.messageUpdated, callback);
      NotificationCenter.post(Event.messageUpdated);
      NotificationCenter.removeObserver(Event.messageUpdated, callback: callback);
      NotificationCenter.post(Event.messageUpdated);
      expect(count, 1);
    });

    test('removeObserver by id', () {
      var count = 0;
      NotificationCenter.observe(Event.modelChanged, (data) => count++, id: 42);
      NotificationCenter.post(Event.modelChanged);
      NotificationCenter.removeObserver(Event.modelChanged, id: 42);
      NotificationCenter.post(Event.modelChanged);
      expect(count, 1);
    });

    test('postImmediate ignores debounce', () async {
      var count = 0;
      NotificationCenter.observe(Event.themeChanged, (data) => count++);
      NotificationCenter.setDebounce(Event.themeChanged, const Duration(seconds: 5));
      NotificationCenter.postImmediate(Event.themeChanged);
      expect(count, 1);
    });

    test('multiple observers for same event', () {
      var count1 = 0;
      var count2 = 0;
      NotificationCenter.observe(Event.settingsUpdated, (data) => count1++);
      NotificationCenter.observe(Event.settingsUpdated, (data) => count2++);
      NotificationCenter.post(Event.settingsUpdated);
      expect(count1, 1);
      expect(count2, 1);
    });

    test('post with no observers does not throw', () {
      expect(() => NotificationCenter.post(Event.logout), returnsNormally);
    });

    test('Event enum has all expected values', () {
      expect(Event.values.length, greaterThanOrEqualTo(30));
      expect(Event.values, contains(Event.sessionChanged));
      expect(Event.values, contains(Event.messageReceived));
      expect(Event.values, contains(Event.themeChanged));
      expect(Event.values, contains(Event.loginSuccess));
      expect(Event.values, contains(Event.logout));
    });

    test('setDebounce delays notification', () async {
      var count = 0;
      NotificationCenter.observe(Event.localeChanged, (data) => count++);
      NotificationCenter.setDebounce(Event.localeChanged, const Duration(milliseconds: 50));
      NotificationCenter.post(Event.localeChanged);
      expect(count, 0);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(count, 1);
    });
  });
}
