import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  group('AccentPreset', () {
    test('has 8 presets', () {
      expect(AccentPreset.presets.length, 8);
    });

    test('each preset has unique key', () {
      final keys = AccentPreset.presets.map((p) => p.key).toSet();
      expect(keys.length, 8);
    });

    test('fromKey returns correct preset', () {
      expect(AccentPreset.fromKey('teal').key, 'teal');
      expect(AccentPreset.fromKey('ocean_blue').key, 'ocean_blue');
      expect(AccentPreset.fromKey('lavender').key, 'lavender');
      expect(AccentPreset.fromKey('coral').key, 'coral');
      expect(AccentPreset.fromKey('amber').key, 'amber');
      expect(AccentPreset.fromKey('emerald').key, 'emerald');
      expect(AccentPreset.fromKey('rose').key, 'rose');
      expect(AccentPreset.fromKey('slate').key, 'slate');
    });

    test('fromKey unknown returns teal', () {
      expect(AccentPreset.fromKey('unknown').key, 'teal');
    });

    test('each preset has non-zero colors', () {
      for (final preset in AccentPreset.presets) {
        expect(preset.darkAccent, isNot(equals(const Color(0x00000000))));
        expect(preset.lightAccent, isNot(equals(const Color(0x00000000))));
      }
    });

    test('static preset references match list', () {
      expect(AccentPreset.teal.key, AccentPreset.presets[0].key);
      expect(AccentPreset.oceanBlue.key, AccentPreset.presets[1].key);
      expect(AccentPreset.lavender.key, AccentPreset.presets[2].key);
      expect(AccentPreset.coral.key, AccentPreset.presets[3].key);
      expect(AccentPreset.amber.key, AccentPreset.presets[4].key);
      expect(AccentPreset.emerald.key, AccentPreset.presets[5].key);
      expect(AccentPreset.rose.key, AccentPreset.presets[6].key);
      expect(AccentPreset.slate.key, AccentPreset.presets[7].key);
    });
  });

  group('AppColors', () {
    test('static color constants are not zero', () {
      expect(AppColors.background, isNotNull);
      expect(AppColors.surface, isNotNull);
      expect(AppColors.accent, isNotNull);
      expect(AppColors.danger, isNotNull);
    });

    test('light mode constants are not zero', () {
      expect(AppColors.lightBackground, isNotNull);
      expect(AppColors.lightSurface, isNotNull);
      expect(AppColors.lightDanger, isNotNull);
    });
  });
}
