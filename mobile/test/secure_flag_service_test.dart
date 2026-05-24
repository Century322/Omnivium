import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/secure_flag_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.omnivium.mobile/security'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'setSecureFlag':
                return true;
              default:
                return null;
            }
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.omnivium.mobile/security'),
          null,
        );
  });

  group('SecureFlagService', () {
    test('instance is singleton', () {
      expect(SecureFlagService.instance, same(SecureFlagService.instance));
    });

    test('onAppLockEnabled does not throw', () async {
      final service = SecureFlagService.instance;
      await expectLater(service.onAppLockEnabled(), completes);
    });

    test('onAppLockDisabled does not throw', () async {
      final service = SecureFlagService.instance;
      await expectLater(service.onAppLockDisabled(), completes);
    });
  });
}
