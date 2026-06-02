
import 'di/app_di.dart';
import 'app_logger.dart';
import 'notification_center.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io' if (dart.library.html) '';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_proxy_service.dart';
import 'auth_service.dart';
import 'deep_link_service.dart';
import 'encryption_service.dart';
import 'push_notification_service_stub.dart'
    if (dart.library.io) 'push_notification_service_io.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  static PushNotificationService get instance => _instance;
  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  Timer? _registerRetryTimer;
  int _registerRetryCount = 0;
  static const _maxRegisterRetries = 5;
  static const _registerRetryDelays = [2, 5, 15, 60, 300];

  final StreamController<Map<String, dynamic>> _onMessageOpenedApp =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      _onMessageOpenedApp.stream;

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
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false);
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = _parsePayload(payload);
            _onMessageOpenedApp.add(data);
          } catch (e, stackTrace) {
            AppLogger.instance.error(
              'App error',
              error: e,
              stackTrace: stackTrace);
          }
        }
      });

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'messages',
          'Messages',
          description: 'Chat message notifications',
          importance: Importance.high));
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'invites',
          'Invites',
          description: 'Friend and group invitations',
          importance: Importance.defaultImportance));
    }
  }

  void setFcmToken(String token) {
    _fcmToken = token;
    _registerRetryCount = 0;
    _registerTokenWithBackend();
  }

  Future<void> _registerTokenWithBackend() async {
    final token = _fcmToken;
    if (token == null) return;
    final proxy = getIt<ApiProxyService>();
    if (!proxy.isConfigured) {
      _scheduleRegisterRetry();
      return;
    }
    try {
      final userId = getIt<AuthService>().currentUser?.id;
      final success = await proxy.registerDevice(
        deviceId: proxy.buildDeviceHeaders()['X-Device-Id'] ?? 'unknown',
        fcmToken: token,
        platform: defaultTargetPlatform.name,
        appVersion: proxy.buildDeviceHeaders()['X-App-Version'] ?? '1.0.0',
        userId: userId);
      if (success) {
        _registerRetryCount = 0;
        AppLogger.instance.info('FCM token registered successfully');
      } else {
        _scheduleRegisterRetry();
      }
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Register FCM token failed',
        error: e,
        stackTrace: stackTrace);
      _scheduleRegisterRetry();
    }
  }

  void _scheduleRegisterRetry() {
    if (_registerRetryCount >= _maxRegisterRetries) {
      AppLogger.instance.warning(
        'FCM token registration exhausted $_maxRegisterRetries retries');
      return;
    }
    _registerRetryTimer?.cancel();
    final delaySeconds = _registerRetryDelays[_registerRetryCount];
    _registerRetryCount++;
    AppLogger.instance.info(
      'FCM token registration retry #$_registerRetryCount in ${delaySeconds}s');
    _registerRetryTimer = Timer(
      Duration(seconds: delaySeconds),
      () => _registerTokenWithBackend());
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String channelId = 'messages',
    int? id,
    Map<String, dynamic>? data,
  }) async {
    try {
      String displayTitle = title;
      String displayBody = body;
      final enc = getIt<EncryptionService>();
      if (enc.isReady && data?['encrypted'] == '1') {
        final decryptedTitle = enc.decrypt(title);
        final decryptedBody = enc.decrypt(body);
        if (decryptedTitle != null) displayTitle = decryptedTitle;
        if (decryptedBody != null) displayBody = decryptedBody;
      }

      final now = DateTime.now();
      final elapsed = now.difference(_lastNotificationTime).inMilliseconds;
      if (elapsed < _notificationThrottleMs &&
          _lastNotificationChannel == channelId) {
        return;
      }
      _lastNotificationTime = now;
      _lastNotificationChannel = channelId;

      final notificationId = id ?? (++_notificationIdCounter % 0x7FFFFFFF);
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'messages' ? 'Messages' : 'Invites',
        channelDescription: channelId == 'messages'
            ? 'Chat message notifications'
            : 'Friend and group invitations',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true);
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails);

      await _localNotifications.show(
        notificationId,
        displayTitle,
        displayBody,
        details,
        payload: data != null ? jsonEncode(data) : null);
      NotificationCenter.post(
        Event.pushNotification,
        data: {'title': displayTitle, 'body': displayBody, 'data': data});
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Show local notification failed',
        error: e,
        stackTrace: stackTrace);
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    try {
      if (Platform.isIOS) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } else if (Platform.isAndroid) {
        final android = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await android?.requestNotificationsPermission();
      }
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Request notification permissions failed',
        error: e,
        stackTrace: stackTrace);
    }
  }

  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _localNotifications.cancel(id);
  }

  void dispose() {
    _registerRetryTimer?.cancel();
    _onMessageOpenedApp.close();
  }

  void handleMessageOpened(Map<String, dynamic> data) {
    _onMessageOpenedApp.add(data);
    final sessionId = data['session_id'] as String?;
    final roomId = data['room_id'] as String?;
    if (sessionId != null || roomId != null) {
      DeepLinkService.instance.onDeepLink?.call(
        Uri(
          scheme: 'omnivium',
          host: sessionId != null ? 'chat' : 'room',
          queryParameters: {'id': sessionId ?? roomId}));
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.instance.debug('Push payload decode failed', error: e);
      return {'payload': payload};
    }
  }
}
