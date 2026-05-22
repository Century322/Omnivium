import 'runtime_permission.dart';
import 'runtime_route.dart';
import 'runtime_event.dart';
import 'failure_policy.dart';

enum TaskPriority {
  critical(0),
  high(1),
  normal(2),
  low(3),
  idle(4);

  final int value;
  const TaskPriority(this.value);
}

class SchedulerHint {
  final String? preferredNode;
  final IsolationLevel isolationLevel;
  final int? deadline;

  const SchedulerHint({
    this.preferredNode,
    this.isolationLevel = IsolationLevel.level0InProcess,
    this.deadline,
  });
}

class RuntimeTask {
  final String id;
  final int version;
  final String type;
  final RuntimeRoute source;
  final TaskPriority priority;
  final TaskBudget budget;
  final SchedulerHint schedulerHint;
  final FailurePolicy failurePolicy;
  final PropagationScope scope;
  final int createdAt;

  const RuntimeTask({
    required this.id,
    this.version = 1,
    required this.type,
    required this.source,
    this.priority = TaskPriority.normal,
    this.budget = const TaskBudget(),
    this.schedulerHint = const SchedulerHint(),
    this.failurePolicy = const FailurePolicy(),
    this.scope = PropagationScope.local,
    required this.createdAt,
  });
}
