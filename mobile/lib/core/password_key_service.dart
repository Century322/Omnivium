import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';

class PasswordKeyService {
  static final PasswordKeyService _instance = PasswordKeyService._();
  static PasswordKeyService get instance => _instance;
  PasswordKeyService._();

  static const _saltKey = 'omnivium_key_salt';
  static const _iterations = 100000;

  Uint8List? _salt;

  bool get isReady => _salt != null;

  Future<void> init() async {
    final storage = SecureStorageService.instance;
    final saltStr = await storage.read(_saltKey);
    if (saltStr != null) _salt = base64Decode(saltStr);
  }

  Future<Uint8List> deriveKey(String password) async {
    final s = _salt ?? _generateSalt();
    if (_salt == null) {
      _salt = s;
      await SecureStorageService.instance.write(_saltKey, base64Encode(s));
    }

    final passwordBytes = utf8.encode(password);
    var hash = sha256.convert([...s, ...passwordBytes, ...s]).bytes;

    for (var i = 0; i < 3; i++) {
      hash = sha256.convert([...s, ...hash, ...s]).bytes;
    }

    hash = _pbkdf2(hash, s, _iterations);
    hash = sha256.convert([...s, ...hash, ...s]).bytes;

    return Uint8List.fromList(hash);
  }

  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }

  Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations) {
    var block = <int>[];
    block.addAll(salt);
    block.addAll([0, 0, 0, 1]);

    var u = Hmac(sha512, password).convert(block).bytes;
    var result = List<int>.from(u);

    for (var i = 1; i < iterations; i++) {
      u = Hmac(sha512, password).convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return Uint8List.fromList(sha256.convert(result).bytes);
  }

  Future<void> clear() async {
    _salt = null;
    await SecureStorageService.instance.delete(_saltKey);
  }
}
