import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';
import 'app_logger.dart';
import 'database_service.dart';
import 'di/app_di.dart';
import 'state_service.dart';
import 'workspace_service.dart';
import 'agent_service.dart';
import 'planning_engine.dart';

part 'world_state_service.freezed.dart';

enum WorldObjectStatus {
  active,
  idle,
  blocked,
  completed,
  failed,
  pending,
  running,
  paused,
  destroyed,
}

@freezed
class WorldObject with _$WorldObject {
  const WorldObject._();

  const factory WorldObject({
    required String id,
    required String name,
    required String type,
    required WorldObjectStatus status,
    @Default(0) double progress,
    String? description,
    String? workspaceId,
    String? parentId,
    @Default(<String>[]) List<String> childrenIds,
    @Default(<String, dynamic>{}) Map<String, dynamic> properties,
    @Default(<String>[]) List<String> blockers,
    String? assignedAgentId,
    required DateTime lastModified,
  }) = _WorldObject;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'status': status.name,
    'progress': progress,
    if (description != null) 'description': description,
    if (workspaceId != null) 'workspaceId': workspaceId,
    if (parentId != null) 'parentId': parentId,
    'childrenIds': childrenIds,
    'properties': properties,
    'blockers': blockers,
    if (assignedAgentId != null) 'assignedAgentId': assignedAgentId,
    'lastModified': lastModified.toIso8601String(),
  };

  factory WorldObject.fromJson(Map<String, dynamic> json) => WorldObject(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    status: WorldObjectStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => WorldObjectStatus.active,
    ),
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
    description: json['description'] as String?,
    workspaceId: json['workspaceId'] as String?,
    parentId: json['parentId'] as String?,
    childrenIds: (json['childrenIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    properties: (json['properties'] as Map<String, dynamic>?) ?? {},
    blockers: (json['blockers'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    assignedAgentId: json['assignedAgentId'] as String?,
    lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ?? DateTime.now(),
  );
}

class WorldState {
  final DateTime timestamp;
  final Map<String, WorldObject> objects;
  final String? activeWorkspaceId;

  const WorldState({
    required this.timestamp,
    required this.objects,
    this.activeWorkspaceId,
  });

  List<WorldObject> get activeObjects => objects.values
      .where((o) => o.status == WorldObjectStatus.active || o.status == WorldObjectStatus.running)
      .toList();

  List<WorldObject> get blockedObjects => objects.values
      .where((o) => o.status == WorldObjectStatus.blocked || o.blockers.isNotEmpty)
      .toList();

  List<WorldObject> get runningAgents => objects.values
      .where((o) => o.type == 'agent' && o.status == WorldObjectStatus.running)
      .toList();

  List<WorldObject> get activeProjects => objects.values
      .where((o) => o.type == 'project' && o.status == WorldObjectStatus.active)
      .toList();

  List<WorldObject> get pendingTasks => objects.values
      .where((o) => o.type == 'task' && o.status == WorldObjectStatus.pending)
      .toList();
}

class WorldStateService {
  final DatabaseService _db;
  bool _isInitialized = false;

  static const _worldObjectsKey = 'world_objects';

  Map<String, WorldObject> _objects = {};

  WorldStateService(this._db);

  bool get isInitialized => _isInitialized;
  int get objectCount => _objects.length;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final json = await _db.getCache(_worldObjectsKey);
      if (json != null) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _objects = map.map((k, v) =>
            MapEntry(k, WorldObject.fromJson(v as Map<String, dynamic>)));
      }
      _isInitialized = true;
      AppLogger.instance.info('WorldStateService initialized: ${_objects.length} objects');
    } catch (e, st) {
      AppLogger.instance.error('WorldStateService init failed', error: e, stackTrace: st);
      _isInitialized = true;
    }
  }

  Future<void> upsertObject(WorldObject obj) async {
    _objects[obj.id] = obj;
    await _persist();
  }

  Future<void> removeObject(String id) async {
    _objects.remove(id);
    await _persist();
  }

  WorldObject? getObject(String id) => _objects[id];

  List<WorldObject> getObjectsByType(String type) =>
      _objects.values.where((o) => o.type == type).toList();

  List<WorldObject> getObjectsByWorkspace(String workspaceId) =>
      _objects.values.where((o) => o.workspaceId == workspaceId).toList();

  WorldState getCurrentState({String? workspaceId}) {
    var objects = _objects;
    if (workspaceId != null) {
      objects = Map.fromEntries(
        _objects.entries.where((e) => e.value.workspaceId == workspaceId),
      );
    }
    return WorldState(
      timestamp: DateTime.now(),
      objects: objects,
      activeWorkspaceId: workspaceId,
    );
  }

  Future<WorldState> refreshFromSources({String? workspaceId}) async {
    final objects = <String, WorldObject>{};

    try {
      final agentService = getIt<AgentService>();
      for (final agent in agentService.agents) {
        if (agent.isAlive) {
          objects[agent.id] = WorldObject(
            id: agent.id,
            name: agent.name,
            type: 'agent',
            status: _mapAgentLifecycle(agent.lifecycle),
            properties: {
              'role': agent.role.name,
              'capabilities': agent.capabilities,
            },
            workspaceId: agent.projectId,
            lastModified: DateTime.now(),
          );
        }
      }
    } catch (_) {}

    try {
      final planningEngine = getIt<PlanningEngine>();
      for (final plan in planningEngine.plans) {
        objects[plan.id] = WorldObject(
          id: plan.id,
          name: plan.title,
          type: 'plan',
          status: _mapPlanStatus(plan.status),
          progress: plan.progress,
          childrenIds: plan.steps.map((s) => s.id).toList(),
          properties: {
            'stepCount': plan.steps.length,
            'completedSteps': plan.steps.where((s) => s.isComplete).length,
          },
          lastModified: DateTime.now(),
        );
      }
    } catch (_) {}

    try {
      final workspaceService = getIt<WorkspaceService>();
      for (final ws in workspaceService.workspaces) {
        objects[ws.id] = WorldObject(
          id: ws.id,
          name: ws.name,
          type: 'project',
          status: WorldObjectStatus.active,
          properties: {
            'domain': ws.domain.name,
          },
          lastModified: ws.lastActiveAt,
        );
      }
    } catch (_) {}

    try {
      final stateService = getIt<StateService>();
      final states = stateService.getAllCurrentStates();
      for (final entry in states.entries) {
        if (objects.containsKey(entry.key)) continue;
        final state = entry.value;
        objects[state.objectId] = WorldObject(
          id: state.objectId,
          name: state.state['displayName'] as String? ?? state.objectId,
          type: state.objectType,
          status: _inferStatus(state.state),
          properties: state.state,
          lastModified: state.lastModified,
        );
      }
    } catch (_) {}

    _objects = objects;
    await _persist();

    return getCurrentState(workspaceId: workspaceId);
  }

  String buildWorldStateContext({String? workspaceId}) {
    final state = getCurrentState(workspaceId: workspaceId);
    final buffer = StringBuffer();
    buffer.writeln('[World State]');
    buffer.writeln('Updated: ${state.timestamp.toIso8601String()}');

    if (state.objects.isEmpty) {
      buffer.writeln('No objects in world state.');
      return buffer.toString();
    }

    final byType = <String, List<WorldObject>>{};
    for (final obj in state.objects.values) {
      byType.putIfAbsent(obj.type, () => []).add(obj);
    }

    if (state.activeProjects.isNotEmpty) {
      buffer.writeln('\nActive Projects:');
      for (final p in state.activeProjects) {
        buffer.writeln('  📁 ${p.name} [${p.status.name}]${p.workspaceId != null ? ' (ws:${p.workspaceId})' : ''}');
        if (p.description != null) buffer.writeln('     ${p.description}');
      }
    }

    if (state.runningAgents.isNotEmpty) {
      buffer.writeln('\nRunning Agents:');
      for (final a in state.runningAgents) {
        final role = a.properties['role'] ?? 'unknown';
        buffer.writeln('  🤖 ${a.name} [${a.status.name}] role=$role');
        if (a.properties['task'] != null) {
          buffer.writeln('     Task: ${a.properties['task']}');
        }
      }
    }

    if (state.blockedObjects.isNotEmpty) {
      buffer.writeln('\n⚠ Blocked:');
      for (final b in state.blockedObjects) {
        buffer.writeln('  ${b.name} (${b.type}): ${b.blockers.join(", ")}');
      }
    }

    if (state.pendingTasks.isNotEmpty) {
      buffer.writeln('\nPending Tasks:');
      for (final t in state.pendingTasks.take(5)) {
        buffer.writeln('  📋 ${t.name} [${t.status.name}]${t.assignedAgentId != null ? ' → ${t.assignedAgentId}' : ''}');
      }
      if (state.pendingTasks.length > 5) {
        buffer.writeln('  ... and ${state.pendingTasks.length - 5} more');
      }
    }

    final otherTypes = byType.keys.where((t) => !{'project', 'agent', 'task', 'plan'}.contains(t));
    if (otherTypes.isNotEmpty) {
      buffer.writeln('\nOther Objects:');
      for (final type in otherTypes) {
        final objs = byType[type]!;
        buffer.writeln('  $type: ${objs.length}');
        for (final obj in objs.take(3)) {
          buffer.writeln('    - ${obj.name} [${obj.status.name}]');
        }
      }
    }

    return buffer.toString();
  }

  WorldObjectStatus _mapAgentLifecycle(AgentLifecycleState lifecycle) {
    switch (lifecycle) {
      case AgentLifecycleState.created:
        return WorldObjectStatus.pending;
      case AgentLifecycleState.running:
        return WorldObjectStatus.running;
      case AgentLifecycleState.paused:
        return WorldObjectStatus.paused;
      case AgentLifecycleState.completed:
        return WorldObjectStatus.completed;
      case AgentLifecycleState.destroyed:
        return WorldObjectStatus.destroyed;
    }
  }

  WorldObjectStatus _mapPlanStatus(PlanStatus status) {
    switch (status) {
      case PlanStatus.draft:
        return WorldObjectStatus.pending;
      case PlanStatus.approved:
        return WorldObjectStatus.active;
      case PlanStatus.executing:
        return WorldObjectStatus.running;
      case PlanStatus.completed:
        return WorldObjectStatus.completed;
      case PlanStatus.cancelled:
        return WorldObjectStatus.failed;
      case PlanStatus.failed:
        return WorldObjectStatus.failed;
    }
  }

  WorldObjectStatus _inferStatus(Map<String, dynamic> state) {
    if (state.containsKey('lifecycle')) {
      final lifecycle = state['lifecycle'] as String?;
      if (lifecycle == 'running') return WorldObjectStatus.running;
      if (lifecycle == 'paused') return WorldObjectStatus.paused;
      if (lifecycle == 'completed') return WorldObjectStatus.completed;
      if (lifecycle == 'destroyed') return WorldObjectStatus.destroyed;
    }
    if (state.containsKey('lastError')) return WorldObjectStatus.failed;
    return WorldObjectStatus.active;
  }

  Future<void> _persist() async {
    try {
      await _db.putCache(
        _worldObjectsKey,
        jsonEncode(_objects.map((k, v) => MapEntry(k, v.toJson()))),
      );
    } catch (e, st) {
      AppLogger.instance.error('WorldStateService persist failed', error: e, stackTrace: st);
    }
  }

  Future<void> clear() async {
    _objects.clear();
    await _persist();
  }
}
