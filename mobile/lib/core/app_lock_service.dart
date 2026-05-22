import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';

class AppLockService {
  static final AppLockService _instance = AppLockService._();
  static AppLockService get instance => _instance;
  AppLockService._();

  static const _hashKey = 'omnivium_passcode_hash';
  static const _saltKey = 'omnivium_passcode_salt';
  static const _typeKey = 'omnivium_passcode_type';
  static const _autoLockKey = 'omnivium_auto_lock_minutes';
  static const _lastUnlockKey = 'omnivium_last_unlock_time';
  static const _attemptsKey = 'omnivium_passcode_attempts';
  static const _lockUntilKey = 'omnivium_lock_until';
  static const _screenshotKey = 'omnivium_block_screenshot';

  String? _hash;
  String? _salt;
  PasscodeType _type = PasscodeType.none;
  int _autoLockMinutes = 0;
  DateTime? _lastUnlockTime;
  int _failedAttempts = 0;
  DateTime? _lockUntil;
  bool _blockScreenshot = false;

  bool get isEnabled => _type != PasscodeType.none;
  bool get isPin => _type == PasscodeType.pin;
  bool get isPassword => _type == PasscodeType.password;
  PasscodeType get type => _type;
  bool get blockScreenshot => _blockScreenshot;
  int get autoLockMinutes => _autoLockMinutes;

  bool get isLocked {
    if (!isEnabled) return false;
    if (_lockUntil != null && DateTime.now().isBefore(_lockUntil!)) return true;
    if (_autoLockMinutes > 0 && _lastUnlockTime != null) {
      final elapsed = DateTime.now().difference(_lastUnlockTime!);
      if (elapsed.inMinutes >= _autoLockMinutes) return true;
    }
    return false;
  }

  int get lockoutSeconds {
    if (_lockUntil == null) return 0;
    final remaining = _lockUntil!.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  Future<void> init() async {
    final storage = SecureStorageService.instance;
    _hash = await storage.read(_hashKey);
    _salt = await storage.read(_saltKey);
    final typeStr = await storage.read(_typeKey);
    _type = typeStr == 'pin'
        ? PasscodeType.pin
        : typeStr == 'password'
        ? PasscodeType.password
        : PasscodeType.none;
    final autoLockStr = await storage.read(_autoLockKey);
    _autoLockMinutes = int.tryParse(autoLockStr ?? '') ?? 0;
    final lastUnlockStr = await storage.read(_lastUnlockKey);
    if (lastUnlockStr != null) {
      _lastUnlockTime = DateTime.tryParse(lastUnlockStr);
    }
    final attemptsStr = await storage.read(_attemptsKey);
    _failedAttempts = int.tryParse(attemptsStr ?? '') ?? 0;
    final lockUntilStr = await storage.read(_lockUntilKey);
    if (lockUntilStr != null) {
      _lockUntil = DateTime.tryParse(lockUntilStr);
    }
    final screenshotStr = await storage.read(_screenshotKey);
    _blockScreenshot = screenshotStr == 'true';
  }

  Future<void> setPasscode(String passcode, PasscodeType type) async {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    _salt = base64Encode(saltBytes);
    _type = type;

    final passcodeBytes = utf8.encode(passcode);
    final saltDecoded = base64Decode(_salt!);
    final bytes = List<int>.from(saltDecoded)
      ..addAll(passcodeBytes)
      ..addAll(saltDecoded);
    _hash = sha256.convert(bytes).toString();

    final storage = SecureStorageService.instance;
    await storage.write(_hashKey, _hash!);
    await storage.write(_saltKey, _salt!);
    await storage.write(
      _typeKey,
      type == PasscodeType.pin ? 'pin' : 'password',
    );
    _failedAttempts = 0;
    await storage.write(_attemptsKey, '0');
    await storage.delete(_lockUntilKey);
    _lockUntil = null;
  }

  Future<void> removePasscode() async {
    final storage = SecureStorageService.instance;
    await storage.delete(_hashKey);
    await storage.delete(_saltKey);
    await storage.delete(_typeKey);
    await storage.delete(_attemptsKey);
    await storage.delete(_lockUntilKey);
    _hash = null;
    _salt = null;
    _type = PasscodeType.none;
    _failedAttempts = 0;
    _lockUntil = null;
  }

  Future<bool> verify(String passcode) async {
    if (_hash == null || _salt == null) return true;

    if (_lockUntil != null && DateTime.now().isBefore(_lockUntil!)) {
      return false;
    }

    final passcodeBytes = utf8.encode(passcode);
    final saltDecoded = base64Decode(_salt!);
    final bytes = List<int>.from(saltDecoded)
      ..addAll(passcodeBytes)
      ..addAll(saltDecoded);
    final computedHash = sha256.convert(bytes).toString();

    final storage = SecureStorageService.instance;

    if (computedHash == _hash) {
      _failedAttempts = 0;
      _lockUntil = null;
      _lastUnlockTime = DateTime.now();
      await storage.write(_attemptsKey, '0');
      await storage.delete(_lockUntilKey);
      await storage.write(_lastUnlockKey, _lastUnlockTime!.toIso8601String());
      return true;
    } else {
      _failedAttempts++;
      await storage.write(_attemptsKey, _failedAttempts.toString());

      final lockoutSeconds = _calculateLockout(_failedAttempts);
      if (lockoutSeconds > 0) {
        _lockUntil = DateTime.now().add(Duration(seconds: lockoutSeconds));
        await storage.write(_lockUntilKey, _lockUntil!.toIso8601String());
      }
      return false;
    }
  }

  int _calculateLockout(int attempts) {
    if (attempts <= 3) return 0;
    if (attempts <= 6) return 5 * (attempts - 3);
    if (attempts <= 9) return 15 + 5 * (attempts - 6);
    return 30;
  }

  Future<void> setAutoLock(int minutes) async {
    _autoLockMinutes = minutes;
    final storage = SecureStorageService.instance;
    await storage.write(_autoLockKey, minutes.toString());
  }

  Future<void> setBlockScreenshot(bool block) async {
    _blockScreenshot = block;
    final storage = SecureStorageService.instance;
    await storage.write(_screenshotKey, block ? 'true' : 'false');
  }

  void recordUnlock() {
    _lastUnlockTime = DateTime.now();
    SecureStorageService.instance.write(
      _lastUnlockKey,
      _lastUnlockTime!.toIso8601String(),
    );
  }
}

enum PasscodeType { none, pin, password }
