import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_logger.dart';
import 'database_service.dart';
import 'runtime/plugins/persistence_backend.dart';

class DatabasePersistenceBackend implements PersistenceBackend {
  final String _boxName;

  DatabasePersistenceBackend({String boxName = 'omnivium_data'})
    : _boxName = boxName;

  Box<String> get _box {
    switch (_boxName) {
      case 'omnivium_sessions':
        return DatabaseService.instance.sessions;
      case 'omnivium_memory':
        return DatabaseService.instance.memory;
      case 'omnivium_cache':
        return DatabaseService.instance.cache;
      case 'omnivium_encrypted':
        return DatabaseService.instance.encrypted;
      default:
        return DatabaseService.instance.data;
    }
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    await _box.put('rt_$key', jsonEncode(value));
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final raw = _box.get('rt_$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.instance.debug('Persistence read failed', error: e);
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete('rt_$key');
  }

  @override
  Future<List<String>> listKeys(String prefix) async {
    return _box.keys
        .where((k) => k is String && k.startsWith('rt_$prefix'))
        .map((k) => (k as String).replaceFirst('rt_', ''))
        .toList();
  }

  @override
  Future<void> clear(String prefix) async {
    final keysToDelete = _box.keys
        .where((k) => k is String && k.startsWith('rt_$prefix'))
        .toList();
    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }
}
