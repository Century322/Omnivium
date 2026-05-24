import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/srp_service.dart';
import 'helpers/test_helpers.dart';

void main() {
  bool storageReady = false;

  setUp(() async {
    await setupTestEnv();
    storageReady = await initSecureStorage();
  });

  group('SrpService', () {
    test('initial state has no verifier', () async {
      if (!storageReady) return;
      final service = SrpService.instance;
      await service.clear();
      expect(service.hasVerifier, isFalse);
      expect(service.username, isNull);
    }, skip: !storageReady);

    test('createVerifier generates verifier', () async {
      if (!storageReady) return;
      final service = SrpService.instance;
      await service.clear();
      final verifier = await service.createVerifier('testuser', 'password123');
      expect(verifier, isNotEmpty);
      expect(service.hasVerifier, isTrue);
      expect(service.username, 'testuser');
    }, skip: !storageReady);

    test('verifyPassword with correct password', () async {
      if (!storageReady) return;
      final service = SrpService.instance;
      await service.clear();
      await service.createVerifier('testuser', 'password123');
      expect(await service.verifyPassword('password123'), isTrue);
    }, skip: !storageReady);

    test('verifyPassword with wrong password', () async {
      if (!storageReady) return;
      final service = SrpService.instance;
      await service.clear();
      await service.createVerifier('testuser', 'password123');
      expect(await service.verifyPassword('wrongpassword'), isFalse);
    }, skip: !storageReady);

    test('verifyPassword returns false when no verifier', () async {
      if (!storageReady) return;
      final service = SrpService.instance;
      await service.clear();
      expect(await service.verifyPassword('anything'), isFalse);
    }, skip: !storageReady);

    test('deriveKey produces consistent results for same input', () async {
      if (!storageReady) return;
      final service = SrpService.instance;
      await service.clear();
      final key1 = await service.deriveKey('password');
      final key2 = await service.deriveKey('password');
      expect(key1, equals(key2));
    }, skip: !storageReady);

    test(
      'deriveKey produces different results for different passwords',
      () async {
        if (!storageReady) return;
        final service = SrpService.instance;
        await service.clear();
        final key1 = await service.deriveKey('pass1');
        final key2 = await service.deriveKey('pass2');
        expect(key1, isNot(equals(key2)));
      },
      skip: !storageReady,
    );

    test('clear removes all data', () async {
      if (!storageReady) return;
      final service = SrpService.instance;
      await service.createVerifier('testuser', 'password123');
      await service.clear();
      expect(service.hasVerifier, isFalse);
      expect(service.username, isNull);
    }, skip: !storageReady);

    test(
      'createVerifier with different users produces different verifiers',
      () async {
        if (!storageReady) return;
        final service = SrpService.instance;
        await service.clear();
        final v1 = await service.createVerifier('user1', 'samepass');
        await service.clear();
        final v2 = await service.createVerifier('user2', 'samepass');
        expect(v1, isNot(equals(v2)));
      },
      skip: !storageReady,
    );
  });
}
