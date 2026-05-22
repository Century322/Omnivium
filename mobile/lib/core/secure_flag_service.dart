import 'package:flutter/services.dart';
import 'app_lock_service.dart';
import 'app_logger.dart';

class SecureFlagService {
  static final SecureFlagService _instance = SecureFlagService._();
  static SecureFlagService get instance => _instance;
  SecureFlagService._();

  static const _channel = MethodChannel('com.omnivium.mobile/security');
  bool _currentFlag = false;

  Future<void> init() async {
    final shouldBlock = AppLockService.instance.blockScreenshot;
    if (shouldBlock) {
      await setSecureFlag(true);
    }
  }

  Future<void> setSecureFlag(bool secure) async {
    if (_currentFlag == secure) return;
    try {
      await _channel.invokeMethod<bool>('setSecureFlag', secure);
      _currentFlag = secure;
    } on PlatformException catch (e) {
      AppLogger.instance.warning('SecureFlag: failed to set secure flag', error: e);
    }
  }

  Future<void> onAppLockEnabled() async {
    if (AppLockService.instance.blockScreenshot) {
      await setSecureFlag(true);
    }
  }

  Future<void> onAppLockDisabled() async {
    await setSecureFlag(false);
  }
}
