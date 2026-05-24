import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:omnivium/presentation/views/settings_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsView', () {
    testWidgets('renders settings view', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(
        home: SettingsView(provider: provider),
      ));
      await tester.pump();
      expect(find.byType(SettingsView), findsOneWidget);
    });

    testWidgets('contains scaffold', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(
        home: SettingsView(provider: provider),
      ));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(
        home: SettingsView(provider: provider),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
