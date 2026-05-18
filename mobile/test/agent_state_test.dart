import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/agent/agent_state.dart';

void main() {
  group('AgentState', () {
    test('initial state is idle', () {
      expect(AgentState.idle.toString(), contains('idle'));
    });

    test('all states are distinct', () {
      final states = AgentState.values;
      final stateSet = states.toSet();
      expect(stateSet.length, states.length);
    });
  });

  group('IntentChannel', () {
    test('has fast and slow channels', () {
      expect(IntentChannel.values, contains(IntentChannel.fast));
      expect(IntentChannel.values, contains(IntentChannel.slow));
    });
  });

  group('ThoughtStep', () {
    test('creates with required fields', () {
      final step = ThoughtStep(
        type: ThoughtType.analysis,
        content: 'Test thought',
        timestamp: DateTime.now(),
      );
      expect(step.type, ThoughtType.analysis);
      expect(step.content, 'Test thought');
    });
  });
}
