import 'dart:async';
import '../../app_logger.dart';

enum TaskState {
  pending,
  running,
  paused,
  completed,
  failed,
  cancelled,
}

enum TaskPriority {
  low,
  normal,
  high,
  urgent,
  critical,
}

enum InterruptPolicy {
  pause,
  queue,
  notify,
  ignore,
}

class AgentTask {
  final String id;
  final String description;
  final TaskPriority priority;
  TaskState state;
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? completedAt;
  final String? parentTaskId;
  final List<String> dependencies;
  final Map<String, dynamic> metadata;
  final InterruptPolicy interruptPolicy;
  final Completer<AgentTaskResult> _completer = Completer();

  AgentTask({
    required this.id,
    required this.description,
    this.priority = TaskPriority.normal,
    this.state = TaskState.pending,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.parentTaskId,
    this.dependencies = const [],
    this.metadata = const {},
    this.interruptPolicy = InterruptPolicy.queue,
  }) : createdAt = createdAt ?? DateTime.now();

  Future<AgentTaskResult> get result => _completer.future;

  void complete(AgentTaskResult result) {
    if (!_completer.isCompleted) {
      _completer.complete(result);
    }
  }

  void fail(Object error) {
    if (!_completer.isCompleted) {
      _completer.completeError(error);
    }
  }
}

class AgentTaskResult {
  final bool success;
  final String? output;
  final Object? error;
  final Map<String, dynamic> data;

  const AgentTaskResult({
    required this.success,
    this.output,
    this.error,
    this.data = const {},
  });
}

class InterruptEvent {
  final String id;
  final String source;
  final String reason;
  final TaskPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const InterruptEvent({
    required this.id,
    required this.source,
    required this.reason,
    this.priority = TaskPriority.urgent,
    required this.timestamp,
    this.data = const {},
  });
}

class AgentRuntime {
  final Map<String, AgentTask> _tasks = {};
  final List<AgentTask> _readyQueue = [];
  AgentTask? _currentTask;
  final StreamController<AgentTask> _taskController = StreamController.broadcast();
  final StreamController<InterruptEvent> _interruptController = StreamController.broadcast();

  final Map<String, InterruptPolicy> _sourcePolicies = {};

  static const _maxConcurrentTasks = 1;

  AgentRuntime() {
    _sourcePolicies['user_message'] = InterruptPolicy.pause;
    _sourcePolicies['friend_message'] = InterruptPolicy.notify;
    _sourcePolicies['timer'] = InterruptPolicy.queue;
    _sourcePolicies['system'] = InterruptPolicy.pause;
  }

  Stream<AgentTask> get taskStream => _taskController.stream;
  Stream<InterruptEvent> get interruptStream => _interruptController.stream;
  AgentTask? get currentTask => _currentTask;
  List<AgentTask> get pendingTasks => _readyQueue.toList();
  List<AgentTask> get allTasks => _tasks.values.toList();
  bool get isIdle => _currentTask == null;

  void setInterruptPolicy(String source, InterruptPolicy policy) {
    _sourcePolicies[source] = policy;
  }

  AgentTask submitTask({
    required String description,
    TaskPriority priority = TaskPriority.normal,
    String? parentTaskId,
    List<String>? dependencies,
    Map<String, dynamic>? metadata,
    InterruptPolicy interruptPolicy = InterruptPolicy.queue,
  }) {
    final task = AgentTask(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}_${description.hashCode.abs()}',
      description: description,
      priority: priority,
      parentTaskId: parentTaskId,
      dependencies: dependencies ?? [],
      metadata: metadata ?? {},
      interruptPolicy: interruptPolicy,
    );

    _tasks[task.id] = task;
    _enqueueTask(task);
    _taskController.add(task);
    _scheduleNext();

    return task;
  }

  void _enqueueTask(AgentTask task) {
    _readyQueue.add(task);
    _readyQueue.sort((a, b) {
      final priorityOrder = {
        TaskPriority.critical: 0, TaskPriority.urgent: 1, TaskPriority.high: 2,
        TaskPriority.normal: 3, TaskPriority.low: 4,
      };
      final cmp = priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      if (cmp != 0) return cmp;
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  void _scheduleNext() {
    if (_currentTask != null) return;
    if (_readyQueue.isEmpty) return;

    while (_readyQueue.isNotEmpty) {
      final task = _readyQueue.removeAt(0);
      if (task.state != TaskState.pending) continue;
      if (!_dependenciesMet(task)) continue;

      _currentTask = task;
      task.state = TaskState.running;
      task.startedAt = DateTime.now();
      _taskController.add(task);
      return;
    }
  }

  bool _dependenciesMet(AgentTask task) {
    for (final depId in task.dependencies) {
      final dep = _tasks[depId];
      if (dep == null || dep.state != TaskState.completed) return false;
    }
    return true;
  }

  void completeCurrentTask(AgentTaskResult result) {
    if (_currentTask == null) return;
    _currentTask!.state = result.success ? TaskState.completed : TaskState.failed;
    _currentTask!.completedAt = DateTime.now();
    _currentTask!.complete(result);
    _taskController.add(_currentTask!);
    _currentTask = null;
    _scheduleNext();
  }

  void pauseCurrentTask() {
    if (_currentTask == null) return;
    _currentTask!.state = TaskState.paused;
    _taskController.add(_currentTask!);
    _enqueueTask(_currentTask!);
    _currentTask = null;
    _scheduleNext();
  }

  void resumeTask(String taskId) {
    final task = _tasks[taskId];
    if (task == null || task.state != TaskState.paused) return;
    task.state = TaskState.pending;
    _enqueueTask(task);
    _scheduleNext();
  }

  void cancelTask(String taskId) {
    final task = _tasks[taskId];
    if (task == null) return;
    task.state = TaskState.cancelled;
    task.completedAt = DateTime.now();
    task.complete(const AgentTaskResult(success: false, output: 'Cancelled'));
    _readyQueue.removeWhere((t) => t.id == taskId);
    if (_currentTask?.id == taskId) {
      _currentTask = null;
      _scheduleNext();
    }
  }

  InterruptAction handleInterrupt(InterruptEvent event) {
    final policy = _sourcePolicies[event.source] ?? InterruptPolicy.queue;

    _interruptController.add(event);

    switch (policy) {
      case InterruptPolicy.pause:
        if (_currentTask != null) {
          pauseCurrentTask();
          return InterruptAction.paused;
        }
        return InterruptAction.ignored;
      case InterruptPolicy.queue:
        return InterruptAction.queued;
      case InterruptPolicy.notify:
        return InterruptAction.notified;
      case InterruptPolicy.ignore:
        return InterruptAction.ignored;
    }
  }

  List<AgentTask> getTasksByState(TaskState state) =>
      _tasks.values.where((t) => t.state == state).toList();

  List<AgentTask> getSubTasks(String parentTaskId) =>
      _tasks.values.where((t) => t.parentTaskId == parentTaskId).toList();

  void dispose() {
    _taskController.close();
    _interruptController.close();
  }
}

enum InterruptAction {
  paused,
  queued,
  notified,
  ignored,
}
