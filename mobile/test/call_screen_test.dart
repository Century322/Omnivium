import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/call_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CallScreen', () {
    testWidgets('renders call screen widget', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: CallScreen(),
      ));
      await tester.pump();
      expect(find.byType(CallScreen), findsOneWidget);
    });

    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: CallScreen(),
      ));
      await tester.pump();
      expect(find.byType(CallScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
