import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';
import 'app_logger.dart';
import 'database_service.dart';
import 'omni_model.dart';
import 'action_executor.dart';

part 'state_service.freezed.dart';

enum StateChangeType {
  created,
  updated,
  deleted,
  actionExecuted,
  stateTransition,
}

@freezed
class StateChange with _$StateChange {
  const StateChange._();

  const factory StateChange({
    required String id,
    required String objectId,
    required String objectType,
    required StateChangeType changeType,
    String? actionId,
    @Default(<String, dynamic>{}) Map<String, dynamic> previousState,
    @Default(<String, dynamic>{}) Map<String, dynamic> newState,
    Map<String, dynamic>? actionParams,
    required bool success,
    String? error,
    String? agentId,
    String? workspaceId,
    required DateTime timestamp,
  }) = _StateChange;

  Map<String, dynamic> toJson() => {
    'id': id,
    'objectId': objectId,
    'objectType': objectType,
    'changeType': changeType.name,
    if (actionId != null) 'actionId': actionId,
    'previousState': previousState,
    'newState': newState,
    if (actionParams != null) 'actionParams': actionParams,
    'success': success,
    if (error != null) 'error': error,
    if (agentId != null) 'agentId': agentId,
    if (workspaceId != null) 'workspaceId': workspaceId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory StateChange.fromJson(Map<String, dynamic> json) => StateChange(
    id: json['id'] as String,
    objectId: json['objectId'] as String,
    objectType: json['objectType'] as String,
    changeType: StateChangeType.values.firstWhere(
      (e) => e.name == json['changeType'],
      orElse: () => StateChangeType.updated,
    ),
    actionId: json['actionId'] as String?,
    previousState: (json['previousState'] as Map<String, dynamic>?) ?? {},
    newState: (json['newState'] as Map<String, dynamic>?) ?? {},
    actionParams: json['actionParams'] as Map<String, dynamic>?,
    success: json['success'] as bool? ?? true,
    error: json['error'] as String?,
    agentId: json['agentId'] as String?,
    workspaceId: json['workspaceId'] as String?,
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}

@freezed
class ObjectState with _$ObjectState {
  const ObjectState._();

  const factory ObjectState({
    required String objectId,
    required String objectType,
    @Default(<String, dynamic>{}) Map<String, dynamic> state,
    required DateTime lastModified,
    String? lastActionId,
    @Default(1) int changeCount,
    String? workspaceId,
  }) = _ObjectState;

  Map<String, dynamic> toJson() => {
    'objectId': objectId,
    'objectType': objectType,
    'state': state,
    'lastModified': lastModified.toIso8601String(),
    if (lastActionId != null) 'lastActionId': lastActionId,
    'changeCount': changeCount,
    if (workspaceId != null) 'workspaceId': workspaceId,
  };

  factory ObjectState.fromJson(Map<String, dynamic> json) => ObjectState(
    objectId: json['objectId'] as String,
    objectType: json['objectType'] as String,
    state: (json['state'] as Map<String, dynamic>?) ?? {},
    lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ?? DateTime.now(),
    lastActionId: json['lastActionId'] as String?,
    changeCount: json['changeCount'] as int? ?? 1,
    workspaceId: json['workspaceId'] as String?,
  );
}

class StateSnapshot {
  final String id;
  final DateTime timestamp;
  final Map<String, ObjectState> objectStates;
  final String? trigger;
  final String? workspaceId;

  const StateSnapshot({
    required this.id,
    required this.timestamp,
    required this.objectStates,
    this.trigger,
    this.workspaceId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'objectStates': objectStates.map((k, v) => MapEntry(k, v.toJson())),
    if (trigger != null) 'trigger': trigger,
    if (workspaceId != null) 'workspaceId': workspaceId,
  };

  factory StateSnapshot.fromJson(Map<String, dynamic> json) {
    final statesMap = (json['objectStates'] as Map<String, dynamic>?) ?? {};
    return StateSnapshot(
      id: json['id'] as String,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      objectStates: statesMap.map((k, v) =>
          MapEntry(k, ObjectState.fromJson(v as Map<String, dynamic>))),
      trigger: json['trigger'] as String?,
      workspaceId: json['workspaceId'] as String?,
    );
  }
}

class StateService {
  final DatabaseService _db;
  bool _isInitialized = false;

  static const _changesKey = 'state_changes';
  static const _statesKey = 'state_current';
  static const _snapshotsKey = 'state_snapshots';
  static const _maxChanges = 500;
  static const _maxSnapshots = 20;
  static const _snapshotInterval = Duration(hours: 6);

  List<StateChange> _changes = [];
  Map<String, ObjectState> _currentStates = {};
  List<StateSnapshot> _snapshots = [];
  DateTime? _lastSnapshotTime;

  StateService(this._db);

  bool get isInitialized => _isInitialized;
  int get totalChanges => _changes.length;
  int get trackedObjects => _currentStates.length;
  int get snapshotCount => _snapshots.length;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final changesJson = await _db.getCache(_changesKey);
      if (changesJson != null) {
        final list = jsonDecode(changesJson) as List<dynamic>;
        _changes = list
            .map((e) => StateChange.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final statesJson = await _db.getCache(_statesKey);
      if (statesJson != null) {
        final map = jsonDecode(statesJson) as Map<String, dynamic>;
        _currentStates = map.map((k, v) =>
            MapEntry(k, ObjectState.fromJson(v as Map<String, dynamic>)));
      }
      final snapshotsJson = await _db.getCache(_snapshotsKey);
      if (snapshotsJson != null) {
        final list = jsonDecode(snapshotsJson) as List<dynamic>;
        _snapshots = list
            .map((e) => StateSnapshot.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _isInitialized = true;
      AppLogger.instance.info(
        'StateService initialized: ${_currentStates.length} objects, ${_changes.length} changes',
      );
    } catch (e, st) {
      AppLogger.instance.error('StateService init failed', error: e, stackTrace: st);
      _isInitialized = true;
    }
  }

  Future<void> recordChange(StateChange change) async {
    _changes.add(change);

    _currentStates[change.objectId] = ObjectState(
      objectId: change.objectId,
      objectType: change.objectType,
      state: change.newState,
      lastModified: change.timestamp,
      lastActionId: change.actionId,
      changeCount: (_currentStates[change.objectId]?.changeCount ?? 0) + 1,
      workspaceId: change.workspaceId,
    );

    if (change.changeType == StateChangeType.deleted) {
      _currentStates.remove(change.objectId);
    }

    if (_changes.length > _maxChanges) {
      _changes = _changes.sublist(_changes.length - _maxChanges);
    }

    await _tryAutoSnapshot();
    await _persist();
  }

  Future<void> recordActionExecution(
    ActionResult result, {
    required OmniObject target,
    required OmniAction action,
    Map<String, dynamic>? params,
    String? agentId,
    String? workspaceId,
  }) async {
    final changeType = result.success
        ? StateChangeType.actionExecuted
        : StateChangeType.updated;

    final previousState = _currentStates[target.id]?.state ?? target.state;

    final newState = result.success
        ? <String, dynamic>{
            ...target.state,
            'lastAction': action.id,
            'lastActionTime': DateTime.now().toIso8601String(),
            if (result.data != null) ...result.data!,
          }
        : <String, dynamic>{
            ...target.state,
            'lastError': result.error,
            'lastErrorTime': DateTime.now().toIso8601String(),
          };

    await recordChange(StateChange(
      id: 'sc_${DateTime.now().millisecondsSinceEpoch}_${target.id.hashCode.abs()}',
      objectId: target.id,
      objectType: target.objectType.name,
      changeType: changeType,
      actionId: action.id,
      previousState: previousState,
      newState: newState,
      actionParams: params,
      success: result.success,
      error: result.error,
      agentId: agentId,
      workspaceId: workspaceId,
      timestamp: DateTime.now(),
    ));
  }

  ObjectState? getCurrentState(String objectId) => _currentStates[objectId];

  Map<String, ObjectState> getAllCurrentStates({
    String? objectType,
    String? workspaceId,
  }) {
    var result = _currentStates.values.toList();

    if (objectType != null) {
      result = result.where((s) => s.objectType == objectType).toList();
    }
    if (workspaceId != null) {
      result = result.where((s) => s.workspaceId == workspaceId).toList();
    }

    return {for (final s in result) s.objectId: s};
  }

  List<StateChange> getHistory(String objectId, {int limit = 50}) =>
      _changes
          .where((c) => c.objectId == objectId)
          .toList()
          .reversed
          .take(limit)
          .toList();

  List<StateChange> getRecentChanges({
    int limit = 50,
    String? objectType,
    String? workspaceId,
  }) {
    var filtered = _changes.toList().reversed;
    if (objectType != null) {
      filtered = filtered.where((c) => c.objectType == objectType);
    }
    if (workspaceId != null) {
      filtered = filtered.where((c) => c.workspaceId == workspaceId);
    }
    return filtered.take(limit).toList();
  }

  List<StateChange> getFailedActions({int limit = 20}) =>
      _changes
          .where((c) => !c.success)
          .toList()
          .reversed
          .take(limit)
          .toList();

  Map<String, dynamic>? reconstructStateAt(String objectId, DateTime pointInTime) {
    Map<String, dynamic> state = {};
    bool found = false;

    for (final change in _changes) {
      if (change.objectId != objectId) continue;
      if (change.timestamp.isAfter(pointInTime)) continue;

      if (change.changeType == StateChangeType.deleted &&
          change.timestamp.isBefore(pointInTime)) {
        return null;
      }

      state = {...state, ...change.newState};
      found = true;
    }

    return found ? state : null;
  }

  Future<StateSnapshot> takeSnapshot({String? trigger, String? workspaceId}) async {
    final snapshot = StateSnapshot(
      id: 'snap_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      objectStates: Map.from(_currentStates),
      trigger: trigger,
      workspaceId: workspaceId,
    );

    _snapshots.add(snapshot);
    if (_snapshots.length > _maxSnapshots) {
      _snapshots = _snapshots.sublist(_snapshots.length - _maxSnapshots);
    }

    _lastSnapshotTime = DateTime.now();
    await _persist();
    return snapshot;
  }

  StateSnapshot? getLatestSnapshot() =>
      _snapshots.isNotEmpty ? _snapshots.last : null;

  Future<bool> restoreFromSnapshot(String snapshotId) async {
    final snapshot = _snapshots.where((s) => s.id == snapshotId).firstOrNull;
    if (snapshot == null) return false;

    _currentStates = Map.from(snapshot.objectStates);

    await recordChange(StateChange(
      id: 'sc_restore_${DateTime.now().millisecondsSinceEpoch}',
      objectId: '__system__',
      objectType: 'system',
      changeType: StateChangeType.stateTransition,
      previousState: {'restoredFrom': 'unknown'},
      newState: {'restoredFrom': snapshotId, 'objectCount': snapshot.objectStates.length},
      success: true,
      timestamp: DateTime.now(),
    ));

    AppLogger.instance.info(
      'State restored from snapshot $snapshotId (${snapshot.objectStates.length} objects)',
    );
    return true;
  }

  String buildStateContext({String? workspaceId}) {
    final buffer = StringBuffer();
    buffer.writeln('[System State]');

    final states = getAllCurrentStates(workspaceId: workspaceId);
    if (states.isEmpty) {
      buffer.writeln('No tracked objects.');
      return buffer.toString();
    }

    final byType = <String, List<ObjectState>>{};
    for (final state in states.values) {
      byType.putIfAbsent(state.objectType, () => []).add(state);
    }

    for (final entry in byType.entries) {
      buffer.writeln('\n${entry.key} (${entry.value.length}):');
      for (final obj in entry.value.take(10)) {
        final age = DateTime.now().difference(obj.lastModified);
        final ageStr = age.inMinutes < 60
            ? '${age.inMinutes}m ago'
            : age.inHours < 24
                ? '${age.inHours}h ago'
                : '${age.inDays}d ago';
        buffer.writeln(
          '  - ${obj.objectId}: ${_summarizeState(obj.state)} [$ageStr, ${obj.changeCount} changes]',
        );
      }
      if (entry.value.length > 10) {
        buffer.writeln('  ... and ${entry.value.length - 10} more');
      }
    }

    final recentActions = getRecentChanges(limit: 5, workspaceId: workspaceId);
    if (recentActions.isNotEmpty) {
      buffer.writeln('\nRecent actions:');
      for (final change in recentActions) {
        final status = change.success ? '✓' : '✗';
        final action = change.actionId ?? change.changeType.name;
        buffer.writeln(
          '  $status ${change.objectType}.${action} → ${change.objectId}',
        );
        if (change.error != null) {
          buffer.writeln('    Error: ${change.error}');
        }
      }
    }

    final failedActions = getFailedActions(limit: 3);
    if (failedActions.isNotEmpty) {
      buffer.writeln('\nFailed actions:');
      for (final change in failedActions) {
        buffer.writeln(
          '  ✗ ${change.objectType}.${change.actionId ?? change.changeType.name} → ${change.objectId}: ${change.error ?? "unknown"}',
        );
      }
    }

    return buffer.toString();
  }

  String _summarizeState(Map<String, dynamic> state) {
    if (state.isEmpty) return '{}';
    final keys = state.keys.take(3).toList();
    final summary = keys.map((k) {
      final v = state[k];
      if (v is String && v.length > 20) return '$k=${v.substring(0, 17)}...';
      return '$k=$v';
    }).join(', ');
    return state.length > 3 ? '$summary ...' : summary;
  }

  Map<String, dynamic> getStateSummary({String? workspaceId}) {
    final states = getAllCurrentStates(workspaceId: workspaceId);
    final byType = <String, int>{};
    var totalChanges = 0;
    var recentFailures = 0;

    for (final state in states.values) {
      byType[state.objectType] = (byType[state.objectType] ?? 0) + 1;
      totalChanges += state.changeCount;
    }

    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    recentFailures = _changes
        .where((c) => !c.success && c.timestamp.isAfter(oneHourAgo))
        .length;

    return {
      'trackedObjects': states.length,
      'totalChanges': totalChanges,
      'byType': byType,
      'recentFailures': recentFailures,
      'snapshots': _snapshots.length,
    };
  }

  Future<void> _tryAutoSnapshot() async {
    final now = DateTime.now();
    if (_lastSnapshotTime != null &&
        now.difference(_lastSnapshotTime!) < _snapshotInterval) {
      return;
    }
    await takeSnapshot(trigger: 'auto');
  }

  Future<void> _persist() async {
    try {
      await _db.putCache(
        _changesKey,
        jsonEncode(_changes.map((e) => e.toJson()).toList()),
      );
      await _db.putCache(
        _statesKey,
        jsonEncode(_currentStates.map((k, v) => MapEntry(k, v.toJson()))),
      );
      await _db.putCache(
        _snapshotsKey,
        jsonEncode(_snapshots.map((e) => e.toJson()).toList()),
      );
    } catch (e, st) {
      AppLogger.instance.error('StateService persist failed', error: e, stackTrace: st);
    }
  }

  Future<void> clear() async {
    _changes.clear();
    _currentStates.clear();
    _snapshots.clear();
    _lastSnapshotTime = null;
    await _persist();
  }
}
