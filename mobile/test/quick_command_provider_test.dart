import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/quick_command_provider.dart';

void main() {
  group('QuickCommandProvider', () {
    test('initial commands is empty', () {
      final provider = QuickCommandProvider();
      expect(provider.commands, isEmpty);
    });

    test('initial categories is empty', () {
      final provider = QuickCommandProvider();
      expect(provider.categories, isEmpty);
    });

    test('is ChangeNotifier', () {
      final provider = QuickCommandProvider();
      expect(provider.hasListeners, isFalse);
    });

    test('notifyListeners on addCommand', () async {
      final provider = QuickCommandProvider();
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.init();
      expect(notified, isTrue);
    });
  });
}
