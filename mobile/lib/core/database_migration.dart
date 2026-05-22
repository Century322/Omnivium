import 'app_logger.dart';
import 'database_service.dart';

class DatabaseMigration {
  static final DatabaseMigration _instance = DatabaseMigration._();
  static DatabaseMigration get instance => _instance;
  DatabaseMigration._();

  static const String _versionKey = 'db_schema_version';
  static const int _currentVersion = 1;

  final Map<int, Future<void> Function(DatabaseService)> _migrations = {};

  void registerMigration(
    int version,
    Future<void> Function(DatabaseService) migration,
  ) {
    _migrations[version] = migration;
  }

  Future<void> run() async {
    final db = DatabaseService.instance;
    if (!db.isInitialized) return;

    final currentVersion = db.getCache(_versionKey) as int? ?? 0;

    if (currentVersion >= _currentVersion) return;

    AppLogger.instance.info(
      'DB migration: $currentVersion -> $_currentVersion',
    );

    for (var v = currentVersion + 1; v <= _currentVersion; v++) {
      final migration = _migrations[v];
      if (migration != null) {
        try {
          await migration(db);
          AppLogger.instance.info('DB migration v$v applied');
        } catch (e, stackTrace) {
          AppLogger.instance.error(
            'DB migration v$v failed',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      }
      await db.putCache(_versionKey, '$v');
    }
  }

  Future<bool> integrityCheck() async {
    final db = DatabaseService.instance;
    if (!db.isInitialized) return false;
    try {
      final sessions = db.getAllSessions();
      AppLogger.instance.info(
        'DB integrity: ${sessions.length} sessions readable',
      );
      return true;
    } catch (e) {
      AppLogger.instance.error('DB integrity check failed', error: e);
      return false;
    }
  }

  Future<void> recoverFromCorruption() async {
    final db = DatabaseService.instance;
    AppLogger.instance.info('Attempting DB recovery...');
    try {
      await db.cache.clear();
      await db.data.clear();
      await db.putCache(_versionKey, '$_currentVersion');
      AppLogger.instance.info('DB recovery completed');
    } catch (e) {
      AppLogger.instance.error('DB recovery failed', error: e);
    }
  }
}
