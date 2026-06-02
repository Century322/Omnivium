import '../scheduler.dart';
import '../plugin/plugin_registry.dart';
import '../event_bus.dart';
import '../kernel/runtime_clock.dart';

enum InvariantSeverity { critical, important, warning }

class InvariantViolation {
  final String invariantId;
  final String description;
  final InvariantSeverity severity;
  final Map<String, dynamic> context;
  final int timestamp;

  const InvariantViolation({
    required this.invariantId,
    required this.description,
    required this.severity,
    this.context = const {},
    required this.timestamp,
  });

  @override
  String toString() => '[$severity] $invariantId: $description';
}

abstract class RuntimeInvariant {
  String get id;
  String get description;
  InvariantSeverity get severity;

  InvariantViolation? check(RuntimeInvariantContext ctx);
}

class RuntimeInvariantContext {
  final Scheduler scheduler;
  final PluginRegistry pluginRegistry;
  final EventBus eventBus;
  final RuntimeClock clock;

  RuntimeInvariantContext({
    required this.scheduler,
    required this.pluginRegistry,
    required this.eventBus,
    required this.clock,
  });
}

class TaskTerminalStateInvariant implements RuntimeInvariant {
  @override
  final id = 'INV-TASK-001';
  @override
  final description =
      'Every task must eventually reach one of: completed, failed, or cancelled';
  @override
  final severity = InvariantSeverity.critical;

  @override
  InvariantViolation? check(RuntimeInvariantContext ctx) {
    final states = ctx.scheduler.taskStates;
    final stuck = <String, TaskState>{};
    for (final entry in states.entries) {
      final state = entry.value;
      if (state != TaskState.completed &&
          state != TaskState.failed &&
          state != TaskState.cancelled) {
        stuck[entry.key] = state;
      }
    }
    if (stuck.isNotEmpty) {
      return InvariantViolation(
        invariantId: id,
        description: '${stuck.length} tasks in non-terminal states',
        severity: severity,
        context: {'stuckTasks': stuck.keys.toList()},
        timestamp: ctx.clock.now());
    }
    return null;
  }
}

class SchedulerNoOrphanTasksInvariant implements RuntimeInvariant {
  @override
  final id = 'INV-SCHED-001';
  @override
  final description = 'Scheduler task counts must be consistent';
  @override
  final severity = InvariantSeverity.important;

  @override
  InvariantViolation? check(RuntimeInvariantContext ctx) {
    final total = ctx.scheduler.totalTasks;
    final accounted =
        ctx.scheduler.pendingCount +
        ctx.scheduler.runningCount +
        ctx.scheduler.completedCount +
        ctx.scheduler.failedCount +
        ctx.scheduler.cancelledCount;
    if (total != accounted) {
      return InvariantViolation(
        invariantId: id,
        description: 'Task count mismatch: total=$total accounted=$accounted',
        severity: severity,
        context: {'total': total, 'accounted': accounted},
        timestamp: ctx.clock.now());
    }
    return null;
  }
}

class EventBusNoLeakedSubscriptionsInvariant implements RuntimeInvariant {
  @override
  final id = 'INV-EVENT-001';
  @override
  final description = 'EventBus subscriptions should not leak';
  @override
  final severity = InvariantSeverity.important;

  @override
  InvariantViolation? check(RuntimeInvariantContext ctx) {
    final subCount = ctx.eventBus.subscriptionCount;
    final pluginCount = ctx.pluginRegistry.pluginCount;
    if (subCount > pluginCount * 20 && pluginCount > 0) {
      return InvariantViolation(
        invariantId: id,
        description:
            'Potential subscription leak: $subCount subs for $pluginCount plugins',
        severity: InvariantSeverity.warning,
        context: {'subscriptionCount': subCount, 'pluginCount': pluginCount},
        timestamp: ctx.clock.now());
    }
    return null;
  }
}

class InvariantChecker {
  final List<RuntimeInvariant> _invariants = [];
  final List<InvariantViolation> _violations = [];

  InvariantChecker() {
    _invariants.addAll([
      TaskTerminalStateInvariant(),
      SchedulerNoOrphanTasksInvariant(),
      EventBusNoLeakedSubscriptionsInvariant(),
    ]);
  }

  List<InvariantViolation> get violations => List.unmodifiable(_violations);
  int get violationCount => _violations.length;
  bool get hasCriticalViolations =>
      _violations.any((v) => v.severity == InvariantSeverity.critical);

  List<InvariantViolation> checkAll(RuntimeInvariantContext ctx) {
    final newViolations = <InvariantViolation>[];
    for (final invariant in _invariants) {
      final violation = invariant.check(ctx);
      if (violation != null) {
        newViolations.add(violation);
        _violations.add(violation);
      }
    }
    return newViolations;
  }

  void clear() => _violations.clear();
}
