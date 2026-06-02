import 'app_logger.dart';
import 'security_check_service_stub.dart'
    if (dart.library.io) 'security_check_service_io.dart';

class SecurityCheckService {
  static final SecurityCheckService _instance = SecurityCheckService._();
  static SecurityCheckService get instance => _instance;
  SecurityCheckService._();

  bool? _isRooted;
  bool? _isJailbroken;
  bool? _isEmulator;

  bool get isRooted => _isRooted ?? false;
  bool get isJailbroken => _isJailbroken ?? false;
  bool get isEmulator => _isEmulator ?? false;
  bool get isCompromised => isRooted || isJailbroken || isEmulator;

  Future<void> check() async {
    final result = await performSecurityCheck();
    _isRooted = result['rooted'] ?? false;
    _isJailbroken = result['jailbroken'] ?? false;
    _isEmulator = result['emulator'] ?? false;
    AppLogger.instance.info(
      'Security check: rooted=$_isRooted, jailbroken=$_isJailbroken, emulator=$_isEmulator');
  }
}
