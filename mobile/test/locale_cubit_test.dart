import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/theme/locale_cubit.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(setupTestEnv);

  group('LocaleCubit', () {
    late LocaleCubit cubit;

    setUp(() async {
      cubit = LocaleCubit();
      await cubit.stream.first;
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has zh locale', () {
      expect(cubit.state.locale, const Locale('zh'));
    });

    test('t returns key for unknown translations', () {
      final result = cubit.t('unknown_key_xyz');
      expect(result, 'unknown_key_xyz');
    });

    test('setLocale emits correct locale', () async {
      await cubit.setLocale(const Locale('en'));
      expect(cubit.state.locale, const Locale('en'));
    });

    test('currentLabel returns correct label', () async {
      await cubit.setLocale(const Locale('en'));
      expect(cubit.currentLabel, 'English');

      await cubit.setLocale(const Locale('ja'));
      expect(cubit.currentLabel, '日本語');

      await cubit.setLocale(const Locale('ko'));
      expect(cubit.currentLabel, '한국어');

      await cubit.setLocale(const Locale('zh'));
      expect(cubit.currentLabel, '中文');
    });

    test('setLocaleFromLabel works with codes', () async {
      cubit.setLocaleFromLabel('en');
      await cubit.stream.first;
      expect(cubit.state.locale, const Locale('en'));

      cubit.setLocaleFromLabel('ja');
      await cubit.stream.first;
      expect(cubit.state.locale, const Locale('ja'));
    });

    test('setLocaleFromLabel works with labels', () async {
      cubit.setLocaleFromLabel('English');
      await cubit.stream.first;
      expect(cubit.state.locale, const Locale('en'));

      cubit.setLocaleFromLabel('日本語');
      await cubit.stream.first;
      expect(cubit.state.locale, const Locale('ja'));
    });

    test('setLocaleFromLabel defaults to zh', () async {
      cubit.setLocaleFromLabel('unknown');
      await cubit.stream.first;
      expect(cubit.state.locale, const Locale('zh'));
    });

    test('locale getter matches state', () async {
      await cubit.setLocale(const Locale('ko'));
      expect(cubit.locale, cubit.state.locale);
    });

    test('supportedLocales contains all 4 locales', () {
      expect(LocaleState.supportedLocales.length, 4);
      expect(LocaleState.supportedLocales, contains(const Locale('zh')));
      expect(LocaleState.supportedLocales, contains(const Locale('en')));
      expect(LocaleState.supportedLocales, contains(const Locale('ja')));
      expect(LocaleState.supportedLocales, contains(const Locale('ko')));
    });
  });
}
