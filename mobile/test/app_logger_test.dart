import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_logger.dart';

void main() {
  group('LogLevel', () {
    test('has correct ordering', () {
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
      expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
      expect(LogLevel.error.index, lessThan(LogLevel.fatal.index));
    });

    test('has 5 levels', () {
      expect(LogLevel.values.length, 5);
    });
  });

  group('AppLogger', () {
    test('instance is singleton', () {
      expect(AppLogger.instance, same(AppLogger.instance));
    });

    test('debug does not throw', () {
      final logger = AppLogger.instance;
      logger.minLevel = LogLevel.debug;
      expect(() => logger.debug('test message'), returnsNormally);
    });

    test('info does not throw', () {
      final logger = AppLogger.instance;
      logger.minLevel = LogLevel.debug;
      expect(() => logger.info('test message'), returnsNormally);
    });

    test('warning does not throw', () {
      final logger = AppLogger.instance;
      logger.minLevel = LogLevel.debug;
      logger.sentryEnabled = false;
      expect(() => logger.warning('test warning'), returnsNormally);
    });

    test('error does not throw', () {
      final logger = AppLogger.instance;
      logger.minLevel = LogLevel.debug;
      logger.sentryEnabled = false;
      expect(() => logger.error('test error'), returnsNormally);
    });

    test('fatal does not throw', () {
      final logger = AppLogger.instance;
      logger.minLevel = LogLevel.debug;
      logger.sentryEnabled = false;
      expect(() => logger.fatal('test fatal'), returnsNormally);
    });

    test('debug with tag does not throw', () {
      final logger = AppLogger.instance;
      logger.minLevel = LogLevel.debug;
      expect(() => logger.debug('test', tag: 'MyTag'), returnsNormally);
    });

    test('minLevel filters messages', () {
      final logger = AppLogger.instance;
      logger.minLevel = LogLevel.error;
      expect(() => logger.debug('should be filtered'), returnsNormally);
      expect(() => logger.info('should be filtered'), returnsNormally);
      expect(() => logger.warning('should be filtered'), returnsNormally);
      expect(() => logger.error('should pass'), returnsNormally);
    });

    test('sentryEnabled can be toggled', () {
      final logger = AppLogger.instance;
      logger.sentryEnabled = false;
      expect(logger.sentryEnabled, isFalse);
      logger.sentryEnabled = true;
      expect(logger.sentryEnabled, isTrue);
    });
  });
}
