import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_config.dart';

void main() {
  group('AppConfig', () {
    test('environment defaults to dev', () {
      expect(AppConfig.environment, AppEnvironment.dev);
    });

    test('isDev is true by default', () {
      expect(AppConfig.isDev, isTrue);
    });

    test('isStaging is false by default', () {
      expect(AppConfig.isStaging, isFalse);
    });

    test('isProd is false by default', () {
      expect(AppConfig.isProd, isFalse);
    });

    test('apiBaseUrl for dev', () {
      expect(AppConfig.apiBaseUrl, contains('10.0.2.2'));
    });

    test('appName for dev', () {
      expect(AppConfig.appName, 'Omnivium Dev');
    });

    test('enableSentry is false in dev', () {
      expect(AppConfig.enableSentry, isFalse);
    });

    test('enableVerboseLogging is true in dev', () {
      expect(AppConfig.enableVerboseLogging, isTrue);
    });

    test('enablePerformanceOverlay is true in dev', () {
      expect(AppConfig.enablePerformanceOverlay, isTrue);
    });

    test('enableHotReload is true in dev', () {
      expect(AppConfig.enableHotReload, isTrue);
    });

    test('toDiagnosticMap returns valid map', () {
      final map = AppConfig.toDiagnosticMap();
      expect(map, containsPair('environment', 'dev'));
      expect(map, containsPair('appName', 'Omnivium Dev'));
      expect(map, containsPair('apiBaseUrl', isNotNull));
      expect(map, containsPair('enableSentry', isFalse));
      expect(map, containsPair('enableVerboseLogging', isTrue));
    });

    test('AppEnvironment enum has all values', () {
      expect(AppEnvironment.values.length, 3);
      expect(AppEnvironment.values, contains(AppEnvironment.dev));
      expect(AppEnvironment.values, contains(AppEnvironment.staging));
      expect(AppEnvironment.values, contains(AppEnvironment.production));
    });
  });
}
