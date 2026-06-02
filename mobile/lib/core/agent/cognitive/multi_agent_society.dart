import 'dart:async';
import 'dart:convert';
import '../../app_logger.dart';
import '../../database_service.dart';
import 'cognitive_types.dart';

enum AgentRole {
  coordinator,
  specialist,
  observer,
  executor,
}

enum MessagePriority {
  low,
  normal,
  high,
  urgent,
}

class AgentProfile {
  final String agentId;
  final String name;
  final AgentRole role;
  final List<String> capabilities;
  final DateTime registeredAt;
  DateTime lastActiveAt;
  bool isOnline;

  AgentProfile({
    required this.agentId,
    required this.name,
    this.role = AgentRole.specialist,
    this.capabilities = const [],
    DateTime? registeredAt,
    DateTime? lastActiveAt,
    this.isOnline = true,
  })  : registeredAt = registeredAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'agentId': agentId,
    'name': name,
    'role': role.name,
    'capabilities': capabilities,
    'registeredAt': registeredAt.toIso8601String(),
    'lastActiveAt': lastActiveAt.toIso8601String(),
    'isOnline': isOnline,
  };

  factory AgentProfile.fromJson(Map<String, dynamic> json) => AgentProfile(
    agentId: json['agentId'] as String,
    name: json['name'] as String,
    role: AgentRole.values.byName((json['role'] as String?) ?? 'specialist'),
    capabilities: (json['capabilities'] as List<dynamic>?)?.cast<String>() ?? [],
    registeredAt: DateTime.parse(json['registeredAt'] as String),
    lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
    isOnline: (json['isOnline'] as bool?) ?? true,
  );
}

class AgentMessage {
  final String id;
  final String fromAgentId;
  final String? toAgentId;
  final String content;
  final MessagePriority priority;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const AgentMessage({
    required this.id,
    required this.fromAgentId,
    this.toAgentId,
    required this.content,
    this.priority = MessagePriority.normal,
    required this.timestamp,
    this.metadata = const {},
  });
}

class CollaborationTask {
  final String taskId;
  final String description;
  final String coordinatorId;
  final List<String> assignedAgentIds;
  final Map<String, String> agentAssignments;
  final DateTime createdAt;
  DateTime? completedAt;
  String status;

