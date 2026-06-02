import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/theme/theme_cubit.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(setupTestEnv);

  group('ThemeCubit', () {
    late ThemeCubit cubit;

    setUp(() async {
      cubit = ThemeCubit();
      await cubit.stream.first;
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has dark mode and teal accent', () {
      expect(cubit.state.mode, ThemeMode.dark);
      expect(cubit.state.accentKey, 'teal');
    });

    test('setMode emits correct theme mode', () async {
      await cubit.setMode(ThemeMode.light);
      expect(cubit.state.mode, ThemeMode.light);

      await cubit.setMode(ThemeMode.system);
      expect(cubit.state.mode, ThemeMode.system);
    });

    test('setAccent emits correct accent key', () async {
      await cubit.setAccent('ocean_blue');
      expect(cubit.state.accentKey, 'ocean_blue');
    });

    test('lightTheme is not null', () {
      expect(cubit.state.lightTheme, isNotNull);
    });

    test('darkTheme is not null', () {
      expect(cubit.state.darkTheme, isNotNull);
    });

    test('overlayStyle is not null', () {
      expect(cubit.state.overlayStyle, isNotNull);
    });

    test('accentPreset returns correct preset', () async {
      await cubit.setAccent('coral');
      expect(cubit.state.accentPreset.key, 'coral');
    });
  });
}
