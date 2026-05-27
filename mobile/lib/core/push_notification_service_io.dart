import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';
import 'push_notification_service.dart';
import 'notification_queue.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final List<StreamSubscription> _firebaseSubs = [];

Future<void> initFirebaseMessaging(PushNotificationService service) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    AppLogger.instance.warning(
      'Firebase init failed (google-services.json may be missing)',
      error: e,
    );
    return;
  }

  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null) {
        service.setFcmToken(token);
      } else {
        AppLogger.instance.warning('FCM getToken returned null');
      }

      _firebaseSubs.add(
        messaging.onTokenRefresh.listen((newToken) {
          service.setFcmToken(newToken);
        }),
      );

      _firebaseSubs.add(
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            final dialogId = message.data['dialog_id'] as String? ?? '';
            NotificationQueue.instance.enqueue(
              dialogId: dialogId,
              sender: notification.title ?? 'Omnivium',
              message: notification.body ?? '',
              data: message.data,
            );
          }
        }),
      );

      _firebaseSubs.add(
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          service.handleMessageOpened(message.data);
        }),
      );

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        service.handleMessageOpened(initialMessage.data);
      }
    } else {
      AppLogger.instance.info(
        'Push notification permission denied: ${settings.authorizationStatus}',
      );
    }
  } catch (e, stackTrace) {
    AppLogger.instance.warning(
      'Firebase messaging setup failed',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

void disposeFirebaseMessaging() {
  for (final sub in _firebaseSubs) {
    sub.cancel();
  }
  _firebaseSubs.clear();
}
