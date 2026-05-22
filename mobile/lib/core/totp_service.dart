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
  String? get secret => _secret;

  Future<void> init() async {
    final storage = SecureStorageService.instance;
    _secret = await storage.read(_secretKey);
    final enabledStr = await storage.read(_enabledKey);
    _enabled = enabledStr == 'true';
  }

  Future<String> generateSecret() async {
    final random = Random.secure();
    final keyBytes = List<int>.generate(20, (_) => random.nextInt(256));
    _secret = base64Encode(keyBytes);
    final storage = SecureStorageService.instance;
    await storage.write(_secretKey, _secret!);
    return _secret!;
  }

  Future<void> enable() async {
    if (_secret == null) await generateSecret();
    _enabled = true;
    final storage = SecureStorageService.instance;
    await storage.write(_enabledKey, 'true');
  }

  Future<void> disable() async {
    _enabled = false;
    final storage = SecureStorageService.instance;
    await storage.write(_enabledKey, 'false');
  }

  bool verify(String code) {
    if (!_enabled || _secret == null) return true;
    final now = DateTime.now().toUtc();
    final timeStep = now.millisecondsSinceEpoch ~/ 30000;
    for (var offset = -1; offset <= 1; offset++) {
      final expected = _generateCode(timeStep + offset);
      if (expected == code) return true;
    }
    return false;
  }

  String _generateCode(int timeStep) {
    final key = base64Decode(_secret!);
    final timeBytes = ByteData(8);
    timeBytes.setInt64(0, timeStep);
    final hmacBytes = Hmac(
      sha1,
      key,
    ).convert(timeBytes.buffer.asUint8List()).bytes;
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
    final encodedSecret = _secret != null
        ? base64Encode(base64Decode(_secret!))
        : '';
    return 'otpauth://totp/Omnivium:$username?secret=$encodedSecret&issuer=Omnivium&algorithm=SHA1&digits=6&period=30';
  }
}
