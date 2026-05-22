import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'push_notification_service.dart';
import 'notification_queue.dart';

final List<StreamSubscription> _firebaseSubs = [];

Future<void> initFirebaseMessaging(PushNotificationService service) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint(
      'Firebase init failed (google-services.json may be missing): $e',
    );
    return;
  }

  try {
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
      final token = await messaging.getToken();
      if (token != null) {
        service.setFcmToken(token);
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
    }
  } catch (e) {
    debugPrint('Firebase messaging setup failed: $e');
  }
}

void disposeFirebaseMessaging() {
  for (final sub in _firebaseSubs) {
    sub.cancel();
  }
  _firebaseSubs.clear();
}
