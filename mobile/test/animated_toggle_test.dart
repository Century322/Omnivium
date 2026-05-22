import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/widgets/animated_toggle.dart';

void main() {
  group('AnimatedToggle', () {
    testWidgets('renders and toggles', (tester) async {
      var enabled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AnimatedToggle(
                  enabled: enabled,
                  onChanged: (val) => setState(() => enabled = val),
                );
              },
            ),
          ),
        ),
      );
      expect(find.byType(AnimatedToggle), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      var value = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedToggle(enabled: value, onChanged: (v) => value = v),
          ),
        ),
      );
      await tester.tap(find.byType(AnimatedToggle));
      expect(value, isTrue);
    });
  });
}
