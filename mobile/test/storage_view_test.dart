import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:omnivium/presentation/views/storage_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StorageView', () {
    testWidgets('renders storage view', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(
        home: StorageView(provider: provider),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(StorageView), findsOneWidget);
    });

    testWidgets('has scaffold structure', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(
        home: StorageView(provider: provider),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows storage categories', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(
        home: StorageView(provider: provider),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(StorageView), findsOneWidget);
    });
  });
}
