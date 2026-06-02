import 'dart:convert';
import 'database_service.dart';
import 'agent/cognitive/multi_agent_society.dart';
import 'omni_model.dart';
import 'omni_objects.dart';
import 'event_store.dart';
import 'di/app_di.dart';
import 'app_logger.dart';

enum AgentLifecycleState {
  created,
  running,
  paused,
  completed,
  destroyed,
}

class AgentInstance {
  final String id;
  final String name;
  final AgentRole role;
  final List<String> capabilities;
  final String? groupId;
  final String? projectId;
  final AgentLifecycleState lifecycle;
  final DateTime createdAt;
  DateTime lastActiveAt;
  Map<String, dynamic> metadata;

  AgentInstance({
    required this.id,
    required this.name,
    this.role = AgentRole.executor,
    this.capabilities = const [],
    this.groupId,
    this.projectId,
    this.lifecycle = AgentLifecycleState.created,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    this.metadata = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now();

  AgentInstance copyWith({
    AgentLifecycleState? lifecycle,
    DateTime? lastActiveAt,
    Map<String, dynamic>? metadata,
    String? groupId,
    String? projectId,
  }) =>
      AgentInstance(
        id: id,
        name: name,
        role: role,
        capabilities: capabilities,
        groupId: groupId ?? this.groupId,
        projectId: projectId ?? this.projectId,
        lifecycle: lifecycle ?? this.lifecycle,
        createdAt: createdAt,
        lastActiveAt: lastActiveAt ?? DateTime.now(),
        metadata: metadata ?? this.metadata,
      );

  bool get isAlive => lifecycle == AgentLifecycleState.created ||
      lifecycle == AgentLifecycleState.running ||
      lifecycle == AgentLifecycleState.paused;

  OmniObject toOmniObject() => AgentObject(
        agentId: id,
        name: name,
        role: role.name,
        status: lifecycle.name,
        capabilities: capabilities,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'capabilities': capabilities,
        'groupId': groupId,
        'projectId': projectId,
        'lifecycle': lifecycle.name,
        'createdAt': createdAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
        'metadata': metadata,
      };

  factory AgentInstance.fromJson(Map<String, dynamic> json) => AgentInstance(
        id: json['id'] as String,
        name: json['name'] as String,
        role: AgentRole.values.byName((json['role'] as String?) ?? 'executor'),
        capabilities: (json['capabilities'] as List<dynamic>?)?.cast<String>() ?? [],
        groupId: json['groupId'] as String?,
        projectId: json['projectId'] as String?,
        lifecycle: AgentLifecycleState.values.byName(
            (json['lifecycle'] as String?) ?? 'created'),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.parse(json['lastActiveAt'] as String)
            : null,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );
}

class AgentGroup {
  final String id;
  final String name;
  final String? projectId;
  final List<String> agentIds;
  final DateTime createdAt;
  DateTime lastActiveAt;
  AgentLifecycleState lifecycle;

  AgentGroup({
    required this.id,
    required this.name,
    this.projectId,
    this.agentIds = const [],
    this.lifecycle = AgentLifecycleState.created,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now();

  OmniObject toOmniObject() => ChatRoomObject(
        roomId: id,
        name: name,
        isGroup: true,
        memberIds: agentIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'projectId': projectId,
        'agentIds': agentIds,
        'lifecycle': lifecycle.name,
        'createdAt': createdAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
      };

  factory AgentGroup.fromJson(Map<String, dynamic> json) => AgentGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        projectId: json['projectId'] as String?,
        agentIds: (json['agentIds'] as List<dynamic>?)?.cast<String>() ?? [],
        lifecycle: AgentLifecycleState.values.byName(
            (json['lifecycle'] as String?) ?? 'created'),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.parse(json['lastActiveAt'] as String)
            : null,
      );
}

class AgentService {
  static const _agentsKey = 'agent_instances';
  static const _groupsKey = 'agent_groups';

  final DatabaseService _db;
  List<AgentInstance> _agents = [];
  List<AgentGroup> _groups = [];
  bool _initialized = false;

  AgentService(this._db);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final agentsJson = await _db.getCache(_agentsKey);
      if (agentsJson != null) {
        final list = jsonDecode(agentsJson) as List<dynamic>;
        _agents = list
            .map((e) => AgentInstance.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final groupsJson = await _db.getCache(_groupsKey);
      if (groupsJson != null) {
        final list = jsonDecode(groupsJson) as List<dynamic>;
        _groups = list
            .map((e) => AgentGroup.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('AgentService init failed',
          error: e, stackTrace: st);
    }
  }

  bool get isInitialized => _initialized;

  Future<void> _persist() async {
    try {
      await _db.putCache(
          _agentsKey, jsonEncode(_agents.map((a) => a.toJson()).toList()));
      await _db.putCache(
          _groupsKey, jsonEncode(_groups.map((g) => g.toJson()).toList()));
    } catch (e, st) {
      AppLogger.instance.error('AgentService persist failed',
          error: e, stackTrace: st);
    }
  }

  List<AgentInstance> get agents => List.unmodifiable(_agents);
  List<AgentGroup> get groups => List.unmodifiable(_groups);

  List<AgentInstance> getAliveAgents() =>
      _agents.where((a) => a.isAlive).toList();

  AgentInstance? getAgent(String id) {
    final idx = _agents.indexWhere((a) => a.id == id);
    return idx >= 0 ? _agents[idx] : null;
  }

  AgentGroup? getGroup(String id) {
    final idx = _groups.indexWhere((g) => g.id == id);
    return idx >= 0 ? _groups[idx] : null;
  }

  List<AgentInstance> getAgentsByGroup(String groupId) =>
      _agents.where((a) => a.groupId == groupId).toList();

  List<AgentInstance> getAgentsByProject(String projectId) =>
      _agents.where((a) => a.projectId == projectId).toList();

  List<AgentInstance> findAgentsByCapability(String capability) =>
      _agents
          .where((a) =>
              a.isAlive && a.capabilities.contains(capability))
          .toList();

  Future<AgentInstance> createAgent({
    required String name,
    AgentRole role = AgentRole.executor,
    List<String> capabilities = const [],
    String? groupId,
    String? projectId,
    Map<String, dynamic>? metadata,
  }) async {
    final agent = AgentInstance(
      id: 'agent_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.abs()}',
      name: name,
      role: role,
      capabilities: capabilities,
      groupId: groupId,
      projectId: projectId,
      lifecycle: AgentLifecycleState.created,
      metadata: metadata ?? {},
    );
    _agents.add(agent);

    if (groupId != null) {
      final groupIdx = _groups.indexWhere((g) => g.id == groupId);
      if (groupIdx >= 0) {
        final group = _groups[groupIdx];
        _groups[groupIdx] = AgentGroup(
          id: group.id,
          name: group.name,
          projectId: group.projectId,
          agentIds: [...group.agentIds, agent.id],
          lifecycle: group.lifecycle,
          createdAt: group.createdAt,
          lastActiveAt: DateTime.now(),
        );
      }
    }

    OmniObjectRegistry.instance.registerObject(agent.toOmniObject());
    await _persist();
    _recordEvent(DomainEventType.agentCreated, agent.id, 'agent', {
      'name': name,
      'role': role.name,
      'capabilities': capabilities,
    });
    AppLogger.instance.info('Agent created: ${agent.name} (${agent.id})');
    return agent;
  }

  Future<AgentGroup> createGroup({
    required String name,
    String? projectId,
  }) async {
    final group = AgentGroup(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.abs()}',
      name: name,
      projectId: projectId,
    );
    _groups.add(group);
    OmniObjectRegistry.instance.registerObject(group.toOmniObject());
    await _persist();
    AppLogger.instance.info('Agent group created: ${group.name} (${group.id})');
    return group;
  }

  Future<void> startAgent(String agentId) async {
    final idx = _agents.indexWhere((a) => a.id == agentId);
    if (idx < 0) return;
    _agents[idx] = _agents[idx].copyWith(
      lifecycle: AgentLifecycleState.running,
      lastActiveAt: DateTime.now(),
    );
    OmniObjectRegistry.instance.registerObject(_agents[idx].toOmniObject());
    await _persist();
  }

  Future<void> pauseAgent(String agentId) async {
    final idx = _agents.indexWhere((a) => a.id == agentId);
    if (idx < 0) return;
    _agents[idx] = _agents[idx].copyWith(
      lifecycle: AgentLifecycleState.paused,
    );
    OmniObjectRegistry.instance.registerObject(_agents[idx].toOmniObject());
    await _persist();
  }

  Future<void> resumeAgent(String agentId) async {
    final idx = _agents.indexWhere((a) => a.id == agentId);
    if (idx < 0) return;
    _agents[idx] = _agents[idx].copyWith(
      lifecycle: AgentLifecycleState.idle,
    );
    OmniObjectRegistry.instance.registerObject(_agents[idx].toOmniObject());
    await _persist();
  }

  Future<void> completeAgent(String agentId) async {
    final idx = _agents.indexWhere((a) => a.id == agentId);
    if (idx < 0) return;
    _agents[idx] = _agents[idx].copyWith(
      lifecycle: AgentLifecycleState.completed,
    );
    OmniObjectRegistry.instance.registerObject(_agents[idx].toOmniObject());
    await _persist();
  }

  Future<void> destroyAgent(String agentId) async {
    final idx = _agents.indexWhere((a) => a.id == agentId);
    if (idx < 0) return;
    _agents[idx] = _agents[idx].copyWith(
      lifecycle: AgentLifecycleState.destroyed,
    );
    OmniObjectRegistry.instance.unregisterObject(agentId);

    for (var i = 0; i < _groups.length; i++) {
      final group = _groups[i];
      if (group.agentIds.contains(agentId)) {
        _groups[i] = AgentGroup(
          id: group.id,
          name: group.name,
          projectId: group.projectId,
          agentIds: group.agentIds.where((id) => id != agentId).toList(),
          lifecycle: group.lifecycle,
          createdAt: group.createdAt,
          lastActiveAt: DateTime.now(),
        );
      }
    }

    await _persist();
    _recordEvent(DomainEventType.agentDestroyed, agentId, 'agent', {});
    AppLogger.instance.info('Agent destroyed: $agentId');
  }

  Future<void> destroyGroup(String groupId, {bool destroyAgents = true}) async {
    final group = getGroup(groupId);
    if (group == null) return;

    if (destroyAgents) {
      for (final agentId in group.agentIds) {
        await destroyAgent(agentId);
      }
    }

    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx >= 0) {
      _groups.removeAt(idx);
    }
    OmniObjectRegistry.instance.unregisterObject(groupId);
    await _persist();
    AppLogger.instance.info('Agent group destroyed: $groupId (agents: ${destroyAgents ? "destroyed" : "preserved"})');
  }

  Future<List<AgentInstance>> createTeamForTask({
    required String taskDescription,
    required String groupName,
    String? projectId,
  }) async {
    final group = await createGroup(name: groupName, projectId: projectId);

    final coordinator = await createAgent(
      name: '${groupName} Coordinator',
      role: AgentRole.coordinator,
      capabilities: ['planning', 'coordination', 'review'],
      groupId: group.id,
      projectId: projectId,
    );

    final executor = await createAgent(
      name: '${groupName} Executor',
      role: AgentRole.executor,
      capabilities: ['execution', 'implementation', 'testing'],
      groupId: group.id,
      projectId: projectId,
    );

    await startAgent(coordinator.id);
    await startAgent(executor.id);

    return [coordinator, executor];
  }

  String buildAgentContext() {
    final alive = getAliveAgents();
    if (alive.isEmpty && _groups.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Active Agents]');

    if (alive.isNotEmpty) {
      for (final agent in alive) {
        buffer.writeln(
            '  - ${agent.name} (${agent.role.name}, ${agent.lifecycle.name}, caps: ${agent.capabilities.join(",")})');
      }
    }

    if (_groups.isNotEmpty) {
      buffer.writeln('[Agent Groups]');
      for (final group in _groups) {
        final aliveInGroup =
            group.agentIds.where((id) => getAgent(id)?.isAlive ?? false).length;
        buffer.writeln(
            '  - ${group.name} (${aliveInGroup} agents, ${group.lifecycle.name})');
      }
    }

    return buffer.toString();
  }

  Future<AgentInstance> spawnChildAgent({
    required String parentAgentId,
    required String name,
    AgentRole role = AgentRole.executor,
    List<String> capabilities = const [],
    String? projectId,
    Map<String, dynamic>? metadata,
  }) async {
    final parent = getAgent(parentAgentId);
    final groupId = parent?.groupId;

    final child = await createAgent(
      name: name,
      role: role,
      capabilities: capabilities,
      groupId: groupId,
      projectId: projectId ?? parent?.projectId,
      metadata: {
        'parentAgentId': parentAgentId,
        ...?metadata,
      },
    );

    await startAgent(child.id);

    AppLogger.instance.info(
      'Agent $parentAgentId spawned child: ${child.name} (${child.id})',
    );
    return child;
  }

  Future<AgentGroup> createTeam({
    required String name,
    required String coordinatorName,
    List<String> specialistRoles = const [],
    String? projectId,
  }) async {
    final group = await createGroup(name: name, projectId: projectId);

    final coordinator = await createAgent(
      name: coordinatorName,
      role: AgentRole.coordinator,
      capabilities: ['planning', 'coordination', 'review', 'delegation'],
      groupId: group.id,
      projectId: projectId,
      metadata: {'isTeamLead': true},
    );

    await startAgent(coordinator.id);

    for (final roleSpec in specialistRoles) {
      final parts = roleSpec.split(':');
      final agentName = parts.length > 1 ? parts[0] : roleSpec;
      final caps = parts.length > 1
          ? parts[1].split(',').map((s) => s.trim()).toList()
          : [roleSpec.toLowerCase()];

      final specialist = await createAgent(
        name: '$name $agentName',
        role: AgentRole.specialist,
        capabilities: caps,
        groupId: group.id,
        projectId: projectId,
      );
      await startAgent(specialist.id);
    }

    AppLogger.instance.info(
      'Team created: $name with ${1 + specialistRoles.length} agents',
    );
    return group;
  }

  Future<void> assignTaskToAgent(String agentId, String task) async {
    final idx = _agents.indexWhere((a) => a.id == agentId);
    if (idx < 0) return;
    _agents[idx] = _agents[idx].copyWith(
      metadata: {
        ..._agents[idx].metadata,
        'currentTask': task,
        'taskAssignedAt': DateTime.now().toIso8601String(),
      },
    );
    OmniObjectRegistry.instance.registerObject(_agents[idx].toOmniObject());
    await _persist();
  }

  Future<void> completeTask(String agentId) async {
    final idx = _agents.indexWhere((a) => a.id == agentId);
    if (idx < 0) return;
    _agents[idx] = _agents[idx].copyWith(
      metadata: {
        ..._agents[idx].metadata,
        'lastCompletedTask': _agents[idx].metadata['currentTask'],
        'taskCompletedAt': DateTime.now().toIso8601String(),
      }..remove('currentTask'),
    );
    OmniObjectRegistry.instance.registerObject(_agents[idx].toOmniObject());
    await _persist();
  }

  Future<void> dissolveGroup(String groupId) async {
    final group = getGroup(groupId);
    if (group == null) return;

    for (final agentId in group.agentIds) {
      await completeAgent(agentId);
    }

    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx >= 0) {
      _groups[idx] = AgentGroup(
        id: group.id,
        name: group.name,
        projectId: group.projectId,
        agentIds: group.agentIds,
        lifecycle: AgentLifecycleState.destroyed,
        createdAt: group.createdAt,
        lastActiveAt: DateTime.now(),
      );
    }
    OmniObjectRegistry.instance.unregisterObject(groupId);
    await _persist();

    AppLogger.instance.info(
      'Group dissolved: $groupId (${group.agentIds.length} agents completed)',
    );
  }

  Future<void> autoCleanup() async {
    final now = DateTime.now();
    final staleThreshold = const Duration(hours: 24);

    for (final group in List.of(_groups)) {
      if (group.lifecycle == AgentLifecycleState.destroyed) continue;

      final agents = getAgentsByGroup(group.id);
      final allCompleted = agents.every((a) =>
          a.lifecycle == AgentLifecycleState.completed ||
          a.lifecycle == AgentLifecycleState.destroyed);

      if (allCompleted && agents.isNotEmpty) {
        await dissolveGroup(group.id);
        continue;
      }

      final hasStaleAgents = agents.any((a) =>
          a.lifecycle == AgentLifecycleState.running &&
          now.difference(a.lastActiveAt) > staleThreshold);

      if (hasStaleAgents) {
        for (final agent in agents) {
          if (agent.lifecycle == AgentLifecycleState.running &&
              now.difference(agent.lastActiveAt) > staleThreshold) {
            await completeAgent(agent.id);
          }
        }
      }
    }

    for (final agent in List.of(_agents)) {
      if (agent.lifecycle == AgentLifecycleState.running &&
          agent.groupId == null &&
          now.difference(agent.lastActiveAt) > staleThreshold) {
        await completeAgent(agent.id);
      }
    }
  }

  String buildSocietyContext() {
    final alive = getAliveAgents();
    final activeGroups = _groups.where((g) =>
        g.lifecycle != AgentLifecycleState.destroyed).toList();

    final buffer = StringBuffer();
    buffer.writeln('[Agent Society]');

    if (activeGroups.isNotEmpty) {
      buffer.writeln('\nTeams:');
      for (final group in activeGroups) {
        final agents = getAgentsByGroup(group.id);
        final running = agents.where((a) => a.isAlive).length;
        buffer.writeln('  ${group.name} [$running alive/${agents.length} total]');
        for (final agent in agents) {
          final task = agent.metadata['currentTask'];
          final taskStr = task != null ? ' → $task' : '';
          buffer.writeln('    ${agent.role.name}: ${agent.name} [${agent.lifecycle.name}]$taskStr');
        }
      }
    }

    final soloAgents = alive.where((a) => a.groupId == null).toList();
    if (soloAgents.isNotEmpty) {
      buffer.writeln('\nSolo Agents:');
      for (final agent in soloAgents) {
        buffer.writeln('  ${agent.name} (${agent.role.name}) caps: ${agent.capabilities.join(", ")}');
      }
    }

    buffer.writeln('\nCommands: CreateTeam, SpawnAgent, AssignTask, DissolveGroup');

    return buffer.toString();
  }

  void _recordEvent(DomainEventType type, String aggregateId, String aggregateType, Map<String, dynamic> payload) {
    try {
      final eventStore = getIt<EventStore>();
      if (eventStore.isInitialized) {
        final event = eventStore.createEvent(
          type: type,
          aggregateId: aggregateId,
          aggregateType: aggregateType,
          payload: payload,
        );
        eventStore.append(event);
      }
    } catch (_) {}
  }
}
