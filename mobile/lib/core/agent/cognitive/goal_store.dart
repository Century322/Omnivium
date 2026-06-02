import 'dart:convert';
import '../../app_logger.dart';
import '../../database_service.dart';
import 'cognitive_types.dart';
import 'goal_runtime.dart';
import 'memory_transaction.dart';

class GoalStore {
  static const _goalsKey = 'cognitive_goals';
  final DatabaseService _db;
  List<GoalNode> _goals = [];
  bool _initialized = false;
  bool _dirty = false;

  GoalStore(this._db);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final json = await _db.getCache(_goalsKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _goals = list.map((e) => GoalNode.fromJson(e as Map<String, dynamic>)).toList();
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('GoalStore init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persist() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      await _db.putCache(_goalsKey, jsonEncode(_goals.map((g) => g.toJson()).toList()));
    } catch (e, st) {
      AppLogger.instance.error('GoalStore persist failed', error: e, stackTrace: st);
    }
  }

  void _markDirty() => _dirty = true;

  void registerWithTransaction(MemoryTransaction tx) {
    if (!_dirty) return;
    tx.register(_goalsKey, () => jsonEncode(_goals.map((g) => g.toJson()).toList()));
    _dirty = false;
  }

  List<GoalNode> get goals => List.unmodifiable(_goals);

  GoalNode? getGoal(String id) {
    final idx = _goals.indexWhere((g) => g.id == id);
    return idx >= 0 ? _goals[idx] : null;
  }

  List<GoalNode> getRootGoals({String? workspaceId}) {
    return _goals.where((g) {
      if (g.parentGoalId != null) return false;
      if (workspaceId != null && g.workspaceId != workspaceId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  List<GoalNode> getSubGoals(String parentGoalId) {
    return _goals.where((g) => g.parentGoalId == parentGoalId).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  List<GoalNode> getActiveGoals({String? workspaceId}) {
    return _goals.where((g) {
      if (g.status == GoalStatus.completed || g.status == GoalStatus.abandoned) return false;
      if (workspaceId != null && g.workspaceId != workspaceId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  List<GoalNode> getOverdueGoals() =>
      _goals.where((g) => g.isOverdue).toList();

  List<GoalNode> getBlockedGoals() =>
      _goals.where((g) => g.isBlocked && g.status == GoalStatus.inProgress).toList();

  Future<GoalNode> upsertGoal(GoalNode goal) async {
    final idx = _goals.indexWhere((g) => g.id == goal.id);
    if (idx >= 0) {
      _goals[idx] = goal;
    } else {
      _goals.add(goal);
    }
    _markDirty();
    return goal;
  }

  Future<GoalNode> createGoal({
    required String title,
    String? parentGoalId,
    String? workspaceId,
    int priority = 50,
    List<String>? successConditions,
    List<String>? failureConditions,
    DateTime? deadline,
    List<String>? dependencies,
    List<String>? relatedEntityIds,
  }) async {
    final goal = GoalNode(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}_${title.hashCode.abs()}',
      title: title,
      parentGoalId: parentGoalId,
      workspaceId: workspaceId,
      priority: priority,
      createdAt: DateTime.now(),
      successConditions: successConditions ?? [],
      failureConditions: failureConditions ?? [],
      deadline: deadline,
      dependencies: dependencies ?? [],
      relatedEntityIds: relatedEntityIds ?? [],
    );
    return upsertGoal(goal);
  }

  Future<void> updateGoalProgress(String goalId, int progress) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx < 0) return;
    var goal = _goals[idx].copyWith(progress: progress.clamp(0, 100));
    if (progress >= 100) {
      goal = goal.copyWith(
        status: GoalStatus.completed,
        completedAt: DateTime.now(),
      );
    }
    _goals[idx] = goal;
    _markDirty();
  }

  Future<void> updateGoalStatus(String goalId, GoalStatus status) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx < 0) return;
    var goal = _goals[idx].copyWith(status: status);
    if (status == GoalStatus.completed) {
      goal = goal.copyWith(completedAt: DateTime.now(), progress: 100);
    }
    _goals[idx] = goal;
    _markDirty();
  }

  Future<void> addBlocker(String goalId, String blocker) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx < 0) return;
    final blockers = [..._goals[idx].blockers];
    if (!blockers.contains(blocker)) {
      blockers.add(blocker);
      _goals[idx] = _goals[idx].copyWith(blockers: blockers);
      _markDirty();
    }
  }

  Future<void> removeBlocker(String goalId, String blocker) async {
    final idx = _goals.indexWhere((g) => g.id == goalId);
    if (idx < 0) return;
    final blockers = _goals[idx].blockers.where((b) => b != blocker).toList();
    _goals[idx] = _goals[idx].copyWith(blockers: blockers);
    _markDirty();
  }

  Future<void> removeGoal(String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
    for (var i = 0; i < _goals.length; i++) {
      if (_goals[i].parentGoalId == goalId) {
        _goals[i] = _goals[i].copyWith(parentGoalId: null);
      }
    }
    _markDirty();
  }

  int get goalCount => _goals.length;

  Map<String, int> get goalCountsByStatus {
    final counts = <String, int>{};
    for (final g in _goals) {
      counts[g.status.name] = (counts[g.status.name] ?? 0) + 1;
    }
    return counts;
  }
}
