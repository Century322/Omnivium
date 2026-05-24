import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/biometric_service.dart';

void main() {
  group('BiometricService', () {
    test('instance is singleton', () {
      expect(BiometricService.instance, same(BiometricService.instance));
    });

    test('isAvailable is false before init', () {
      final service = BiometricService.instance;
      expect(service.isAvailable, isFalse);
    });

    test('biometricTypes is empty before init', () {
      final service = BiometricService.instance;
      expect(service.biometricTypes, isEmpty);
    });

    test('hasBiometric is false before init', () {
      final service = BiometricService.instance;
      expect(service.hasBiometric, isFalse);
    });

    test('authenticate returns false when not available', () async {
      final service = BiometricService.instance;
      final result = await service.authenticate();
      expect(result, isFalse);
    });

    test('shouldShowBiometric returns false when not available', () async {
      final service = BiometricService.instance;
      final result = await service.shouldShowBiometric();
      expect(result, isFalse);
    });
  });
}
