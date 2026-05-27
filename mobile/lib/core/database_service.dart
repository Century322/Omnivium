import 'app_logger.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  static DatabaseService get instance => _instance;
  DatabaseService._();

  static const _sessionsBox = 'omnivium_sessions';
  static const _memoryBox = 'omnivium_memory';
  static const _cacheBox = 'omnivium_cache';
  static const _dataBox = 'omnivium_data';
  static const _encryptedBox = 'omnivium_encrypted';

  late Box<String> _sessions;
  late Box<String> _memory;
  late Box<String> _cache;
  late Box<String> _data;
  late Box<String> _encrypted;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  encrypt.Key? _aesKey;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter('omnivium_db');
    _sessions = await Hive.openBox<String>(_sessionsBox);
    _memory = await Hive.openBox<String>(_memoryBox);
    _cache = await Hive.openBox<String>(_cacheBox);
    _data = await Hive.openBox<String>(_dataBox);
    _encrypted = await Hive.openBox<String>(_encryptedBox);
    _initialized = true;
  }

  Box<String> get sessions => _sessions;
  Box<String> get memory => _memory;
  Box<String> get cache => _cache;
  Box<String> get data => _data;
  Box<String> get encrypted => _encrypted;

  void setEncryptionKey(String key) {
    if (key.isNotEmpty) {
      final keyBytes = sha256.convert(utf8.encode(key)).bytes;
      _aesKey = encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, 32)));
    }
  }

  String _encrypt(String plainText) {
    final key = _aesKey;
    if (key == null) {
      throw StateError(
        'Encryption key not set. Call setEncryptionKey() before storing encrypted data.',
      );
    }
    try {
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
      combined.setRange(0, iv.bytes.length, iv.bytes);
      combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);
      return base64.encode(combined);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'AES encryption failed',
        error: e,
        stackTrace: stackTrace,
      );
      throw StateError('Encryption failed. Data will not be stored in plaintext.');
    }
  }

  String? _decrypt(String cipherText) {
    final key = _aesKey;
    if (key == null) {
      throw StateError(
        'Encryption key not set. Cannot decrypt data.',
      );
    }
    try {
      final combined = base64.decode(cipherText);
      if (combined.length < 16) return null;
      final ivBytes = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);
      final iv = encrypt.IV(Uint8List.fromList(ivBytes));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final decrypted = encrypter.decrypt(
        encrypt.Encrypted(Uint8List.fromList(encryptedBytes)),
        iv: iv,
      );
      return decrypted;
    } catch (e) {
      AppLogger.instance.warning('AES decryption failed', error: e);
      return null;
    }
  }

  Future<void> putEncrypted(String key, Map<String, dynamic> value) async {
    final json = jsonEncode(value);
    await _encrypted.put(key, _encrypt(json));
  }

  Map<String, dynamic>? getEncrypted(String key) {
    final raw = _encrypted.get(key);
    if (raw == null) return null;
    final decrypted = _decrypt(raw);
    if (decrypted == null) return null;
    try {
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Encrypted data parse failed',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> deleteEncrypted(String key) async {
    await _encrypted.delete(key);
  }

  Future<void> putSession(String id, Map<String, dynamic> data) async {
    await _sessions.put(id, jsonEncode(data));
  }

  Map<String, dynamic>? getSession(String id) {
    final raw = _sessions.get(id);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'App error',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  List<Map<String, dynamic>> getAllSessions() {
    return _sessions.values
        .map((raw) {
          try {
            return jsonDecode(raw) as Map<String, dynamic>;
          } catch (e, stackTrace) {
            AppLogger.instance.warning(
              'App error',
              error: e,
              stackTrace: stackTrace,
            );
            return <String, dynamic>{};
          }
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }

  Future<void> deleteSession(String id) async {
    await _sessions.delete(id);
  }

  Future<void> putMemory(String id, Map<String, dynamic> data) async {
    await _memory.put(id, jsonEncode(data));
  }

  Map<String, dynamic>? getMemory(String id) {
    final raw = _memory.get(id);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'App error',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  List<Map<String, dynamic>> getAllMemories() {
    return _memory.values
        .map((raw) {
          try {
            return jsonDecode(raw) as Map<String, dynamic>;
          } catch (e, stackTrace) {
            AppLogger.instance.warning(
              'App error',
              error: e,
              stackTrace: stackTrace,
            );
            return <String, dynamic>{};
          }
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }

  Future<void> deleteMemory(String id) async {
    await _memory.delete(id);
  }

  Future<void> putCache(String key, String value) async {
    await _cache.put(key, value);
    if (_cache.length > 200) {
      final keys = _cache.keys.take(_cache.length - 150).toList();
      for (final k in keys) {
        await _cache.delete(k);
      }
    }
  }

  String? getCache(String key) => _cache.get(key);

  Future<void> deleteCache(String key) async {
    await _cache.delete(key);
  }

  Future<void> clearAllCache() async {
    await _cache.clear();
  }

  Future<void> putData(String key, Map<String, dynamic> value) async {
    await _data.put(key, jsonEncode(value));
  }

  Map<String, dynamic>? getData(String key) {
    final raw = _data.get(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'App error',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  List<Map<String, dynamic>> queryData(
    bool Function(Map<String, dynamic>) predicate,
  ) {
    return _data.values
        .map((raw) {
          try {
            return jsonDecode(raw) as Map<String, dynamic>;
          } catch (e) {
            AppLogger.instance.debug('Cache JSON decode failed', error: e);
            return <String, dynamic>{};
          }
        })
        .where((m) => m.isNotEmpty && predicate(m))
        .toList();
  }

  Future<void> deleteData(String key) async {
    await _data.delete(key);
  }

  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('omnivium_sessions');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final id = map['id'] as String?;
          if (id != null && !_sessions.containsKey(id)) {
            await _sessions.put(id, jsonEncode(map));
          }
        }
        await prefs.remove('omnivium_sessions');
      } catch (e, stackTrace) {
        AppLogger.instance.error(
          'App error',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    final memRaw = prefs.getString('omnivium_memories');
    if (memRaw != null) {
      try {
        final list = jsonDecode(memRaw) as List;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final id = map['id'] as String?;
          if (id != null && !_memory.containsKey(id)) {
            await _memory.put(id, jsonEncode(map));
          }
        }
        await prefs.remove('omnivium_memories');
      } catch (e, stackTrace) {
        AppLogger.instance.error(
          'App error',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  int getSessionsCount() => _sessions.length;
  int getMemoryCount() => _memory.length;
  int getCacheSize() => _cache.length;
  int getDataCount() => _data.length;
  int getEncryptedCount() => _encrypted.length;

  Future<Map<String, int>> getStorageStats() async {
    return {
      'sessions': _sessions.length,
      'memory': _memory.length,
      'cache': _cache.length,
      'data': _data.length,
      'encrypted': _encrypted.length,
    };
  }
}
