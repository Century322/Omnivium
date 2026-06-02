
import 'di/app_di.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';

class TotpService {
  static final TotpService _instance = TotpService._();
  static TotpService get instance => _instance;
  TotpService._();

  static const _secretKey = 'omnivium_totp_secret';
  static const _enabledKey = 'omnivium_totp_enabled';

  String? _secret;
  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> init() async {
    final storage = getIt<SecureStorageService>();
    _secret = await storage.read(_secretKey);
    final enabledStr = await storage.read(_enabledKey);
    _enabled = enabledStr == 'true';
  }

  Future<String> generateSecret() async {
    final random = Random.secure();
    final keyBytes = List<int>.generate(20, (_) => random.nextInt(256));
    final secret = base64Encode(keyBytes);
    _secret = secret;
    final storage = getIt<SecureStorageService>();
    await storage.write(_secretKey, secret);
    return secret;
  }

  Future<void> enable() async {
    if (_secret == null) await generateSecret();
    _enabled = true;
    final storage = getIt<SecureStorageService>();
    await storage.write(_enabledKey, 'true');
  }

  Future<void> disable() async {
    _enabled = false;
    final storage = getIt<SecureStorageService>();
    await storage.write(_enabledKey, 'false');
  }

  bool verify(String code) {
    if (!_enabled || _secret == null) return true;
    final secret = _secret;
    if (secret == null) return true;
    final now = DateTime.now().toUtc();
    final timeStep = now.millisecondsSinceEpoch ~/ 30000;
    for (var offset = -1; offset <= 1; offset++) {
      final expected = _generateCode(timeStep + offset, secret);
      if (expected == code) return true;
    }
    return false;
  }

  String _generateCode(int timeStep, String secret) {
    final key = base64Decode(secret);
    final timeBytes = ByteData(8);
    timeBytes.setInt64(0, timeStep);
    final hmacBytes = Hmac(
      sha1,
      key).convert(timeBytes.buffer.asUint8List()).bytes;
    final offset = hmacBytes[hmacBytes.length - 1] & 0x0f;
    final binary =
        ((hmacBytes[offset] & 0x7f) << 24) |
        ((hmacBytes[offset + 1] & 0xff) << 16) |
        ((hmacBytes[offset + 2] & 0xff) << 8) |
        (hmacBytes[offset + 3] & 0xff);
    final otp = binary % 1000000;
    return otp.toString().padLeft(6, '0');
  }

  String getOtpAuthUri(String username) {
    final secret = _secret;
    final encodedSecret = secret != null
        ? base64Encode(base64Decode(secret))
        : '';
    return 'otpauth://totp/Omnivium:$username?secret=$encodedSecret&issuer=Omnivium&algorithm=SHA1&digits=6&period=30';
  }
}
