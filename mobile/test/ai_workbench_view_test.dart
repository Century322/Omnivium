import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:omnivium/presentation/views/ai_workbench_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AIWorkbenchView', () {
    testWidgets('renders workbench view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AIWorkbenchView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(AIWorkbenchView), findsOneWidget);
    });

    testWidgets('has scaffold with app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AIWorkbenchView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has text input field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AIWorkbenchView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('can enter text in input field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AIWorkbenchView(provider: AppProvider())),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Write a poem');
      await tester.pump();
      expect(find.text('Write a poem'), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AIWorkbenchView(provider: AppProvider())),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
