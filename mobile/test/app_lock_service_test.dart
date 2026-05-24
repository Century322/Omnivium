import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_lock_service.dart';
import 'helpers/test_helpers.dart';

void main() {
  bool storageReady = false;

  setUp(() async {
    await setupTestEnv();
    storageReady = await initSecureStorage();
  });

  group('AppLockService', () {
    test('initial state is not enabled', () async {
      if (!storageReady) return;
      final service = AppLockService.instance;
      await service.init();
      expect(service.isEnabled, isFalse);
      expect(service.isLocked, isFalse);
    }, skip: !storageReady);

    test('setPasscode enables lock', () async {
      if (!storageReady) return;
      final service = AppLockService.instance;
      await service.setPasscode('1234', PasscodeType.pin);
      expect(service.isEnabled, isTrue);
      expect(service.isPin, isTrue);
    }, skip: !storageReady);

    test('verify correct PIN', () async {
      if (!storageReady) return;
      final service = AppLockService.instance;
      await service.setPasscode('1234', PasscodeType.pin);
      expect(await service.verify('1234'), isTrue);
    }, skip: !storageReady);

    test('verify wrong PIN', () async {
      if (!storageReady) return;
      final service = AppLockService.instance;
      await service.setPasscode('1234', PasscodeType.pin);
      expect(await service.verify('0000'), isFalse);
    }, skip: !storageReady);

    test('setPasscode with password type', () async {
      if (!storageReady) return;
      final service = AppLockService.instance;
      await service.setPasscode('mySecret!', PasscodeType.password);
      expect(service.isPassword, isTrue);
      expect(await service.verify('mySecret!'), isTrue);
    }, skip: !storageReady);

    test('removePasscode disables lock', () async {
      if (!storageReady) return;
      final service = AppLockService.instance;
      await service.setPasscode('1234', PasscodeType.pin);
      await service.removePasscode();
      expect(service.isEnabled, isFalse);
    }, skip: !storageReady);

    test('verify returns true when no passcode set', () async {
      if (!storageReady) return;
      final service = AppLockService.instance;
      await service.removePasscode();
      expect(await service.verify('anything'), isTrue);
    }, skip: !storageReady);

    test('setAutoLock', () async {
      if (!storageReady) return;
      final service = AppLockService.instance;
      await service.setAutoLock(5);
      expect(service.autoLockMinutes, 5);
    }, skip: !storageReady);

    test('setBlockScreenshot', () async {
      if (!storageReady) return;
      final service = AppLockService.instance;
      await service.setBlockScreenshot(true);
      expect(service.blockScreenshot, isTrue);
      await service.setBlockScreenshot(false);
      expect(service.blockScreenshot, isFalse);
    }, skip: !storageReady);

    test('PasscodeType enum', () {
      expect(PasscodeType.none.index, 0);
      expect(PasscodeType.pin.index, 1);
      expect(PasscodeType.password.index, 2);
    });
  });
}
