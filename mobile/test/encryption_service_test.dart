import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/encryption_service.dart';
import 'helpers/test_helpers.dart';

void main() {
  bool storageReady = false;

  setUp(() async {
    await setupTestEnv();
    storageReady = await initSecureStorage();
  });

  group('EncryptionService', () {
    test('isReady false before init', () {
      final service = EncryptionService.instance;
      expect(service.isReady, isFalse);
    });

    test('encrypt returns plaintext when not initialized', () {
      final service = EncryptionService.instance;
      expect(service.encrypt('hello'), 'hello');
    });

    test('decrypt returns null when not initialized', () {
      final service = EncryptionService.instance;
      expect(service.decrypt('anything'), isNull);
    });

    test('init sets isReady', () async {
      if (!storageReady) return;
      final service = EncryptionService.instance;
      await service.init();
      expect(service.isReady, isTrue);
    }, skip: !storageReady);

    test('encrypt and decrypt roundtrip', () async {
      if (!storageReady) return;
      final service = EncryptionService.instance;
      await service.init();
      const plaintext = 'Hello, Omnivium!';
      final encrypted = service.encrypt(plaintext);
      expect(encrypted, isNot(equals(plaintext)));
      final decrypted = service.decrypt(encrypted);
      expect(decrypted, plaintext);
    }, skip: !storageReady);

    test('encrypt produces different ciphertext each time', () async {
      if (!storageReady) return;
      final service = EncryptionService.instance;
      await service.init();
      const plaintext = 'same input';
      final encrypted1 = service.encrypt(plaintext);
      final encrypted2 = service.encrypt(plaintext);
      expect(encrypted1, isNot(equals(encrypted2)));
    }, skip: !storageReady);

    test('decrypt invalid data returns null', () async {
      if (!storageReady) return;
      final service = EncryptionService.instance;
      await service.init();
      expect(service.decrypt('not-valid-base64!!!'), isNull);
    }, skip: !storageReady);

    test('decrypt too short data returns null', () async {
      if (!storageReady) return;
      final service = EncryptionService.instance;
      await service.init();
      final short = base64Encode([1, 2, 3]);
      expect(service.decrypt(short), isNull);
    }, skip: !storageReady);

    test('decrypt wrong ciphertext returns null', () async {
      if (!storageReady) return;
      final service = EncryptionService.instance;
      await service.init();
      final fake = base64Encode(List<int>.generate(30, (i) => i));
      expect(service.decrypt(fake), isNull);
    }, skip: !storageReady);
  });
}
