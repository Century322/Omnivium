import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleProvider translations', () {
    test('zh translations contain key settings', () {
      expect(zhTranslations.containsKey('settings'), true);
      expect(zhTranslations['settings'], '设置');
    });

    test('en translations contain key settings', () {
      expect(enTranslations.containsKey('settings'), true);
      expect(enTranslations['settings'], 'Settings');
    });

    test('ja translations contain key settings', () {
      expect(jaTranslations.containsKey('settings'), true);
      expect(jaTranslations['settings'], '設定');
    });

    test('ko translations contain key settings', () {
      expect(koTranslations.containsKey('settings'), true);
      expect(koTranslations['settings'], '설정');
    });

    test('all locales have same number of keys', () {
      expect(zhTranslations.length, enTranslations.length);
      expect(zhTranslations.length, jaTranslations.length);
      expect(zhTranslations.length, koTranslations.length);
    });

    test('zh translations contain security keys', () {
      expect(zhTranslations.containsKey('security_warning'), true);
      expect(zhTranslations.containsKey('coming_soon'), true);
    });

    test('en translations contain security keys', () {
      expect(enTranslations.containsKey('security_warning'), true);
      expect(enTranslations.containsKey('coming_soon'), true);
    });
  });
}

const zhTranslations = <String, String>{
  'settings': '设置', 'security_warning': '安全警告', 'coming_soon': '即将推出',
};
const enTranslations = <String, String>{
  'settings': 'Settings', 'security_warning': 'Security Warning', 'coming_soon': 'Coming soon',
};
const jaTranslations = <String, String>{
  'settings': '設定', 'security_warning': 'セキュリティ警告', 'coming_soon': '近日公開',
};
const koTranslations = <String, String>{
  'settings': '설정', 'security_warning': '보안 경고', 'coming_soon': '출시 예정',
};
