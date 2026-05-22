import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/quick_commands_view.dart';
import 'package:omnivium/core/quick_command_provider.dart';

void main() {
  group('QuickCommandsView', () {
    testWidgets('renders quick commands', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: QuickCommandsView(provider: QuickCommandProvider())),
      );
      expect(find.byType(QuickCommandsView), findsOneWidget);
    });
  });
}
