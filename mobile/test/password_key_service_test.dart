import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/password_key_service.dart';
import 'helpers/test_helpers.dart';

void main() {
  bool storageReady = false;

  setUp(() async {
    await setupTestEnv();
    storageReady = await initSecureStorage();
  });

  group('PasswordKeyService', () {
    test('initial state is not ready', () async {
      if (!storageReady) return;
      final service = PasswordKeyService.instance;
      await service.clear();
      expect(service.isReady, isFalse);
    });

    test('deriveKey makes service ready', () async {
      if (!storageReady) return;
      final service = PasswordKeyService.instance;
      await service.clear();
      await service.deriveKey('password123');
      expect(service.isReady, isTrue);
    });

    test('deriveKey produces consistent results for same input', () async {
      if (!storageReady) return;
      final service = PasswordKeyService.instance;
      await service.clear();
      final key1 = await service.deriveKey('password');
      final key2 = await service.deriveKey('password');
      expect(key1, equals(key2));
    });

    test(
      'deriveKey produces different results for different passwords',
      () async {
        if (!storageReady) return;
        final service = PasswordKeyService.instance;
        await service.clear();
        final key1 = await service.deriveKey('pass1');
        final key2 = await service.deriveKey('pass2');
        expect(key1, isNot(equals(key2)));
      },
    );

    test('clear removes all data', () async {
      if (!storageReady) return;
      final service = PasswordKeyService.instance;
      await service.deriveKey('password123');
      await service.clear();
      expect(service.isReady, isFalse);
    });
  });
}
