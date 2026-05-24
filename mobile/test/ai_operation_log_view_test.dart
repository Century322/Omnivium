import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/ai_operation_log_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiOperationLogView', () {
    testWidgets('renders operation log view', (tester) async {
      await tester.pumpWidget(MaterialApp(home: AiOperationLogView()));
      await tester.pump();
      expect(find.byType(AiOperationLogView), findsOneWidget);
    });

    testWidgets('has scaffold', (tester) async {
      await tester.pumpWidget(MaterialApp(home: AiOperationLogView()));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(MaterialApp(home: AiOperationLogView()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
