import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    test('instance is singleton', () {
      expect(AnalyticsService.instance, same(AnalyticsService.instance));
    });

    test('analytics getter returns null before init', () {
      final service = AnalyticsService.instance;
      expect(service.analytics, isNull);
    });

    test('logEvent does not throw before init', () async {
      final service = AnalyticsService.instance;
      expect(() => service.logEvent(name: 'test_event'), returnsNormally);
    });

    test('logAppOpen does not throw', () async {
      final service = AnalyticsService.instance;
      expect(() => service.logAppOpen(), returnsNormally);
    });

    test('logLogin does not throw', () async {
      final service = AnalyticsService.instance;
      expect(() => service.logLogin(method: 'email'), returnsNormally);
    });

    test('logSignUp does not throw', () async {
      final service = AnalyticsService.instance;
      expect(() => service.logSignUp(method: 'email'), returnsNormally);
    });

    test('logSendMessage does not throw', () async {
      final service = AnalyticsService.instance;
      expect(() => service.logSendMessage(type: 'text'), returnsNormally);
    });

    test('logVoiceCall does not throw', () async {
      final service = AnalyticsService.instance;
      expect(() => service.logVoiceCall(), returnsNormally);
    });

    test('logVideoCall does not throw', () async {
      final service = AnalyticsService.instance;
      expect(() => service.logVideoCall(), returnsNormally);
    });

    test('logAiQuery does not throw', () async {
      final service = AnalyticsService.instance;
      expect(() => service.logAiQuery(model: 'gpt-4'), returnsNormally);
    });

    test('logScreenView does not throw', () async {
      final service = AnalyticsService.instance;
      expect(() => service.logScreenView(screenName: 'home'), returnsNormally);
    });

    test('logSearch does not throw', () async {
      final service = AnalyticsService.instance;
      expect(() => service.logSearch(query: 'test'), returnsNormally);
    });

    test('setEnabled does not throw', () {
      final service = AnalyticsService.instance;
      expect(() => service.setEnabled(false), returnsNormally);
      expect(() => service.setEnabled(true), returnsNormally);
    });
  });
}
