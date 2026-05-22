import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'app_lock_service.dart';
import 'app_logger.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._();
  static BiometricService get instance => _instance;
  BiometricService._();

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAvailable = false;
  List<BiometricType> _biometricTypes = [];

  bool get isAvailable => _isAvailable;
  List<BiometricType> get biometricTypes => _biometricTypes;
  bool get hasBiometric => _biometricTypes.isNotEmpty;

  Future<void> init() async {
    try {
      _isAvailable = await _localAuth.canCheckBiometrics;
      if (_isAvailable) {
        _biometricTypes = await _localAuth.getAvailableBiometrics();
      }
      AppLogger.instance.info(
        'Biometric: available=$_isAvailable, types=$_biometricTypes',
      );
    } on PlatformException catch (e) {
      AppLogger.instance.info('Biometric init failed: $e');
      _isAvailable = false;
      _biometricTypes = [];
    }
  }

  Future<bool> authenticate({String reason = 'Unlock Omnivium'}) async {
    if (!_isAvailable) return false;

    try {
      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (result) {
        AppLockService.instance.recordUnlock();
      }
      return result;
    } on PlatformException catch (e) {
      AppLogger.instance.info('Biometric auth failed: ${e.code} ${e.message}');
      return false;
    }
  }

  Future<bool> shouldShowBiometric() async {
    return _isAvailable && AppLockService.instance.isEnabled;
  }
}
