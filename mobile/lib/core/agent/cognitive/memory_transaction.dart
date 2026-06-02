import '../../database_service.dart';
import '../../app_logger.dart';
import 'dart:convert';

typedef PersistEntry = MapEntry<String, String Function()>;

class MemoryTransaction {
  final DatabaseService _db;
  final List<PersistEntry> _entries = [];
  bool _committed = false;

  MemoryTransaction(this._db);

  void register(String key, String Function() serializer) {
    if (_committed) return;
    _entries.add(PersistEntry(key, serializer));
  }

  Future<void> commit() async {
    if (_committed) return;
    _committed = true;

    if (_entries.isEmpty) return;

    try {
      final batch = <String, String>{};
      for (final entry in _entries) {
        try {
          batch[entry.key] = entry.value();
        } catch (e, st) {
          AppLogger.instance.error(
            'MemoryTransaction serialize failed for key: ${entry.key}',
            error: e,
            stackTrace: st,
          );
        }
      }

      if (batch.isNotEmpty) {
        await _db.putCacheBatch(batch);
      }
    } catch (e, st) {
      AppLogger.instance.error(
        'MemoryTransaction commit failed',
        error: e,
        stackTrace: st,
      );
    }
  }
}
