import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_lock_service.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUp(() async {
    await setupTestEnv();
    await initSecureStorage();
  });

  group('AppLockService', () {
    test('initial state is not enabled', () async {
      final service = AppLockService.instance;
      await service.init();
      expect(service.isEnabled, isFalse);
      expect(service.isLocked, isFalse);
    });

    test('setPasscode enables lock', () async {
      final service = AppLockService.instance;
      await service.setPasscode('1234', PasscodeType.pin);
      expect(service.isEnabled, isTrue);
      expect(service.isPin, isTrue);
    });

    test('verify correct PIN', () async {
      final service = AppLockService.instance;
      await service.setPasscode('1234', PasscodeType.pin);
      expect(await service.verify('1234'), isTrue);
    });

    test('verify wrong PIN', () async {
      final service = AppLockService.instance;
      await service.setPasscode('1234', PasscodeType.pin);
      expect(await service.verify('0000'), isFalse);
    });

    test('setPasscode with password type', () async {
      final service = AppLockService.instance;
      await service.setPasscode('mySecret!', PasscodeType.password);
      expect(service.isPassword, isTrue);
      expect(await service.verify('mySecret!'), isTrue);
    });

    test('removePasscode disables lock', () async {
      final service = AppLockService.instance;
      await service.setPasscode('1234', PasscodeType.pin);
      await service.removePasscode();
      expect(service.isEnabled, isFalse);
    });

    test('verify returns true when no passcode set', () async {
      final service = AppLockService.instance;
      await service.removePasscode();
      expect(await service.verify('anything'), isTrue);
    });

    test('setAutoLock', () async {
      final service = AppLockService.instance;
      await service.setAutoLock(5);
      expect(service.autoLockMinutes, 5);
    });

    test('setBlockScreenshot', () async {
      final service = AppLockService.instance;
      await service.setBlockScreenshot(true);
      expect(service.blockScreenshot, isTrue);
      await service.setBlockScreenshot(false);
      expect(service.blockScreenshot, isFalse);
    });

    test('PasscodeType enum', () {
      expect(PasscodeType.none.index, 0);
      expect(PasscodeType.pin.index, 1);
      expect(PasscodeType.password.index, 2);
    });
  });
}
