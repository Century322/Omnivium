import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_logger.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._();
  static PermissionService get instance => _instance;
  PermissionService._();

  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestPhotos() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdk();
      if (sdkInt >= 33) {
        final status = await Permission.photos.request();
        if (status.isGranted) return true;
      }
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> requestContacts() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<bool> checkMicrophone() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<bool> checkCamera() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<bool> checkPhotos() async {
    final status = await Permission.photos.status;
    if (status.isGranted) return true;
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      return storageStatus.isGranted;
    }
    return false;
  }

  Future<bool> checkNotification() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> openSettingsIfPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return true;
    }
    return false;
  }

  Future<Map<Permission, PermissionStatus>> requestMultiple(
    List<Permission> permissions,
  ) async {
    try {
      return await permissions.request();
    } catch (e) {
      AppLogger.instance.warning('Batch permission request failed', error: e);
      return {};
    }
  }

  Future<int> _getAndroidSdk() async {
    try {
      if (!Platform.isAndroid) return 30;
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      AppLogger.instance.debug('SDK version detection failed', error: e);
      return 30;
    }
  }
}
