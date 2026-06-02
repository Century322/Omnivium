import 'dart:convert';
import 'app_logger.dart';
import 'database_service.dart';
import 'di/app_di.dart';
import 'workspace_service.dart';
import 'agent_service.dart';
import 'planning_engine.dart';

enum WorkspaceNodeType {
  workspace,
  project,
  task,
  file,
  decision,
  agent,
  milestone,
  timeline,
}

class WorkspaceNode {
  final String id;
  final String name;
  final WorkspaceNodeType type;
  final String? parentId;
  final String workspaceId;
  final Map<String, dynamic> properties;
  final DateTime lastModified;

  const WorkspaceNode({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    required this.workspaceId,
    this.properties = const {},
    required this.lastModified,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    if (parentId != null) 'parentId': parentId,
    'workspaceId': workspaceId,
    'properties': properties,
    'lastModified': lastModified.toIso8601String(),
  };

  factory WorkspaceNode.fromJson(Map<String, dynamic> json) => WorkspaceNode(
    id: json['id'] as String,
    name: json['name'] as String,
    type: WorkspaceNodeType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => WorkspaceNodeType.task,
    ),
    parentId: json['parentId'] as String?,
    workspaceId: json['workspaceId'] as String,
    properties: (json['properties'] as Map<String, dynamic>?) ?? {},
    lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ?? DateTime.now(),
  );
}

class WorkspaceEdge {
  final String sourceId;
  final String targetId;
  final String relation;

  const WorkspaceEdge({
    required this.sourceId,
    required this.targetId,
    required this.relation,
  });

  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'targetId': targetId,
    'relation': relation,
  };

  factory WorkspaceEdge.fromJson(Map<String, dynamic> json) => WorkspaceEdge(
    sourceId: json['sourceId'] as String,
    targetId: json['targetId'] as String,
    relation: json['relation'] as String,
  );
}

class WorkspaceGraph {
  final Map<String, WorkspaceNode> _nodes = {};
  final List<WorkspaceEdge> _edges = [];
  final DatabaseService _db;
  bool _isInitialized = false;

  static const _nodesKey = 'workspace_graph_nodes';
  static const _edgesKey = 'workspace_graph_edges';

  WorkspaceGraph(this._db);

