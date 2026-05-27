import 'runtime/sdk/omnivium_sdk.dart';
import 'runtime/plugins/persistence_backend.dart';
import 'database_persistence_backend.dart';
import 'database_service.dart';

class AppDataGateway {
  static final AppDataGateway _instance = AppDataGateway._();
  static AppDataGateway get instance => _instance;
  AppDataGateway._();

  PersistenceBackend? _persistence;

  PersistenceBackend get persistence {
    var backend = _persistence;
    if (backend == null) {
      backend = DatabasePersistenceBackend();
      _persistence = backend;
    }
    return backend;
  }

  void init({PersistenceBackend? backend}) {
    _persistence = backend ?? DatabasePersistenceBackend();
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
    } catch (e) {
      AppLogger.instance.debug('Audit write failed', error: e);
    }
  }

  void _auditDelete(String key) {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;
    try {
      sdk.container.eventJournal.append('data.delete', {'key': key});
    } catch (e) {
      AppLogger.instance.debug('Audit delete failed', error: e);
    }
  }

  void _auditClear(String prefix) {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;
    try {
      sdk.container.eventJournal.append('data.clear', {'prefix': prefix});
    } catch (e) {
      AppLogger.instance.debug('Audit clear failed', error: e);
    }
  }
}
