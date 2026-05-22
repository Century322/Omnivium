import 'runtime/sdk/omnivium_sdk.dart';
import 'runtime/plugins/persistence_backend.dart';
import 'database_persistence_backend.dart';
import 'database_service.dart';

class AppDataGateway {
  static final AppDataGateway _instance = AppDataGateway._();
  static AppDataGateway get instance => _instance;
  AppDataGateway._();

  PersistenceBackend? _persistence;
  bool _initialized = false;

  PersistenceBackend get persistence {
    _persistence ??= DatabasePersistenceBackend();
    return _persistence!;
  }

  void init({PersistenceBackend? backend}) {
    _persistence = backend ?? DatabasePersistenceBackend();
    _initialized = true;
  }

  Future<void> write(String key, Map<String, dynamic> value) async {
    await persistence.write(key, value);
    _auditWrite(key, value);
  }

  Future<Map<String, dynamic>?> read(String key) async {
    return persistence.read(key);
  }

  Future<void> delete(String key) async {
    await persistence.delete(key);
    _auditDelete(key);
  }

  Future<List<String>> listKeys(String prefix) async {
    return persistence.listKeys(prefix);
  }

  Future<void> clear(String prefix) async {
    await persistence.clear(prefix);
    _auditClear(prefix);
  }

  DatabaseService get db => DatabaseService.instance;

  void _auditWrite(String key, Map<String, dynamic> value) {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;
    try {
      sdk.container.eventJournal.append('data.write', {
        'key': key,
        'size': value.length,
      });
    } catch (_) {}
  }

  void _auditDelete(String key) {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;
    try {
      sdk.container.eventJournal.append('data.delete', {'key': key});
    } catch (_) {}
  }

  void _auditClear(String prefix) {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;
    try {
      sdk.container.eventJournal.append('data.clear', {'prefix': prefix});
    } catch (_) {}
  }
}
