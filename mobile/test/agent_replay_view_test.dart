import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/views/agent_replay_view.dart';
import 'package:omnivium/core/agent/agent_orchestrator.dart';

void main() {
  group('AgentReplayView', () {
    testWidgets('renders replay view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AgentReplayView(orchestrator: AgentOrchestrator())),
      );
      expect(find.byType(AgentReplayView), findsOneWidget);
    });
  });
}