  CollaborationTask({
    required this.taskId,
    required this.description,
    required this.coordinatorId,
    this.assignedAgentIds = const [],
    this.agentAssignments = const {},
    DateTime? createdAt,
    this.completedAt,
    this.status = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();
}

class MultiAgentSociety {
  static const _agentsKey = 'cognitive_agent_society';
  static const _messagesKey = 'cognitive_agent_messages';

  final DatabaseService _db;
  final Map<String, AgentProfile> _agents = {};
  final List<AgentMessage> _messageQueue = [];
  final List<CollaborationTask> _tasks = [];
  final StreamController<AgentMessage> _messageController = StreamController.broadcast();

  bool _initialized = false;

  MultiAgentSociety(this._db);

  Stream<AgentMessage> get messageStream => _messageController.stream;
  List<AgentProfile> get agents => _agents.values.toList();
  List<AgentMessage> get pendingMessages => _messageQueue.where((m) => m.toAgentId != null).toList();
  List<CollaborationTask> get activeTasks => _tasks.where((t) => t.status != 'completed').toList();

  Future<void> init() async {
    if (_initialized) return;
    try {
      final agentsJson = await _db.getCache(_agentsKey);
      if (agentsJson != null) {
        final list = jsonDecode(agentsJson) as List<dynamic>;
        for (final item in list) {
          final profile = AgentProfile.fromJson(item as Map<String, dynamic>);
          _agents[profile.agentId] = profile;
        }
      }

      if (!_agents.containsKey('omni')) {
        _agents['omni'] = AgentProfile(
          agentId: 'omni',
          name: 'Omni',
          role: AgentRole.coordinator,
          capabilities: ['conversation', 'analysis', 'planning', 'memory', 'reasoning'],
        );
        await _persistAgents();
      }

      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('MultiAgentSociety init failed', error: e, stackTrace: st);
    }
  }

  void dispose() {
    _messageController.close();
  }

  Future<void> _persistAgents() async {
    try {
      await _db.putCache(_agentsKey, jsonEncode(_agents.values.map((a) => a.toJson()).toList()));
    } catch (e, st) {
      AppLogger.instance.error('MultiAgentSociety persist failed', error: e, stackTrace: st);
    }
  }

  AgentProfile? getAgent(String agentId) => _agents[agentId];

  List<AgentProfile> findAgentsByCapability(String capability) =>
      _agents.values.where((a) => a.capabilities.contains(capability) && a.isOnline).toList();

  Future<void> registerAgent(AgentProfile profile) async {
    _agents[profile.agentId] = profile;
    await _persistAgents();
  }

  Future<void> unregisterAgent(String agentId) async {
    _agents.remove(agentId);
    await _persistAgents();
  }

  void setAgentOnline(String agentId, bool online) {
    final agent = _agents[agentId];
    if (agent != null) {
      agent.isOnline = online;
      agent.lastActiveAt = DateTime.now();
    }
  }

  void sendMessage({
    required String fromAgentId,
    String? toAgentId,
    required String content,
    MessagePriority priority = MessagePriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    final message = AgentMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_${content.hashCode.abs()}',
      fromAgentId: fromAgentId,
      toAgentId: toAgentId,
      content: content,
      priority: priority,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _messageQueue.add(message);
    _messageController.add(message);

    if (_messageQueue.length > 100) {
      _messageQueue.removeRange(0, _messageQueue.length - 100);
    }
  }

  List<AgentMessage> getMessagesForAgent(String agentId) =>
      _messageQueue.where((m) => m.toAgentId == agentId || m.toAgentId == null).toList()
        ..sort((a, b) {
          final priorityOrder = {MessagePriority.urgent: 0, MessagePriority.high: 1, MessagePriority.normal: 2, MessagePriority.low: 3};
          final cmp = priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
          if (cmp != 0) return cmp;
          return b.timestamp.compareTo(a.timestamp);
        });

  void clearMessagesForAgent(String agentId) {
    _messageQueue.removeWhere((m) => m.toAgentId == agentId);
  }

  Future<CollaborationTask> createCollaboration({
    required String description,
    required String coordinatorId,
    Map<String, String>? requiredCapabilities,
  }) async {
    final assignments = <String, String>{};

    if (requiredCapabilities != null) {
      for (final entry in requiredCapabilities.entries) {
        final candidates = findAgentsByCapability(entry.value);
        if (candidates.isNotEmpty) {
          assignments[entry.key] = candidates.first.agentId;
        }
      }
    }

    final task = CollaborationTask(
      taskId: 'task_${DateTime.now().millisecondsSinceEpoch}_${description.hashCode.abs()}',
      description: description,
      coordinatorId: coordinatorId,
      assignedAgentIds: assignments.values.toList(),
      agentAssignments: assignments,
      status: 'active',
    );

    _tasks.add(task);

    for (final assignment in assignments.entries) {
      sendMessage(
        fromAgentId: coordinatorId,
        toAgentId: assignment.value,
        content: 'New task: $description. Your role: ${assignment.key}',
        priority: MessagePriority.high,
        metadata: {'taskId': task.taskId, 'role': assignment.key},
      );
    }

    return task;
  }

  void updateTaskStatus(String taskId, String status) {
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].taskId == taskId) {
        _tasks[i].status = status;
        if (status == 'completed') {
          _tasks[i].completedAt = DateTime.now();
        }
        break;
      }
    }
  }

  String buildSocietyContext() {
    if (_agents.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Agent Society]');
    buffer.writeln('- Registered agents: ${_agents.length}');

    final onlineAgents = _agents.values.where((a) => a.isOnline).toList();
    if (onlineAgents.isNotEmpty) {
      buffer.writeln('- Online agents: ${onlineAgents.map((a) => a.name).join(", ")}');
    }

    final activeTaskList = activeTasks;
    if (activeTaskList.isNotEmpty) {
      buffer.writeln('- Active collaborations: ${activeTaskList.length}');
      for (final task in activeTaskList.take(3)) {
        buffer.writeln('  - ${task.description} (${task.assignedAgentIds.length} agents)');
      }
    }

    return buffer.toString();
  }
}
