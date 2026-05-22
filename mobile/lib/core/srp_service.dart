import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';
import 'api_proxy_service.dart';
import 'app_logger.dart';

class SrpService {
  static final SrpService _instance = SrpService._();
  static SrpService get instance => _instance;
  SrpService._();

  static const _saltKey = 'omnivium_srp_salt';
  static const _verifierKey = 'omnivium_srp_verifier';
  static const _usernameKey = 'omnivium_srp_username';
  static const _iterations = 100000;

  Uint8List? _salt;
  String? _verifier;
  String? _username;

  bool get hasVerifier => _verifier != null;
  String? get username => _username;

  Future<void> init() async {
    final storage = SecureStorageService.instance;
    final saltStr = await storage.read(_saltKey);
    if (saltStr != null) _salt = base64Decode(saltStr);
    _verifier = await storage.read(_verifierKey);
    _username = await storage.read(_usernameKey);
  }

  Future<String> createVerifier(String username, String password) async {
    _salt = _generateSalt();
    _username = username;
    final key = await deriveKey(password, salt: _salt);
    _verifier = base64Encode(key);

    final storage = SecureStorageService.instance;
    await storage.write(_saltKey, base64Encode(_salt!));
    await storage.write(_verifierKey, _verifier!);
    await storage.write(_usernameKey, username);

    await _registerWithWorker(username, _verifier!, base64Encode(_salt!));

    return _verifier!;
  }

  Future<void> _registerWithWorker(
    String username,
    String verifier,
    String salt,
  ) async {
    try {
      final proxy = ApiProxyService.instance;
      await proxy.secureClient.post(
        Uri.parse('${proxy.backendUrl}/auth/srp-register'),
        headers: {
          ...proxy.buildAuthHeaders(),
          ...proxy.buildDeviceHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'verifier': verifier,
          'salt': salt,
        }),
      );
    } catch (e) {
      AppLogger.instance.info('SRP register with worker failed: $e');
    }
  }

  Future<Map<String, dynamic>?> srpLogin(
    String username,
    String password,
  ) async {
    final key = await deriveKey(password, salt: _salt);
    final proof = base64Encode(key);
    final srpId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final proxy = ApiProxyService.instance;
      final response = await proxy.secureClient.post(
        Uri.parse('${proxy.backendUrl}/auth/srp-login'),
        headers: {
          ...proxy.buildDeviceHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'srp_proof': proof,
          'srp_id': srpId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLogger.instance.info('SRP login failed: $e');
    }
    return null;
  }

  Future<Uint8List> deriveKey(String password, {Uint8List? salt}) async {
    final s = salt ?? _salt ?? _generateSalt();
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

  Future<bool> verifyPassword(String password) async {
    if (_salt == null || _verifier == null) return false;

    final key = await deriveKey(password, salt: _salt);
    final keyBase64 = base64Encode(key);

    return keyBase64 == _verifier;
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
    _verifier = null;
    _username = null;
    final storage = SecureStorageService.instance;
    await storage.delete(_saltKey);
    await storage.delete(_verifierKey);
    await storage.delete(_usernameKey);
  }
}
