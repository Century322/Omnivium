import 'dart:async';
import 'vocabulary/runtime_task.dart';
import 'kernel/runtime_config.dart';

enum TaskState { pending, running, completed, failed, cancelled, retrying }

class ScheduledTask {
  final RuntimeTask task;
  final Future<dynamic> Function(CancellationToken token) executor;
  TaskState _state = TaskState.pending;
  int _retryCount = 0;
  final Completer<dynamic> _completer = Completer<dynamic>();
  CancellationToken? _cancellationToken;

  ScheduledTask({required this.task, required this.executor});

  TaskState get state => _state;
  int get retryCount => _retryCount;
  Completer<dynamic> get completer => _completer;
  bool get isDone =>
      _state == TaskState.completed ||
      _state == TaskState.failed ||
      _state == TaskState.cancelled;
}

class CancellationToken {
  bool _isCancelled = false;
  final List<void Function()> _callbacks = [];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final cb in _callbacks) {
      cb();
    }
    _callbacks.clear();
  }

  void onCancel(void Function() callback) {
    if (_isCancelled) {
      callback();
    } else {
      _callbacks.add(callback);
    }
  }
}

class _PrioritizedTask implements Comparable<_PrioritizedTask> {
  final int priority;
  final ScheduledTask task;

  _PrioritizedTask(this.priority, this.task);

  @override
  int compareTo(_PrioritizedTask other) => priority.compareTo(other.priority);
}

class Scheduler {
  final RuntimeConfig _config;
  final Map<String, ScheduledTask> _tasks = {};
  final List<_PrioritizedTask> _queue = [];
  int _runningCount = 0;
  int _completedCount = 0;
  int _failedCount = 0;
  int _cancelledCount = 0;

  Scheduler({required RuntimeConfig config}) : _config = config;

  int get pendingCount => _queue.length;
  int get runningCount => _runningCount;
  int get completedCount => _completedCount;
  int get failedCount => _failedCount;
  int get cancelledCount => _cancelledCount;
  int get totalTasks => _tasks.length;

  Future<dynamic> schedule(
    RuntimeTask task,
    Future<dynamic> Function(CancellationToken token) executor) async {
    if (_tasks.containsKey(task.id)) {
      throw StateError('Task "${task.id}" already scheduled');
    }

    final scheduled = ScheduledTask(task: task, executor: executor);
    _tasks[task.id] = scheduled;

    _queue.add(_PrioritizedTask(task.priority.value, scheduled));
    _queue.sort((a, b) => a.compareTo(b));

    _tryRunNext();

    return scheduled.completer.future;
  }

  bool cancel(String taskId) {
    final scheduled = _tasks[taskId];
    if (scheduled == null || scheduled.isDone) return false;

    scheduled._cancellationToken?.cancel();
    scheduled._state = TaskState.cancelled;
    _cancelledCount++;
    if (!scheduled._completer.isCompleted) {
      scheduled._completer.completeError(
        StateError('Task "$taskId" cancelled'));
    }
    return true;
  }

  void cancelAll() {
    for (final task in _tasks.values) {
      if (!task.isDone) {
        cancel(task.task.id);
      }
    }
  }

  TaskState? taskState(String taskId) => _tasks[taskId]?.state;

  Map<String, TaskState> get taskStates =>
      _tasks.map((id, t) => MapEntry(id, t.state));

  void _tryRunNext() {
    while (_runningCount < _config.maxConcurrentTasks && _queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      _execute(next.task);
    }
  }

  Future<void> _execute(ScheduledTask scheduled) async {
    _runningCount++;
    scheduled._state = TaskState.running;

    final token = CancellationToken();
    scheduled._cancellationToken = token;

    try {
      final result = await scheduled
          .executor(token)
          .timeout(Duration(milliseconds: scheduled.task.budget.maxDurationMs));

      if (token.isCancelled) return;

      scheduled._state = TaskState.completed;
      _completedCount++;
      if (!scheduled._completer.isCompleted) {
        scheduled._completer.complete(result);
      }
    } catch (e) {
      if (token.isCancelled) return;

      if (scheduled._retryCount < scheduled.task.budget.maxRetries) {
        scheduled._retryCount++;
        scheduled._state = TaskState.retrying;

        final delay = scheduled.task.failurePolicy.retry.delayForAttempt(
          scheduled._retryCount);
        await Future<void>.delayed(delay);

        if (!token.isCancelled) {
          _runningCount--;
          _execute(scheduled);
          return;
        }
      }

      scheduled._state = TaskState.failed;
      _failedCount++;
      if (!scheduled._completer.isCompleted) {
        scheduled._completer.completeError(e);
      }
    } finally {
      _runningCount--;
      _tryRunNext();
    }
  }
}
