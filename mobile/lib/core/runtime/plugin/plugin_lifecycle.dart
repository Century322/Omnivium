enum PluginState { unloaded, loaded, active, suspended, failed }

class LifecycleTransition {
  final PluginState from;
  final PluginState to;
  final int timestamp;
  final String reason;
  final int durationMs;

  const LifecycleTransition({
    required this.from,
    required this.to,
    required this.timestamp,
    required this.reason,
    this.durationMs = 0,
  });
}

class PluginLifecycle {
  PluginState _state = PluginState.unloaded;
  final List<LifecycleTransition> _transitions = [];

  PluginState get state => _state;
  List<LifecycleTransition> get transitions => List.unmodifiable(_transitions);

  bool canTransitionTo(PluginState target) {
    switch (_state) {
      case PluginState.unloaded:
        return target == PluginState.loaded;
      case PluginState.loaded:
        return target == PluginState.active ||
            target == PluginState.unloaded ||
            target == PluginState.failed;
      case PluginState.active:
        return target == PluginState.suspended ||
            target == PluginState.unloaded ||
            target == PluginState.failed;
      case PluginState.suspended:
        return target == PluginState.active ||
            target == PluginState.unloaded ||
            target == PluginState.failed;
      case PluginState.failed:
        return target == PluginState.loaded || target == PluginState.unloaded;
    }
  }

  bool transitionTo(PluginState target, {String reason = ''}) {
    if (!canTransitionTo(target)) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    _transitions.add(
      LifecycleTransition(
        from: _state,
        to: target,
        timestamp: now,
        reason: reason));
    _state = target;
    return true;
  }

  void reset() {
    _state = PluginState.unloaded;
    _transitions.clear();
  }
}