  bool get isInitialized => _isInitialized;
  int get nodeCount => _nodes.length;
  int get edgeCount => _edges.length;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final nodesJson = await _db.getCache(_nodesKey);
      if (nodesJson != null) {
        final map = jsonDecode(nodesJson) as Map<String, dynamic>;
        for (final entry in map.entries) {
          _nodes[entry.key] = WorkspaceNode.fromJson(entry.value as Map<String, dynamic>);
        }
      }
      final edgesJson = await _db.getCache(_edgesKey);
      if (edgesJson != null) {
        final list = jsonDecode(edgesJson) as List<dynamic>;
        for (final e in list) {
          _edges.add(WorkspaceEdge.fromJson(e as Map<String, dynamic>));
        }
      }
      _isInitialized = true;
      AppLogger.instance.info('WorkspaceGraph initialized: ${_nodes.length} nodes, ${_edges.length} edges');
    } catch (e, st) {
      AppLogger.instance.error('WorkspaceGraph init failed', error: e, stackTrace: st);
      _isInitialized = true;
    }
  }

  void addNode(WorkspaceNode node) {
    _nodes[node.id] = node;
  }

  void addEdge(String sourceId, String targetId, String relation) {
    _edges.add(WorkspaceEdge(sourceId: sourceId, targetId: targetId, relation: relation));
  }

  WorkspaceNode? getNode(String id) => _nodes[id];

  List<WorkspaceNode> getChildren(String parentId) => _nodes.values
      .where((n) => n.parentId == parentId)
      .toList();

  List<WorkspaceNode> getWorkspaceNodes(String workspaceId) => _nodes.values
      .where((n) => n.workspaceId == workspaceId)
      .toList();

  List<WorkspaceNode> getNodesByType(WorkspaceNodeType type) => _nodes.values
      .where((n) => n.type == type)
      .toList();

  List<WorkspaceNode> getPathToRoot(String nodeId) {
    final path = <WorkspaceNode>[];
    var current = _nodes[nodeId];
    while (current != null) {
      path.add(current);
      if (current.parentId == null) break;
      current = _nodes[current.parentId];
    }
    return path;
  }

  List<WorkspaceNode> getSubtree(String rootId) {
    final result = <WorkspaceNode>[];
    final root = _nodes[rootId];
    if (root == null) return result;
    result.add(root);
    final children = getChildren(rootId);
    for (final child in children) {
      result.addAll(getSubtree(child.id));
    }
    return result;
  }

  Future<void> buildFromSources() async {
    _nodes.clear();
    _edges.clear();

    try {
      final workspaceService = getIt<WorkspaceService>();
      for (final ws in workspaceService.workspaces) {
        addNode(WorkspaceNode(
          id: ws.id,
          name: ws.name,
          type: WorkspaceNodeType.workspace,
          workspaceId: ws.id,
          properties: {'domain': ws.domain.name},
          lastModified: ws.lastActiveAt,
        ));

        final ctx = workspaceService.buildProjectContext(ws.id);
        for (final entity in ctx.entities.take(20)) {
          addNode(WorkspaceNode(
            id: 'entity_${entity.id}',
            name: entity.name,
            type: WorkspaceNodeType.file,
            parentId: ws.id,
            workspaceId: ws.id,
            properties: {'entityType': entity.type.name, 'state': entity.currentState},
            lastModified: DateTime.now(),
          ));
          addEdge(ws.id, 'entity_${entity.id}', 'contains');
        }

        for (final goal in ctx.goals.take(10)) {
          addNode(WorkspaceNode(
            id: 'goal_${goal.id}',
            name: goal.title,
            type: goal.progress >= 100 ? WorkspaceNodeType.milestone : WorkspaceNodeType.task,
            parentId: ws.id,
            workspaceId: ws.id,
            properties: {'progress': goal.progress, 'status': goal.status.name},
            lastModified: DateTime.now(),
          ));
          addEdge(ws.id, 'goal_${goal.id}', 'hasGoal');
        }

        for (final entry in ctx.timeline.take(10)) {
          addNode(WorkspaceNode(
            id: 'tl_${entry.timestamp.millisecondsSinceEpoch}',
            name: entry.description,
            type: WorkspaceNodeType.timeline,
            parentId: ws.id,
            workspaceId: ws.id,
            properties: {'type': entry.type, 'data': entry.data},
            lastModified: entry.timestamp,
          ));
          addEdge(ws.id, 'tl_${entry.timestamp.millisecondsSinceEpoch}', 'timeline');
        }
      }
    } catch (_) {}

    try {
      final agentService = getIt<AgentService>();
      for (final agent in agentService.agents) {
        if (!agent.isAlive) continue;
        final wsId = agent.projectId ?? agent.groupId ?? '';
        if (wsId.isEmpty) continue;
        addNode(WorkspaceNode(
          id: 'agent_${agent.id}',
          name: agent.name,
          type: WorkspaceNodeType.agent,
          parentId: wsId,
          workspaceId: wsId,
          properties: {'role': agent.role.name, 'capabilities': agent.capabilities},
          lastModified: agent.lastActiveAt,
        ));
        addEdge(wsId, 'agent_${agent.id}', 'assignedTo');
      }
    } catch (_) {}

    try {
      final planningEngine = getIt<PlanningEngine>();
      for (final plan in planningEngine.plans) {
        if (plan.status == PlanStatus.completed || plan.status == PlanStatus.cancelled) continue;
        final wsId = plan.steps.isNotEmpty
            ? (plan.steps.first.params['workspaceId'] as String?) ?? ''
            : '';
        if (wsId.isEmpty) continue;
        addNode(WorkspaceNode(
          id: 'plan_${plan.id}',
          name: plan.title,
          type: WorkspaceNodeType.decision,
          parentId: wsId,
          workspaceId: wsId,
          properties: {'progress': plan.progress, 'stepCount': plan.steps.length},
          lastModified: DateTime.now(),
        ));
        addEdge(wsId, 'plan_${plan.id}', 'hasPlan');
      }
    } catch (_) {}

    await _persist();
  }

  String buildWorkspaceGraphContext({String? workspaceId}) {
    final buffer = StringBuffer();
    buffer.writeln('[Workspace Graph]');

    final workspaces = workspaceId != null
        ? _nodes.values.where((n) => n.id == workspaceId && n.type == WorkspaceNodeType.workspace).toList()
        : getNodesByType(WorkspaceNodeType.workspace);

    if (workspaces.isEmpty) {
      buffer.writeln('No workspaces in graph.');
      return buffer.toString();
    }

    for (final ws in workspaces) {
      buffer.writeln('\n📁 ${ws.name} [${ws.properties['domain'] ?? ''}]');

      final children = getChildren(ws.id);
      final byType = <WorkspaceNodeType, List<WorkspaceNode>>{};
      for (final child in children) {
        byType.putIfAbsent(child.type, () => []).add(child);
      }

      if (byType.containsKey(WorkspaceNodeType.task)) {
        final tasks = byType[WorkspaceNodeType.task]!;
        buffer.writeln('  Tasks (${tasks.length}):');
        for (final task in tasks.take(8)) {
          final progress = task.properties['progress'];
          final status = task.properties['status'];
          buffer.writeln('    📋 ${task.name}${progress != null ? ' [$progress%]' : ''}${status != null ? ' ($status)' : ''}');
        }
      }

      if (byType.containsKey(WorkspaceNodeType.milestone)) {
        final milestones = byType[WorkspaceNodeType.milestone]!;
        buffer.writeln('  Milestones (${milestones.length}):');
        for (final m in milestones.take(5)) {
          buffer.writeln('    🏆 ${m.name}');
        }
      }

      if (byType.containsKey(WorkspaceNodeType.agent)) {
        final agents = byType[WorkspaceNodeType.agent]!;
        buffer.writeln('  Agents (${agents.length}):');
        for (final agent in agents) {
          final role = agent.properties['role'];
          buffer.writeln('    🤖 ${agent.name} ($role)');
        }
      }

      if (byType.containsKey(WorkspaceNodeType.decision)) {
        final decisions = byType[WorkspaceNodeType.decision]!;
        buffer.writeln('  Plans (${decisions.length}):');
        for (final d in decisions) {
          final progress = d.properties['progress'];
          buffer.writeln('    📝 ${d.name}${progress != null ? ' [$progress%]' : ''}');
        }
      }

      if (byType.containsKey(WorkspaceNodeType.file)) {
        final files = byType[WorkspaceNodeType.file]!;
        buffer.writeln('  Entities (${files.length}):');
        for (final f in files.take(5)) {
          buffer.writeln('    📄 ${f.name} (${f.properties['entityType'] ?? ''})');
        }
        if (files.length > 5) buffer.writeln('    ... and ${files.length - 5} more');
      }
    }

    return buffer.toString();
  }

  String buildRecoveryContext(String workspaceName) {
    final ws = _nodes.values.firstWhere(
      (n) => n.type == WorkspaceNodeType.workspace && n.name.toLowerCase().contains(workspaceName.toLowerCase()),
      orElse: () => WorkspaceNode(id: '', name: '', type: WorkspaceNodeType.workspace, workspaceId: '', lastModified: DateTime.now()),
    );

    if (ws.id.isEmpty) return 'No workspace found matching: $workspaceName';

    final buffer = StringBuffer();
    buffer.writeln('[Recovery: ${ws.name}]');

    final subtree = getSubtree(ws.id);
    final tasks = subtree.where((n) => n.type == WorkspaceNodeType.task).toList();
    final agents = subtree.where((n) => n.type == WorkspaceNodeType.agent).toList();
    final decisions = subtree.where((n) => n.type == WorkspaceNodeType.decision).toList();
    final milestones = subtree.where((n) => n.type == WorkspaceNodeType.milestone).toList();

    buffer.writeln('Total nodes: ${subtree.length}');
    if (tasks.isNotEmpty) buffer.writeln('Active tasks: ${tasks.length}');
    if (agents.isNotEmpty) buffer.writeln('Assigned agents: ${agents.length}');
    if (decisions.isNotEmpty) buffer.writeln('Active plans: ${decisions.length}');
    if (milestones.isNotEmpty) buffer.writeln('Milestones: ${milestones.length}');

    final recentTimeline = subtree
        .where((n) => n.type == WorkspaceNodeType.timeline)
        .toList()
      ..sort((a, b) => b.lastModified.compareTo(a.lastModified));

    if (recentTimeline.isNotEmpty) {
      buffer.writeln('\nRecent activity:');
      for (final entry in recentTimeline.take(5)) {
        buffer.writeln('  ${entry.name}');
      }
    }

    return buffer.toString();
  }

  Future<void> _persist() async {
    try {
      await _db.putCache(
        _nodesKey,
        jsonEncode(_nodes.map((k, v) => MapEntry(k, v.toJson()))),
      );
      await _db.putCache(
        _edgesKey,
        jsonEncode(_edges.map((e) => e.toJson()).toList()),
      );
    } catch (e, st) {
      AppLogger.instance.error('WorkspaceGraph persist failed', error: e, stackTrace: st);
    }
  }

  Future<void> clear() async {
    _nodes.clear();
    _edges.clear();
    await _persist();
  }
}
