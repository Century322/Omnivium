import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._();
  static SecureStorageService get instance => _instance;
  SecureStorageService._();

  static const _androidOptions = AndroidOptions(encryptedSharedPreferences: true);
  static const _iosOptions = IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  late final FlutterSecureStorage _storage;

  Future<void> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  Future<Map<String, String>> readAll() => _storage.readAll();
}
