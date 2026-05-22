import 'app_logger.dart';
import 'dart:io';

Future<Map<String, bool>> performSecurityCheck() async {
  bool rooted = false;
  bool jailbroken = false;
  bool emulator = false;

  if (Platform.isAndroid) {
    final rootPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
      '/magisk/.core/bin/su',
    ];
    for (final path in rootPaths) {
      try {
        if (await File(path).exists()) {
          rooted = true;
          break;
        }
      } catch (e, stackTrace) {
        AppLogger.instance.warning(
          'Root check path access failed',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    try {
      final result = await Process.run('which', ['su']);
      if (result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty) {
        rooted = true;
      }
    } catch (_) {}

    emulator = await _checkAndroidEmulator();
  }

  if (Platform.isIOS) {
    final jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/private/var/lib/cydia',
      '/private/var/tmp/cydia.log',
      '/System/Library/Lydia',
    ];
    for (final path in jailbreakPaths) {
      try {
        if (await File(path).exists()) {
          jailbroken = true;
          break;
        }
      } catch (e, stackTrace) {
        AppLogger.instance.warning(
          'Jailbreak check path access failed',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    emulator = await _checkIOSEmulator();
  }

  return {'rooted': rooted, 'jailbroken': jailbroken, 'emulator': emulator};
}

Future<bool> _checkAndroidEmulator() async {
  final indicators = <String, bool>{};

  try {
    final buildProps = File('/system/build.prop');
    if (await buildProps.exists()) {
      final content = await buildProps.readAsString();
      indicators['product_model'] =
          content.contains('sdk') ||
          content.contains('google_sdk') ||
          content.contains('Emulator') ||
          content.contains('Android SDK built for x86') ||
          content.contains('Genymotion') ||
          content.contains('generic');
      indicators['product_device'] =
          content.contains('generic') || content.contains('vbox');
      indicators['product_board'] = content.contains('goldfish');
      indicators['hardware'] =
          content.contains('ranchu') || content.contains('vbox86');
    }
  } catch (_) {}

  try {
    final qemu = File('/dev/qemu_pipe');
    indicators['qemu_pipe'] = await qemu.exists();
  } catch (_) {}

  try {
    final goldfish = File('/sys/class/thermal/thermal_zone0/type');
    if (await goldfish.exists()) {
      final content = await goldfish.readAsString();
      indicators['goldfish'] = content.trim() == 'goldfish';
    }
  } catch (_) {}

  final emulatorCount = indicators.values.where((v) => v).length;
  return emulatorCount >= 2;
}

Future<bool> _checkIOSEmulator() async {
  try {
    final result = await Process.run('sysctl', ['hw.model']);
    if (result.exitCode == 0) {
      final model = (result.stdout as String).toLowerCase();
      return model.contains('simulator') || model.contains('x86');
    }
  } catch (_) {}

  try {
    if (Platform.environment.containsKey('SIMULATOR_DEVICE_NAME')) {
      return true;
    }
  } catch (_) {}

  return false;
}
