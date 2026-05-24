import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:omnivium/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Launch', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('app launches and shows home view', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Omnivium'), findsWidgets);
    });
  });

  group('Navigation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('swipe right opens drawer hint', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.dragFrom(
        Offset(0, size.height / 2),
        Offset(size.width / 2, 0),
      );
      await tester.pumpAndSettle();
    });
  });
}
