import 'dart:convert';
import 'database_service.dart';
import 'agent/cognitive/workspace.dart';
import 'agent/cognitive/entity_store.dart';
import 'agent/cognitive/entity_layer.dart';
import 'agent/cognitive/goal_store.dart';
import 'agent/cognitive/goal_runtime.dart';
import 'agent/cognitive/cognitive_types.dart';
import 'app_logger.dart';

class WorkspaceService {
  static const _workspacesKey = 'cognitive_workspaces';
  static const _subspacesKey = 'cognitive_subspaces';
  static const _topicsKey = 'cognitive_topics';
  static const _activeWorkspaceKey = 'active_workspace_id';

  final DatabaseService _db;
  final EntityStore _entityStore;
  final GoalStore _goalStore;

  List<MemoryWorkspace> _workspaces = [];
  List<MemorySubspace> _subspaces = [];
  List<MemoryTopic> _topics = [];
  String? _activeWorkspaceId;
  bool _initialized = false;

  WorkspaceService(this._db, this._entityStore, this._goalStore);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final wsJson = await _db.getCache(_workspacesKey);
      if (wsJson != null) {
        final list = jsonDecode(wsJson) as List<dynamic>;
        _workspaces = list.map((e) => MemoryWorkspace.fromJson(e as Map<String, dynamic>)).toList();
      }
      final ssJson = await _db.getCache(_subspacesKey);
      if (ssJson != null) {
        final list = jsonDecode(ssJson) as List<dynamic>;
        _subspaces = list.map((e) => MemorySubspace.fromJson(e as Map<String, dynamic>)).toList();
      }
      final tpJson = await _db.getCache(_topicsKey);
      if (tpJson != null) {
        final list = jsonDecode(tpJson) as List<dynamic>;
        _topics = list.map((e) => MemoryTopic.fromJson(e as Map<String, dynamic>)).toList();
      }
      _activeWorkspaceId = await _db.getCache(_activeWorkspaceKey);
      if (_workspaces.isEmpty) {
        await _createDefaultWorkspace();
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('WorkspaceService init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _createDefaultWorkspace() async {
    final defaultWs = MemoryWorkspace(
      id: 'ws_default',
      name: 'Default',
      domain: MemoryDomain.project,
      lastActiveAt: DateTime.now(),
    );
    _workspaces.add(defaultWs);
    _activeWorkspaceId = defaultWs.id;
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _db.putCache(_workspacesKey, jsonEncode(_workspaces.map((e) => e.toJson()).toList()));
      await _db.putCache(_subspacesKey, jsonEncode(_subspaces.map((e) => e.toJson()).toList()));
      await _db.putCache(_topicsKey, jsonEncode(_topics.map((e) => e.toJson()).toList()));
      if (_activeWorkspaceId != null) {
        await _db.putCache(_activeWorkspaceKey, _activeWorkspaceId!);
      }
    } catch (e, st) {
      AppLogger.instance.error('WorkspaceService persist failed', error: e, stackTrace: st);
    }
  }

  List<MemoryWorkspace> get workspaces => List.unmodifiable(_workspaces);
  String? get activeWorkspaceId => _activeWorkspaceId;
  bool get isInitialized => _initialized;

  MemoryWorkspace? getWorkspace(String id) {
    final idx = _workspaces.indexWhere((w) => w.id == id);
    return idx >= 0 ? _workspaces[idx] : null;
  }

  MemoryWorkspace? getActiveWorkspace() {
    if (_activeWorkspaceId == null) return null;
    return getWorkspace(_activeWorkspaceId!);
  }

  MemoryWorkspace? findWorkspaceByName(String name) {
    final lower = name.toLowerCase();
    for (final ws in _workspaces) {
      if (ws.name.toLowerCase() == lower) return ws;
    }
    return null;
  }

  List<MemoryWorkspace> findWorkspacesByDomain(MemoryDomain domain) =>
      _workspaces.where((w) => w.domain == domain).toList();

  Future<MemoryWorkspace> createWorkspace({
    required String name,
    MemoryDomain domain = MemoryDomain.project,
  }) async {
    final existing = findWorkspaceByName(name);
    if (existing != null) return existing;

    final ws = MemoryWorkspace(
      id: 'ws_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.abs()}',
      name: name,
      domain: domain,
      lastActiveAt: DateTime.now(),
    );
    _workspaces.add(ws);
    await _persist();
    return ws;
  }

  Future<void> setActiveWorkspace(String workspaceId) async {
    final ws = getWorkspace(workspaceId);
    if (ws == null) return;
    _activeWorkspaceId = workspaceId;
    final idx = _workspaces.indexWhere((w) => w.id == workspaceId);
    if (idx >= 0) {
      _workspaces[idx] = ws.copyWith(lastActiveAt: DateTime.now());
    }
    await _persist();
  }

  Future<MemoryWorkspace> findOrCreateForEntity(String entityName, {MemoryDomain? domain}) async {
    final entity = _entityStore.getEntityByName(entityName);
    if (entity != null && entity.workspaceId != null) {
      final ws = getWorkspace(entity.workspaceId!);
      if (ws != null) return ws;
    }

    final wsName = entityName;
    var ws = findWorkspaceByName(wsName);
    if (ws != null) return ws;

    return createWorkspace(
      name: wsName,
      domain: domain ?? MemoryDomain.project,
    );
  }

