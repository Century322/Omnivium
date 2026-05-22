import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'secure_storage_service.dart';
import 'app_logger.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  static EncryptionService get instance => _instance;
  EncryptionService._();

  static const _keyKey = 'omnivium_encryption_key';
  Key? _key;

  bool get isReady => _key != null;

  Future<void> init() async {
    final storage = SecureStorageService.instance;
    var keyBase64 = await storage.read(_keyKey);
    if (keyBase64 == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      keyBase64 = base64Encode(keyBytes);
      await storage.write(_keyKey, keyBase64);
    }
    _key = Key.fromBase64(keyBase64);
  }

  String encrypt(String plaintext) {
    if (_key == null) return plaintext;
    final iv = IV.fromSecureRandom(12);
    final encrypter = Encrypter(AES(_key!, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    final output = Uint8List(12 + encrypted.bytes.length);
    output.setRange(0, 12, iv.bytes);
    output.setRange(12, output.length, encrypted.bytes);
    return base64Encode(output);
  }

  String? decrypt(String ciphertext) {
    if (_key == null) return null;
    try {
      final raw = base64Decode(ciphertext);
      if (raw.length < 13) return null;
      final ivBytes = raw.sublist(0, 12);
      final data = raw.sublist(12);
      final iv = IV(ivBytes);
      final encrypter = Encrypter(AES(_key!, mode: AESMode.gcm));
      return encrypter.decrypt64(base64Encode(data), iv: iv);
    } catch (e) {
      AppLogger.instance.info('Decryption failed: $e');
      return null;
    }
  }
}
