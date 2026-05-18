import 'dart:convert';
import 'app_logger.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CrashReport {
  final String id;
  final DateTime timestamp;
  final String error;
  final String? stackTrace;
  final String? stateSnapshot;
  final bool recovered;

  const CrashReport({
    required this.id,
    required this.timestamp,
    required this.error,
    this.stackTrace,
    this.stateSnapshot,
    this.recovered = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'timestamp': timestamp.toIso8601String(),
    'error': error, 'stackTrace': stackTrace,
    'stateSnapshot': stateSnapshot, 'recovered': recovered,
  };

  factory CrashReport.fromJson(Map<String, dynamic> json) => CrashReport(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    error: json['error'] as String,
    stackTrace: json['stackTrace'] as String?,
    stateSnapshot: json['state_snapshot'] as String?,
    recovered: json['recovered'] as bool? ?? false,
  );
}

class CrashRecoveryService {
  static final CrashRecoveryService _instance = CrashRecoveryService._();
  static CrashRecoveryService get instance => _instance;
  CrashRecoveryService._();

  static const _crashFlagKey = 'omnivium_crash_flag';
  static const _stateSnapshotKey = 'omnivium_state_snapshot';
  static const _crashReportsKey = 'omnivium_crash_reports';
  static const _maxReports = 50;

  bool _initialized = false;
  bool _crashDetected = false;
  bool get crashDetected => _crashDetected;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _checkCrashFlag();
  }

  Future<void> _checkCrashFlag() async {
    try {
      final storage = SecureStorageService.instance;
      final flag = await storage.read(_crashFlagKey);
      if (flag != null) {
        _crashDetected = true;
        AppLogger.instance.warning('Previous crash detected');

        final snapshot = await storage.read(_stateSnapshotKey);
        await _saveCrashReport(CrashReport(
          id: 'crash_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          error: 'App terminated unexpectedly',
          stateSnapshot: snapshot,
        ));

        await storage.delete(_crashFlagKey);
      }
    } catch (e) {
      AppLogger.instance.warning('Crash flag check failed', error: e);
    }
  }

  Future<void> markAppStart() async {
    try {
      final storage = SecureStorageService.instance;
      await storage.write(_crashFlagKey, DateTime.now().toIso8601String());
    } catch (e) {
      AppLogger.instance.warning('Failed to mark app start', error: e);
    }
  }

  Future<void> markAppCleanExit() async {
    try {
      final storage = SecureStorageService.instance;
      await storage.delete(_crashFlagKey);
    } catch (e) {
      AppLogger.instance.warning('Failed to clear crash flag', error: e);
    }
  }

  Future<void> saveStateSnapshot({
    String? activeSessionId,
    List<String>? openViews,
    Map<String, dynamic>? customState,
  }) async {
    try {
      final snapshot = jsonEncode({
        'active_session_id': activeSessionId,
        'open_views': openViews ?? [],
        'custom_state': customState ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
      final db = DatabaseService.instance;
      if (db.isInitialized) {
        await db.putCache(_stateSnapshotKey, snapshot);
      }
      final storage = SecureStorageService.instance;
      await storage.write(_stateSnapshotKey, snapshot);
    } catch (e) {
      AppLogger.instance.warning('Failed to save state snapshot', error: e);
    }
  }

  Map<String, dynamic>? getLastStateSnapshot() {
    try {
      final db = DatabaseService.instance;
      if (db.isInitialized) {
        final raw = db.getCache(_stateSnapshotKey);
        if (raw != null) return jsonDecode(raw) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCrashReport(CrashReport report) async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;

      final reports = await getCrashReports();
      reports.insert(0, report);
      if (reports.length > _maxReports) {
        reports.removeRange(_maxReports, reports.length);
      }

      await db.putCache(_crashReportsKey, jsonEncode(reports.map((r) => r.toJson()).toList()));

      Sentry.captureMessage('Crash detected and reported', level: SentryLevel.warning, hint: Hint.withMap({
        'crash_report': report.toJson(),
      }));
    } catch (e) {
      AppLogger.instance.warning('Failed to save crash report', error: e);
    }
  }

  Future<List<CrashReport>> getCrashReports() async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return [];
      final raw = db.getCache(_crashReportsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((r) => CrashReport.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearCrashReports() async {
    try {
      final db = DatabaseService.instance;
      if (!db.isInitialized) return;
      await db.deleteCache(_crashReportsKey);
    } catch (_) {}
  }

  Future<bool> attemptRecovery() async {
    if (!_crashDetected) return true;

    try {
      final snapshot = getLastStateSnapshot();
      if (snapshot != null) {
        AppLogger.instance.info('Attempting crash recovery with state snapshot');
      }

      _crashDetected = false;
      return true;
    } catch (e) {
      AppLogger.instance.error('Crash recovery failed', error: e);
      return false;
    }
  }

  Future<void> reportUnhandledError(Object error, StackTrace stackTrace) async {
    await _saveCrashReport(CrashReport(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      error: error.toString(),
      stackTrace: stackTrace.toString(),
    ));
  }
}
