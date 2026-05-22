import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/agent/agent_state.dart';
import 'package:omnivium/core/agent/agent_state_machine.dart';

void main() {
  group('AgentStateMachine', () {
    late AgentStateMachine fsm;

    setUp(() {
      fsm = AgentStateMachine();
    });

    test('initial state is idle', () {
      expect(fsm.state, AgentState.idle);
    });

    test('initial history is empty', () {
      expect(fsm.history, isEmpty);
    });

    test('initial recoverCount is zero', () {
      expect(fsm.recoverCount, 0);
    });

    test('idle -> thinking is valid', () {
      expect(fsm.transition(AgentState.thinking), true);
      expect(fsm.state, AgentState.thinking);
    });

    test('idle -> executing is invalid', () {
      expect(fsm.transition(AgentState.executing), false);
      expect(fsm.state, AgentState.idle);
    });

    test('idle -> planning is invalid', () {
      expect(fsm.transition(AgentState.planning), false);
      expect(fsm.state, AgentState.idle);
    });

    test('idle -> reflecting is invalid', () {
      expect(fsm.transition(AgentState.reflecting), false);
      expect(fsm.state, AgentState.idle);
    });

    test('thinking -> planning is valid', () {
      fsm.transition(AgentState.thinking);
      expect(fsm.transition(AgentState.planning), true);
      expect(fsm.state, AgentState.planning);
    });

    test('thinking -> completed is valid (fast path)', () {
      fsm.transition(AgentState.thinking);
      expect(fsm.transition(AgentState.completed), true);
      expect(fsm.state, AgentState.completed);
    });

    test('thinking -> executing is invalid', () {
      fsm.transition(AgentState.thinking);
      expect(fsm.transition(AgentState.executing), false);
      expect(fsm.state, AgentState.thinking);
    });

    test('planning -> executing is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      expect(fsm.transition(AgentState.executing), true);
      expect(fsm.state, AgentState.executing);
    });

    test('executing -> waitingTool is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      expect(fsm.transition(AgentState.waitingTool), true);
      expect(fsm.state, AgentState.waitingTool);
    });

    test('waitingTool -> checking is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      expect(fsm.transition(AgentState.checking), true);
      expect(fsm.state, AgentState.checking);
    });

    test('checking -> completed is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      expect(fsm.transition(AgentState.completed), true);
    });

    test('checking -> recovering is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      expect(fsm.transition(AgentState.recovering), true);
      expect(fsm.state, AgentState.recovering);
    });

    test('checking -> reflecting is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      expect(fsm.transition(AgentState.reflecting), true);
      expect(fsm.state, AgentState.reflecting);
    });

    test('reflecting -> thinking is valid (re-think)', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.reflecting);
      expect(fsm.transition(AgentState.thinking), true);
      expect(fsm.state, AgentState.thinking);
    });

    test('reflecting -> completed is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.reflecting);
      expect(fsm.transition(AgentState.completed), true);
    });

    test('reflecting -> memorizing is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.reflecting);
      expect(fsm.transition(AgentState.memorizing), true);
      expect(fsm.state, AgentState.memorizing);
    });

    test('memorizing -> completed is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.reflecting);
      fsm.transition(AgentState.memorizing);
      expect(fsm.transition(AgentState.completed), true);
      expect(fsm.state, AgentState.completed);
    });

    test('completed -> memorizing is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.completed);
      expect(fsm.transition(AgentState.memorizing), true);
      expect(fsm.state, AgentState.memorizing);
    });

    test('completed -> idle is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.completed);
      expect(fsm.transition(AgentState.idle), true);
      expect(fsm.state, AgentState.idle);
    });

    test('recovering -> executing is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.recovering);
      expect(fsm.transition(AgentState.executing), true);
      expect(fsm.state, AgentState.executing);
    });

    test('recovering -> thinking is valid', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.recovering);
      expect(fsm.transition(AgentState.thinking), true);
      expect(fsm.state, AgentState.thinking);
    });

    test('interrupted -> idle is valid', () {
      fsm.forceState(AgentState.interrupted);
      expect(fsm.transition(AgentState.idle), true);
      expect(fsm.state, AgentState.idle);
    });

    test('full slow path with memorizing', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.reflecting);
      fsm.transition(AgentState.memorizing);
      fsm.transition(AgentState.completed);
      expect(fsm.state, AgentState.completed);
    });

    test('fast path: idle -> thinking -> completed', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.completed);
      expect(fsm.state, AgentState.completed);
    });

    test('recovery path: checking -> recovering -> executing', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.recovering);
      fsm.transition(AgentState.executing);
      expect(fsm.state, AgentState.executing);
    });

    test(
      'reflection-rethink path: reflecting -> thinking -> planning -> ...',
      () {
        fsm.transition(AgentState.thinking);
        fsm.transition(AgentState.planning);
        fsm.transition(AgentState.executing);
        fsm.transition(AgentState.waitingTool);
        fsm.transition(AgentState.checking);
        fsm.transition(AgentState.reflecting);
        fsm.transition(AgentState.thinking);
        fsm.transition(AgentState.planning);
        fsm.transition(AgentState.executing);
        expect(fsm.state, AgentState.executing);
      },
    );

    test('forceState bypasses rules', () {
      fsm.forceState(AgentState.executing);
      expect(fsm.state, AgentState.executing);
    });

    test('forceState records history with forced condition', () {
      fsm.forceState(AgentState.executing);
      expect(fsm.history.length, 1);
      expect(fsm.history.last.from, AgentState.idle);
      expect(fsm.history.last.to, AgentState.executing);
      expect(fsm.history.last.condition, 'forced');
    });

    test('transition records history', () {
      fsm.transition(AgentState.thinking);
      expect(fsm.history.length, 1);
      expect(fsm.history.first.from, AgentState.idle);
      expect(fsm.history.first.to, AgentState.thinking);
    });

    test('transition with condition records condition', () {
      fsm.transition(AgentState.thinking, condition: 'user_input');
      expect(fsm.history.first.condition, 'user_input');
    });

    test('invalid transition does not record history', () {
      fsm.transition(AgentState.executing);
      expect(fsm.history, isEmpty);
      expect(fsm.state, AgentState.idle);
    });

    test('interrupt forces interrupted state', () {
      fsm.transition(AgentState.thinking);
      fsm.interrupt();
      expect(fsm.state, AgentState.interrupted);
    });

    test('reset returns to idle and clears history', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.reset();
      expect(fsm.state, AgentState.idle);
      expect(fsm.history, isEmpty);
      expect(fsm.recoverCount, 0);
    });

    test('recoverCount increments on recovering transition', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.recovering);
      expect(fsm.recoverCount, 1);
    });

    test('recoverCount increments multiple times', () {
      fsm.transition(AgentState.thinking);
      fsm.transition(AgentState.planning);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.recovering);
      fsm.transition(AgentState.executing);
      fsm.transition(AgentState.waitingTool);
      fsm.transition(AgentState.checking);
      fsm.transition(AgentState.recovering);
      expect(fsm.recoverCount, 2);
    });

    test('canRecover is true when under max attempts', () {
      expect(fsm.canRecover, true);
    });

    test('canRecover is false after max recover attempts', () {
      for (int i = 0; i < 3; i++) {
        fsm.forceState(AgentState.checking);
        fsm.transition(AgentState.recovering);
      }
      expect(fsm.canRecover, false);
    });

    test('recoverCount resets on idle', () {
      fsm.forceState(AgentState.checking);
      fsm.transition(AgentState.recovering);
      expect(fsm.recoverCount, 1);
      fsm.forceState(AgentState.completed);
      fsm.transition(AgentState.idle);
      expect(fsm.recoverCount, 0);
    });

    test('recoverCount resets on completed', () {
      fsm.forceState(AgentState.checking);
      fsm.transition(AgentState.recovering);
      expect(fsm.recoverCount, 1);
      fsm.forceState(AgentState.thinking);
      fsm.transition(AgentState.completed);
      expect(fsm.recoverCount, 0);
    });
  });

  group('AgentState', () {
    test('all states exist', () {
      expect(
        AgentState.values,
        containsAll([
          AgentState.idle,
          AgentState.thinking,
          AgentState.planning,
          AgentState.executing,
          AgentState.waitingTool,
          AgentState.checking,
          AgentState.reflecting,
          AgentState.memorizing,
          AgentState.recovering,
          AgentState.interrupted,
          AgentState.failed,
          AgentState.completed,
        ]),
      );
    });

    test('all states are distinct', () {
      final states = AgentState.values;
      expect(states.toSet().length, states.length);
    });

    test('state names are readable', () {
      for (final state in AgentState.values) {
        expect(state.name, isNotEmpty);
      }
    });
  });
}
