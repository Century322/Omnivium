import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/haptic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HapticService', () {
    test('enabled defaults to true after loadPreference', () async {
      SharedPreferences.setMockInitialValues({});
      await HapticService.loadPreference();
      expect(HapticService.enabled, isTrue);
    });

    test('setEnabled false', () async {
      await HapticService.setEnabled(false);
      expect(HapticService.enabled, isFalse);
    });

    test('setEnabled true', () async {
      await HapticService.setEnabled(true);
      expect(HapticService.enabled, isTrue);
    });

    test('loadPreference reads from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'omnivium_haptic_enabled': false,
      });
      await HapticService.loadPreference();
      expect(HapticService.enabled, isFalse);
    });

    test('loadPreference defaults to true when not set', () async {
      SharedPreferences.setMockInitialValues({});
      await HapticService.loadPreference();
      expect(HapticService.enabled, isTrue);
    });

    test('lightImpact does not throw when enabled', () async {
      await HapticService.setEnabled(true);
      expect(() => HapticService.lightImpact(), returnsNormally);
    });

    test('lightImpact does not throw when disabled', () async {
      await HapticService.setEnabled(false);
      expect(() => HapticService.lightImpact(), returnsNormally);
    });

    test('mediumImpact does not throw', () {
      expect(() => HapticService.mediumImpact(), returnsNormally);
    });

    test('heavyImpact does not throw', () {
      expect(() => HapticService.heavyImpact(), returnsNormally);
    });

    test('selectionClick does not throw', () {
      expect(() => HapticService.selectionClick(), returnsNormally);
    });

    test('convenience methods do not throw', () {
      expect(() => HapticService.buttonPress(), returnsNormally);
      expect(() => HapticService.toggleSwitch(), returnsNormally);
      expect(() => HapticService.sendMessage(), returnsNormally);
      expect(() => HapticService.recordStart(), returnsNormally);
      expect(() => HapticService.recordStop(), returnsNormally);
      expect(() => HapticService.success(), returnsNormally);
      expect(() => HapticService.error(), returnsNormally);
      expect(() => HapticService.longPressStart(), returnsNormally);
    });
  });
}
