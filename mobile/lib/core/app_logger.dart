import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'file_log.dart';

enum LogLevel { debug, info, warning, error, fatal }

class AppLogger {
  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;
  AppLogger._();

  LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  bool sentryEnabled = true;

  void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (minLevel.index > LogLevel.debug.index) return;
    debugPrint('[DEBUG${_fmtTag(tag)}] $message');
    FileLog.instance.write('[DEBUG${_fmtTag(tag)}] $message');
  }

  void info(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (minLevel.index > LogLevel.info.index) return;
    debugPrint('[INFO${_fmtTag(tag)}] $message');
    FileLog.instance.write('[INFO${_fmtTag(tag)}] $message');
  }

  void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (minLevel.index > LogLevel.warning.index) return;
    debugPrint('[WARN${_fmtTag(tag)}] $message ${error ?? ''}');
    FileLog.instance.writeError(
      '[WARN${_fmtTag(tag)}] $message',
      error,
      stackTrace,
    );
    if (sentryEnabled) {
      Sentry.captureMessage(message, level: SentryLevel.warning);
    }
  }

  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (minLevel.index > LogLevel.error.index) return;
    debugPrint('[ERROR${_fmtTag(tag)}] $message ${error ?? ''}');
    FileLog.instance.writeError(
      '[ERROR${_fmtTag(tag)}] $message',
      error,
      stackTrace,
    );
    if (sentryEnabled) {
      Sentry.captureException(
        error ?? Exception(message),
        stackTrace: stackTrace,
      );
    }
  }

  void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('[FATAL${_fmtTag(tag)}] $message ${error ?? ''}');
    FileLog.instance.writeError(
      '[FATAL${_fmtTag(tag)}] $message',
      error,
      stackTrace,
    );
    if (sentryEnabled) {
      Sentry.captureException(
        error ?? Exception(message),
        stackTrace: stackTrace,
        hint: Hint.withMap({'fatal': true}),
      );
    }
  }

  String _fmtTag(String? tag) => tag != null ? '::$tag' : '';
}