  Future<MemorySubspace> createSubspace({
    required String workspaceId,
    required String name,
  }) async {
    final existing = _subspaces.where((s) => s.workspaceId == workspaceId && s.name.toLowerCase() == name.toLowerCase());
    if (existing.isNotEmpty) return existing.first;

    final ss = MemorySubspace(
      id: 'ss_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.abs()}',
      workspaceId: workspaceId,
      name: name,
      lastActiveAt: DateTime.now(),
    );
    _subspaces.add(ss);
    await _persist();
    return ss;
  }

  Future<MemoryTopic> createTopic({
    required String subspaceId,
    required String name,
  }) async {
    final existing = _topics.where((t) => t.subspaceId == subspaceId && t.name.toLowerCase() == name.toLowerCase());
    if (existing.isNotEmpty) return existing.first;

    final topic = MemoryTopic(
      id: 'tp_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.abs()}',
      subspaceId: subspaceId,
      name: name,
      lastActiveAt: DateTime.now(),
    );
    _topics.add(topic);
    await _persist();
    return topic;
  }

  List<MemorySubspace> getSubspaces(String workspaceId) =>
      _subspaces.where((s) => s.workspaceId == workspaceId).toList();

  List<MemoryTopic> getTopics(String subspaceId) =>
      _topics.where((t) => t.subspaceId == subspaceId).toList();

  ProjectContext buildProjectContext(String workspaceId) {
    final ws = getWorkspace(workspaceId);
    if (ws == null) return ProjectContext.empty();

    final entities = _entityStore.getEntitiesByWorkspace(workspaceId);
    final goals = _goalStore.getActiveGoals(workspaceId: workspaceId);
    final subspaces = getSubspaces(workspaceId);

    final timeline = <ProjectTimelineEntry>[];
    for (final entity in entities) {
      timeline.add(ProjectTimelineEntry(
        timestamp: entity.lastAccessedAt,
        type: 'entity_access',
        description: '${entity.type.name}: ${entity.name}',
        data: {'entityId': entity.id, 'entityName': entity.name, 'entityType': entity.type.name},
      ));
    }
    for (final goal in goals) {
      timeline.add(ProjectTimelineEntry(
        timestamp: goal.createdAt,
        type: 'goal_created',
        description: 'Goal: ${goal.title} (${goal.progress}%)',
        data: {'goalId': goal.id, 'goalTitle': goal.title, 'progress': goal.progress},
      ));
    }
    timeline.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ProjectContext(
      workspace: ws,
      entities: entities,
      goals: goals,
      subspaces: subspaces,
      timeline: timeline,
    );
  }

  String buildProjectContextPrompt(String workspaceId) {
    final ctx = buildProjectContext(workspaceId);
    if (ctx.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Project: ${ctx.workspace.name}]');
    buffer.writeln('Domain: ${ctx.workspace.domain.name}');
    buffer.writeln('Last active: ${ctx.workspace.lastActiveAt.toIso8601String()}');

    if (ctx.entities.isNotEmpty) {
      buffer.writeln('\nRelated entities:');
      for (final e in ctx.entities.take(10)) {
        buffer.writeln('  - ${e.name} (${e.type.name}) [${e.currentState}]');
      }
    }

    if (ctx.goals.isNotEmpty) {
      buffer.writeln('\nProject goals:');
      for (final g in ctx.goals.take(5)) {
        buffer.writeln('  - ${g.title} (${g.progress}%, ${g.status.name})');
      }
    }

    if (ctx.timeline.isNotEmpty) {
      buffer.writeln('\nRecent activity:');
      for (final t in ctx.timeline.take(8)) {
        final time = t.timestamp.toIso8601String().substring(0, 16);
        buffer.writeln('  - [$time] ${t.description}');
      }
    }

    return buffer.toString();
  }

  Future<MemoryWorkspace?> resolveWorkspace(String? workspaceId, String? topic) async {
    if (workspaceId != null) {
      final ws = getWorkspace(workspaceId);
      if (ws != null) {
        await setActiveWorkspace(ws.id);
        return ws;
      }
    }

    if (topic != null) {
      final ws = findWorkspaceByName(topic);
      if (ws != null) {
        await setActiveWorkspace(ws.id);
        return ws;
      }

      final entity = _entityStore.getEntityByName(topic);
      if (entity != null && entity.workspaceId != null) {
        final ws = getWorkspace(entity.workspaceId!);
        if (ws != null) {
          await setActiveWorkspace(ws.id);
          return ws;
        }
      }

      return await findOrCreateForEntity(topic);
    }

    return getActiveWorkspace();
  }
}

class ProjectTimelineEntry {
  final DateTime timestamp;
  final String type;
  final String description;
  final Map<String, dynamic> data;

  const ProjectTimelineEntry({
    required this.timestamp,
    required this.type,
    required this.description,
    this.data = const {},
  });
}

class ProjectContext {
  final MemoryWorkspace workspace;
  final List<MemoryEntity> entities;
  final List<GoalNode> goals;
  final List<MemorySubspace> subspaces;
  final List<ProjectTimelineEntry> timeline;

  const ProjectContext({
    required this.workspace,
    required this.entities,
    required this.goals,
    required this.subspaces,
    required this.timeline,
  });

  factory ProjectContext.empty() => ProjectContext(
    workspace: MemoryWorkspace(
      id: '_empty',
      name: 'No Project',
      lastActiveAt: DateTime.now(),
    ),
    entities: const [],
    goals: const [],
    subspaces: const [],
    timeline: const [],
  );

  bool get isEmpty => workspace.id == '_empty';
}
