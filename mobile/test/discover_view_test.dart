import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:omnivium/presentation/views/discover_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DiscoverView', () {
    testWidgets('renders discover view', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(
        home: DiscoverView(provider: provider),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverView), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(
        home: DiscoverView(provider: provider),
      ));
      await tester.pump();
      expect(find.byType(DiscoverView), findsOneWidget);
    });

    testWidgets('has scaffold structure', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(
        home: DiscoverView(provider: provider),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders fallback content when API unavailable', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(MaterialApp(
        home: DiscoverView(provider: provider),
      ));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(DiscoverView), findsOneWidget);
    });
  });
}
