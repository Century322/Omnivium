import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:omnivium/core/totp_service.dart';
import 'helpers/test_helpers.dart';

String generateTotpCode(String secret, int timeStep) {
  final key = base64Decode(secret);
  final timeBytes = Uint8List(8);
  final data = ByteData.view(timeBytes.buffer);
  data.setInt64(0, timeStep);
  final hmacBytes = Hmac(sha1, key).convert(timeBytes).bytes;
  final offset = hmacBytes[hmacBytes.length - 1] & 0x0f;
  final binary =
      ((hmacBytes[offset] & 0x7f) << 24) |
      ((hmacBytes[offset + 1] & 0xff) << 16) |
      ((hmacBytes[offset + 2] & 0xff) << 8) |
      (hmacBytes[offset + 3] & 0xff);
  final otp = binary % 1000000;
  return otp.toString().padLeft(6, '0');
}

void main() {
  bool storageReady = false;

  setUp(() async {
    await setupTestEnv();
    storageReady = await initSecureStorage();
  });

  group('TotpService', () {
    test('initial state', () {
      final service = TotpService.instance;
      expect(service.isEnabled, isFalse);
    });

    test('generateSecret returns base64 string', () async {
      if (!storageReady) return;
      final service = TotpService.instance;
      final secret = await service.generateSecret();
      expect(secret, isNotEmpty);
      expect(() => base64Decode(secret), returnsNormally);
    });

    test('enable sets isEnabled true', () async {
      if (!storageReady) return;
      final service = TotpService.instance;
      await service.enable();
      expect(service.isEnabled, isTrue);
    });

    test('disable sets isEnabled false', () async {
      if (!storageReady) return;
      final service = TotpService.instance;
      await service.enable();
      await service.disable();
      expect(service.isEnabled, isFalse);
    });

    test('getOtpAuthUri returns valid URI', () async {
      if (!storageReady) return;
      final service = TotpService.instance;
      await service.generateSecret();
      final uri = service.getOtpAuthUri('testuser');
      expect(uri, startsWith('otpauth://totp/Omnivium:testuser'));
      expect(uri, contains('issuer=Omnivium'));
      expect(uri, contains('algorithm=SHA1'));
      expect(uri, contains('digits=6'));
      expect(uri, contains('period=30'));
    });

    test('verify accepts valid code for current time step', () async {
      if (!storageReady) return;
      final service = TotpService.instance;
      final secret = await service.generateSecret();
      await service.enable();
      final timeStep = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 30000;
      final code = generateTotpCode(secret, timeStep);
      expect(service.verify(code), isTrue);
    });

    test('verify rejects invalid code', () async {
      if (!storageReady) return;
      final service = TotpService.instance;
      await service.enable();
      expect(service.verify('000000'), isFalse);
    });

    test('verify accepts code within time window offset -1', () async {
      if (!storageReady) return;
      final service = TotpService.instance;
      final secret = await service.generateSecret();
      await service.enable();
      final timeStep = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 30000;
      final codePrev = generateTotpCode(secret, timeStep - 1);
      expect(service.verify(codePrev), isTrue);
    });
  });
}
