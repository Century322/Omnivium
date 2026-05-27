import 'dart:async';
import 'dart:io' if (dart.library.html) '';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

class FileLog {
  static final FileLog _instance = FileLog._();
  static FileLog get instance => _instance;
  FileLog._();

  static const int _maxFileSize = 2 * 1024 * 1024;
  static const int _maxLogFiles = 5;
  static const Duration _anrTimeout = Duration(seconds: 5);

  File? _logFile;
  IOSink? _sink;
  bool _initialized = false;
  Timer? _anrTimer;
  DateTime? _lastUiThreadTime;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final logDir = Directory('${dir.path}/logs');
      if (!logDir.existsSync()) logDir.createSync(recursive: true);
      final file = File('${logDir.path}/app.log');
      _logFile = file;
      await _rotateLogs(logDir);
      _sink = file.openWrite(mode: FileMode.append);
      _initialized = true;
      _startAnrDetection();
      AppLogger.instance.info('FileLog initialized');
    } catch (e) {
      AppLogger.instance.info('FileLog init failed: $e');
    }
  }

  void write(String message) {
    if (!_initialized) return;
    final sink = _sink;
    final logFile = _logFile;
    if (sink == null) return;
    try {
      final timestamp = DateTime.now().toIso8601String();
      sink.writeln('[$timestamp] $message');
      if (logFile != null && logFile.existsSync() && logFile.lengthSync() > _maxFileSize) {
        _rotateLogs(Directory(logFile.parent.path));
      }
    } catch (e) {
      debugPrint('FileLog: write failed: $e');
    }
  }

  void writeError(String message, [Object? error, StackTrace? stackTrace]) {
    write('ERROR: $message');
    if (error != null) write('  Error: $error');
    if (stackTrace != null) write('  Stack: $stackTrace');
  }

  Future<String> readLogs({int maxLines = 500}) async {
    final logFile = _logFile;
    if (logFile == null || !logFile.existsSync()) return '';
    try {
      final lines = await logFile.readAsLines();
      if (lines.length <= maxLines) return lines.join('\n');
      return lines.sublist(lines.length - maxLines).join('\n');
    } catch (e) {
      AppLogger.instance.debug('Log trim failed', error: e);
      return '';
    }
  }

  Future<void> clearLogs() async {
    if (!_initialized) return;
    try {
      await _sink?.close();
      final logFile = _logFile;
      if (logFile != null && logFile.existsSync()) {
        await logFile.writeAsString('');
      }
      _sink = logFile?.openWrite(mode: FileMode.append);
    } catch (e) {
      debugPrint('FileLog: clearLogs failed: $e');
    }
  }

  void _startAnrDetection() {
    _lastUiThreadTime = DateTime.now();
    _anrTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final lastTime = _lastUiThreadTime;
      if (lastTime != null) {
        final diff = now.difference(lastTime);
        if (diff > _anrTimeout) {
          writeError('ANR detected: UI thread blocked for ${diff.inSeconds}s');
        }
      }
      _lastUiThreadTime = now;
    });
  }

  void pingUiThread() {
    _lastUiThreadTime = DateTime.now();
  }

  Future<void> _rotateLogs(Directory logDir) async {
    try {
      for (var i = _maxLogFiles - 1; i >= 1; i--) {
        final oldFile = File('${logDir.path}/app_$i.log');
        final newFile = File('${logDir.path}/app_${i + 1}.log');
        if (oldFile.existsSync()) {
          if (i == _maxLogFiles - 1) {
            await oldFile.delete();
          } else {
            await oldFile.rename(newFile.path);
          }
        }
      }
      final logFile = _logFile;
      if (logFile != null && logFile.existsSync()) {
        await logFile.rename('${logDir.path}/app_1.log');
      }
    } catch (e) {
      debugPrint('FileLog: rotateLogs failed: $e');
    }
  }

  void dispose() {
    _anrTimer?.cancel();
    _sink?.close();
  }
}
