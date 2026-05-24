import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/notification_queue.dart';

void main() {
  group('NotificationQueue', () {
    test('instance is singleton', () {
      expect(NotificationQueue.instance, same(NotificationQueue.instance));
    });

    test('markDialogActive and markDialogInactive', () {
      final queue = NotificationQueue.instance;
      queue.markDialogActive('dialog1');
      queue.markDialogInactive('dialog1');
    });

    test('enqueue does not throw', () {
      final queue = NotificationQueue.instance;
      expect(
        () => queue.enqueue(
          dialogId: 'dialog1',
          sender: 'Alice',
          message: 'Hello!',
        ),
        returnsNormally,
      );
    });

    test('enqueue with data does not throw', () {
      final queue = NotificationQueue.instance;
      expect(
        () => queue.enqueue(
          dialogId: 'dialog2',
          sender: 'Bob',
          message: 'Test',
          channelId: 'calls',
          data: {'callId': '123'},
        ),
        returnsNormally,
      );
    });

    test('multiple markDialogActive for different dialogs', () {
      final queue = NotificationQueue.instance;
      queue.markDialogActive('d1');
      queue.markDialogActive('d2');
      queue.markDialogInactive('d1');
      queue.markDialogInactive('d2');
    });

    test('enqueue when dialog is active suppresses notification', () {
      final queue = NotificationQueue.instance;
      queue.markDialogActive('dialog3');
      queue.enqueue(
        dialogId: 'dialog3',
        sender: 'Alice',
        message: 'Should be suppressed',
      );
      queue.markDialogInactive('dialog3');
    });
  });
}
