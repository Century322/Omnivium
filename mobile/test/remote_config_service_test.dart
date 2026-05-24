import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/remote_config_service.dart';

void main() {
  group('RemoteConfigService', () {
    test('instance is singleton', () {
      expect(RemoteConfigService.instance, same(RemoteConfigService.instance));
    });

    test('config returns empty map before init', () {
      final service = RemoteConfigService.instance;
      expect(service.config, isA<Map<String, dynamic>>());
    });

    test('getFeatureFlag returns defaultValue when not initialized', () {
      final service = RemoteConfigService.instance;
      expect(
        service.getFeatureFlag('unknown_flag', defaultValue: true),
        isTrue,
      );
      expect(
        service.getFeatureFlag('unknown_flag', defaultValue: false),
        isFalse,
      );
    });

    test('getValue returns defaultValue when not initialized', () {
      final service = RemoteConfigService.instance;
      expect(
        service.getValue<String>('missing_key', defaultValue: 'fallback'),
        'fallback',
      );
    });

    test('getInt returns defaultValue when not initialized', () {
      final service = RemoteConfigService.instance;
      expect(service.getInt('missing_key', defaultValue: 42), 42);
    });

    test('getDouble returns defaultValue when not initialized', () {
      final service = RemoteConfigService.instance;
      expect(service.getDouble('missing_key', defaultValue: 3.14), 3.14);
    });

    test('getUISchema returns null when not initialized', () {
      final service = RemoteConfigService.instance;
      expect(service.getUISchema('home_screen'), isNull);
    });

    test('maxMemories has default value', () {
      final service = RemoteConfigService.instance;
      expect(service.maxMemories, greaterThan(0));
    });

    test('maxCacheSize has default value', () {
      final service = RemoteConfigService.instance;
      expect(service.maxCacheSize, greaterThan(0));
    });

    test('maxInputLength has default value', () {
      final service = RemoteConfigService.instance;
      expect(service.maxInputLength, greaterThan(0));
    });

    test('memorySimilarityThreshold is between 0 and 1', () {
      final service = RemoteConfigService.instance;
      expect(service.memorySimilarityThreshold, inInclusiveRange(0.0, 1.0));
    });
  });
}
