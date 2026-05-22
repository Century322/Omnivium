abstract class PersistenceBackend {
  Future<void> write(String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> read(String key);
  Future<void> delete(String key);
  Future<List<String>> listKeys(String prefix);
  Future<void> clear(String prefix);
}

class InMemoryPersistence implements PersistenceBackend {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    _store[key] = Map.from(value);
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final value = _store[key];
    return value != null ? Map.from(value) : null;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<List<String>> listKeys(String prefix) async {
    return _store.keys.where((k) => k.startsWith(prefix)).toList();
  }

  @override
  Future<void> clear(String prefix) async {
    _store.removeWhere((key, _) => key.startsWith(prefix));
  }
}
