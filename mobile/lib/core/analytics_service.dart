import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;
  AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _enabled = true;

  FirebaseAnalytics? get analytics => _analytics;

  Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final analytics = FirebaseAnalytics.instance;
      _analytics = analytics;
      await analytics.setAnalyticsCollectionEnabled(!kDebugMode);
      AppLogger.instance.info('Analytics initialized');
    } catch (e) {
      AppLogger.instance.warning('Analytics init failed', error: e);
    }
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    _analytics?.setAnalyticsCollectionEnabled(enabled);
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_enabled) return;
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      AppLogger.instance.warning('Analytics logEvent failed', error: e);
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_enabled) return;
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      AppLogger.instance.warning('Analytics setUserProperty failed', error: e);
    }
  }

  Future<void> logAppOpen() => logEvent(name: 'app_open');

  Future<void> logLogin({required String method}) =>
      logEvent(name: 'login', parameters: {'method': method});

  Future<void> logSignUp({required String method}) =>
      logEvent(name: 'sign_up', parameters: {'method': method});

  Future<void> logSendMessage({required String type}) =>
      logEvent(name: 'send_message', parameters: {'type': type});

  Future<void> logVoiceCall() => logEvent(name: 'voice_call');

  Future<void> logVideoCall() => logEvent(name: 'video_call');

  Future<void> logAiQuery({required String model}) =>
      logEvent(name: 'ai_query', parameters: {'model': model});

  Future<void> logScreenView({required String screenName}) =>
      logEvent(name: 'screen_view', parameters: {'screen_name': screenName});

  Future<void> logSearch({required String query}) =>
      logEvent(name: 'search', parameters: {'query': query});

  Future<void> logShare({required String contentType}) =>
      logEvent(name: 'share', parameters: {'content_type': contentType});

  Future<void> logAddContact() => logEvent(name: 'add_contact');

  Future<void> logCreateGroup() => logEvent(name: 'create_group');

  Future<void> logChangeLanguage({required String language}) =>
      logEvent(name: 'change_language', parameters: {'language': language});

  Future<void> logToggleSetting({
    required String setting,
    required bool value,
  }) => logEvent(
    name: 'toggle_setting',
    parameters: {'setting': setting, 'value': value});
}
