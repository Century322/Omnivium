import 'dart:async';
import '../../app_logger.dart';
import '../cognitive/cognitive_types.dart';
import '../cognitive/goal_runtime.dart';
import '../cognitive/goal_store.dart';
import 'agent_runtime.dart';
import 'priority_manager.dart';

class ScheduledJob {
  final String id;
  final String name;
  final Duration interval;
  final Future<void> Function() callback;
  DateTime lastRun;
  DateTime? nextRun;
  bool enabled;

  ScheduledJob({
    required this.id,
    required this.name,
    required this.interval,
    required this.callback,
    DateTime? lastRun,
    this.nextRun,
    this.enabled = true,
  }) : lastRun = lastRun ?? DateTime.now();
}

class TaskScheduler {
  final AgentRuntime runtime;
  final PriorityManager priorityManager;
  final GoalStore goalStore;

  final Map<String, ScheduledJob> _jobs = {};
  Timer? _tickTimer;
  static const _tickInterval = Duration(minutes: 5);

  TaskScheduler({
    required this.runtime,
    required this.priorityManager,
    required this.goalStore,
  });

  void start() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(_tickInterval, (_) => _tick());
    AppLogger.instance.info('TaskScheduler started');
  }

  void stop() {
    _tickTimer?.cancel();
    _tickTimer = null;
    AppLogger.instance.info('TaskScheduler stopped');
  }

  void registerJob(ScheduledJob job) {
    _jobs[job.id] = job;
  }

  void unregisterJob(String jobId) {
    _jobs.remove(jobId);
  }

  void _tick() {
    final now = DateTime.now();

    for (final job in _jobs.values) {
      if (!job.enabled) continue;
      if (job.nextRun != null && now.isBefore(job.nextRun!)) continue;

      final elapsed = now.difference(job.lastRun);
      if (elapsed >= job.interval) {
        _executeJob(job);
      }
    }

    _checkGoalDeadlines();
  }

  void _executeJob(ScheduledJob job) {
    job.lastRun = DateTime.now();
    job.nextRun = job.lastRun.add(job.interval);

    runtime.submitTask(
      description: 'Scheduled: ${job.name}',
      priority: TaskPriority.low,
      metadata: {'type': 'scheduled', 'jobId': job.id},
    );

    job.callback().catchError((e) {
      AppLogger.instance.warning('Scheduled job ${job.name} failed', error: e);
    });
  }

  void _checkGoalDeadlines() {
    final now = DateTime.now();
    final activeGoals = goalStore.getActiveGoals();

    for (final goal in activeGoals) {
      if (goal.deadline == null) continue;
      if (goal.status == GoalStatus.completed) continue;

      final daysLeft = goal.deadline!.difference(now).inDays;

      if (daysLeft <= 1 && daysLeft > 0) {
        runtime.submitTask(
          description: '目标"${goal.title}"即将到期，需要优先处理',
          priority: TaskPriority.urgent,
          metadata: {'type': 'deadline_warning', 'goalId': goal.id},
        );
      } else if (daysLeft <= 0) {
        runtime.submitTask(
          description: '目标"${goal.title}"已逾期',
          priority: TaskPriority.critical,
          metadata: {'type': 'deadline_overdue', 'goalId': goal.id},
        );
      }
    }
  }

  List<ScheduledJob> get jobs => _jobs.values.toList();
  List<ScheduledJob> get enabledJobs => _jobs.values.where((j) => j.enabled).toList();

  void dispose() {
    stop();
  }
}
