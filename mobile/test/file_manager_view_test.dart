import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/app_provider.dart';
import 'package:omnivium/presentation/views/file_manager_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FileManagerView', () {
    testWidgets('renders file manager view', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(
        MaterialApp(home: FileManagerView(provider: provider)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FileManagerView), findsOneWidget);
    });

    testWidgets('has scaffold structure', (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(
        MaterialApp(home: FileManagerView(provider: provider)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
