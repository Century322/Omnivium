import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/secure_flag_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureFlagService', () {
    test('instance is singleton', () {
      expect(SecureFlagService.instance, same(SecureFlagService.instance));
    });

    test('onAppLockEnabled does not throw', () async {
      final service = SecureFlagService.instance;
      expect(() => service.onAppLockEnabled(), returnsNormally);
    });

    test('onAppLockDisabled does not throw', () async {
      final service = SecureFlagService.instance;
      expect(() => service.onAppLockDisabled(), returnsNormally);
    });
  });
}
