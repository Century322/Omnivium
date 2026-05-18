import 'agent_state.dart';

class StateTransition {
  final AgentState from;
  final AgentState to;
  final String? condition;

  const StateTransition({required this.from, required this.to, this.condition});
}

class AgentStateMachine {
  AgentState _state = AgentState.idle;
  final List<StateTransition> _history = [];
  int _recoverCount = 0;
  static const int _maxRecoverAttempts = 3;
  static const int _maxHistorySize = 100;

  static const _transitions = <StateTransition>[
    StateTransition(from: AgentState.idle, to: AgentState.thinking),
    StateTransition(from: AgentState.thinking, to: AgentState.planning),
    StateTransition(from: AgentState.thinking, to: AgentState.completed),
    StateTransition(from: AgentState.thinking, to: AgentState.failed),
    StateTransition(from: AgentState.planning, to: AgentState.executing),
    StateTransition(from: AgentState.planning, to: AgentState.failed),
    StateTransition(from: AgentState.executing, to: AgentState.waitingTool),
    StateTransition(from: AgentState.executing, to: AgentState.failed),
    StateTransition(from: AgentState.executing, to: AgentState.completed),
    StateTransition(from: AgentState.waitingTool, to: AgentState.checking),
    StateTransition(from: AgentState.waitingTool, to: AgentState.failed),
    StateTransition(from: AgentState.checking, to: AgentState.completed),
    StateTransition(from: AgentState.checking, to: AgentState.recovering),
    StateTransition(from: AgentState.checking, to: AgentState.reflecting),
    StateTransition(from: AgentState.checking, to: AgentState.failed),
    StateTransition(from: AgentState.reflecting, to: AgentState.thinking),
    StateTransition(from: AgentState.reflecting, to: AgentState.completed),
    StateTransition(from: AgentState.reflecting, to: AgentState.memorizing),
    StateTransition(from: AgentState.reflecting, to: AgentState.failed),
    StateTransition(from: AgentState.recovering, to: AgentState.executing),
    StateTransition(from: AgentState.recovering, to: AgentState.thinking),
    StateTransition(from: AgentState.recovering, to: AgentState.failed),
    StateTransition(from: AgentState.interrupted, to: AgentState.idle),
    StateTransition(from: AgentState.memorizing, to: AgentState.completed),
    StateTransition(from: AgentState.memorizing, to: AgentState.failed),
    StateTransition(from: AgentState.completed, to: AgentState.memorizing),
    StateTransition(from: AgentState.completed, to: AgentState.idle),
    StateTransition(from: AgentState.failed, to: AgentState.recovering),
    StateTransition(from: AgentState.failed, to: AgentState.idle),
  ];

  AgentState get state => _state;
  List<StateTransition> get history => List.unmodifiable(_history);
  int get recoverCount => _recoverCount;
  bool get canRecover => _recoverCount < _maxRecoverAttempts;

  bool transition(AgentState newState, {String? condition}) {
    final valid = _transitions.any(
      (t) => t.from == _state && t.to == newState,
    );

    if (!valid) return false;

    _applyTransition(newState, condition);
    return true;
  }

  void forceState(AgentState newState, {String? condition}) {
    _applyTransition(newState, condition ?? 'forced');
  }

  void interrupt() {
    if (_state == AgentState.idle) return;
    _applyTransition(AgentState.interrupted, 'interrupt');
  }

  void _applyTransition(AgentState newState, String? condition) {
    final oldState = _state;
    _history.add(StateTransition(from: oldState, to: newState, condition: condition));
    if (_history.length > _maxHistorySize) {
      _history.removeRange(0, _history.length - _maxHistorySize);
    }
    _state = newState;

    if (newState == AgentState.recovering) {
      _recoverCount++;
    }

    if (newState == AgentState.idle || newState == AgentState.completed) {
      _recoverCount = 0;
    }
  }

  void reset() {
    _state = AgentState.idle;
    _history.clear();
    _recoverCount = 0;
  }
}
