import 'app_logger.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_proxy_service.dart';
import 'deep_link_service.dart';
import 'push_notification_service_stub.dart'
    if (dart.library.io) 'push_notification_service_io.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  static PushNotificationService get instance => _instance;
  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final StreamController<Map<String, dynamic>> _onMessageOpenedApp = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onMessageOpenedApp => _onMessageOpenedApp.stream;

  DateTime _lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _lastNotificationChannel;
  int _notificationIdCounter = 0;
  static const _notificationThrottleMs = 1000;

  Future<void> init() async {
    await _initLocalNotifications();
    if (!kIsWeb) {
      await initFirebaseMessaging(this);
    }
  }

  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = _parsePayload(response.payload!);
            _onMessageOpenedApp.add(data);
          } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
        }
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'Chat message notifications',
        importance: Importance.high,
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        'invites',
        'Invites',
        description: 'Friend and group invitations',
        importance: Importance.defaultImportance,
      ));
    }
  }

  void setFcmToken(String token) {
    _fcmToken = token;
    _registerTokenWithBackend();
  }

  Future<void> _registerTokenWithBackend() async {
    if (_fcmToken == null) return;
    final proxy = ApiProxyService.instance;
    if (!proxy.isConfigured) return;
    try {
      await proxy.registerDevice(
        deviceId: proxy.buildDeviceHeaders()['X-Device-Id'] ?? 'unknown',
        fcmToken: _fcmToken!,
        platform: defaultTargetPlatform.name,
        appVersion: proxy.buildDeviceHeaders()['X-App-Version'] ?? '1.0.0',
      );
    } catch (e, stackTrace) {
      AppLogger.instance.warning('Register FCM token failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String channelId = 'messages',
    int? id,
    Map<String, dynamic>? data,
  }) async {
    try {
      final now = DateTime.now();
      final elapsed = now.difference(_lastNotificationTime).inMilliseconds;
      if (elapsed < _notificationThrottleMs && _lastNotificationChannel == channelId) {
        return;
      }
      _lastNotificationTime = now;
      _lastNotificationChannel = channelId;

      final notificationId = id ?? (++_notificationIdCounter % 0x7FFFFFFF);
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'messages' ? 'Messages' : 'Invites',
        channelDescription: channelId == 'messages' ? 'Chat message notifications' : 'Friend and group invitations',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e, stackTrace) {
      AppLogger.instance.warning('Show local notification failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    try {
      if (Platform.isIOS) {
        await _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        final android = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
      }
    } catch (e, stackTrace) {
      AppLogger.instance.warning('Request notification permissions failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _localNotifications.cancel(id);
  }

  void dispose() {
    _onMessageOpenedApp.close();
  }

  void handleMessageOpened(Map<String, dynamic> data) {
    _onMessageOpenedApp.add(data);
    final sessionId = data['session_id'] as String?;
    final roomId = data['room_id'] as String?;
    if (sessionId != null || roomId != null) {
      DeepLinkService.instance.onDeepLink?.call(
        Uri(scheme: 'omnivium', host: sessionId != null ? 'chat' : 'room', queryParameters: {'id': sessionId ?? roomId}),
      );
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {'payload': payload};
    }
  }
}
