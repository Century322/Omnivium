import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:omnivium/presentation/views/search_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SearchView', () {
    testWidgets('renders search view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SearchView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(SearchView), findsOneWidget);
    });

    testWidgets('has scaffold', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SearchView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has search text field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SearchView(provider: AppProvider())),
      );
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('can type in search field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SearchView(provider: AppProvider())),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SearchView(provider: AppProvider())),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
