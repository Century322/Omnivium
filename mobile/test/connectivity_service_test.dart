import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/connectivity_service.dart';

void main() {
  group('NetworkQuality', () {
    test('has all expected values', () {
      expect(NetworkQuality.values, contains(NetworkQuality.excellent));
      expect(NetworkQuality.values, contains(NetworkQuality.good));
      expect(NetworkQuality.values, contains(NetworkQuality.poor));
      expect(NetworkQuality.values, contains(NetworkQuality.unknown));
    });
  });

  group('ConnectivityService', () {
    test('initial state', () {
      final service = ConnectivityService.instance;
      expect(service.isInitialized, isFalse);
    });

    test('dispose does not throw', () {
      final service = ConnectivityService.instance;
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
