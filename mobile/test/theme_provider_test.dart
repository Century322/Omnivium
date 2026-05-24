import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/theme/theme_provider.dart';
import 'package:omnivium/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider', () {
    test('default mode is dark', () {
      final provider = ThemeProvider();
      expect(provider.mode, ThemeMode.dark);
    });

    test('setMode changes mode', () async {
      final provider = ThemeProvider();
      await provider.setMode(ThemeMode.light);
      expect(provider.mode, ThemeMode.light);
    });

    test('setMode notifies listeners', () async {
      final provider = ThemeProvider();
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.setMode(ThemeMode.system);
      expect(notified, isTrue);
    });

    test('setAccent changes accent', () async {
      final provider = ThemeProvider();
      await provider.setAccent('ocean_blue');
      expect(provider.accentPreset.key, 'ocean_blue');
    });

    test('setAccent notifies listeners', () async {
      final provider = ThemeProvider();
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.setAccent('coral');
      expect(notified, isTrue);
    });

    test('darkTheme returns ThemeData with dark brightness', () {
      final provider = ThemeProvider();
      expect(provider.darkTheme.brightness, Brightness.dark);
    });

    test('lightTheme returns ThemeData with light brightness', () {
      final provider = ThemeProvider();
      expect(provider.lightTheme.brightness, Brightness.light);
    });

    test('darkTheme uses accent color as primary', () async {
      final provider = ThemeProvider();
      await provider.setAccent('teal');
      expect(
        provider.darkTheme.colorScheme.primary,
        AccentPreset.teal.darkAccent,
      );
    });

    test('lightTheme uses light accent as primary', () async {
      final provider = ThemeProvider();
      await provider.setAccent('teal');
      expect(
        provider.lightTheme.colorScheme.primary,
        AccentPreset.teal.lightAccent,
      );
    });

    test('currentModeKey returns correct string', () async {
      final provider = ThemeProvider();
      expect(provider.currentModeKey, 'dark');
      await provider.setMode(ThemeMode.light);
      expect(provider.currentModeKey, 'light');
      await provider.setMode(ThemeMode.system);
      expect(provider.currentModeKey, 'system');
    });

    test('setModeFromString works', () async {
      final provider = ThemeProvider();
      provider.setModeFromString('light');
      expect(provider.mode, ThemeMode.light);
    });

    test('overlayStyle for dark mode has light icons', () {
      final provider = ThemeProvider();
      final style = provider.overlayStyle;
      expect(style.statusBarIconBrightness, Brightness.light);
    });

    test('overlayStyle for light mode has dark icons', () async {
      final provider = ThemeProvider();
      await provider.setMode(ThemeMode.light);
      final style = provider.overlayStyle;
      expect(style.statusBarIconBrightness, Brightness.dark);
    });
  });
}
