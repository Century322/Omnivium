import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/security_check_service.dart';

void main() {
  group('SecurityCheckService', () {
    test('isCompromised returns false by default', () {
      final service = SecurityCheckService.instance;
      expect(service.isCompromised, false);
    });

    test('isRooted returns false by default', () {
      final service = SecurityCheckService.instance;
      expect(service.isRooted, false);
    });

    test('isEmulator returns false by default', () {
      final service = SecurityCheckService.instance;
      expect(service.isEmulator, false);
    });

    test('isJailbroken returns false by default', () {
      final service = SecurityCheckService.instance;
      expect(service.isJailbroken, false);
    });
  });
}
