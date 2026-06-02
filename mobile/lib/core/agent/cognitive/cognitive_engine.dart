import 'dart:async';
import 'dart:convert';
import '../../app_logger.dart';
import '../../database_service.dart';
import '../../di/app_di.dart';
import '../../state_service.dart';
import '../../workspace_service.dart';
import '../../tool_memory.dart';
import '../../agent_service.dart';
import '../../planning_engine.dart';
import '../../capability_system.dart';
import '../../world_state_service.dart';
import '../../capability_graph.dart';
import '../../cross_app_action_engine.dart';
import '../../workspace_graph.dart';
import '../../event_store.dart';
import '../../knowledge_layer.dart';
import 'cognitive_types.dart';
import 'entity_store.dart';
import 'goal_store.dart';
import 'memory_event.dart';
import 'understanding_engine.dart';
import 'working_memory.dart';
import 'attention_engine.dart';
import 'recall_engine.dart';
import 'speaker_graph.dart';
import 'episodic_memory.dart';
import 'procedural_memory.dart';
import 'perception_engine.dart';
import 'reasoning_engine.dart';
import 'prediction_engine.dart';
import 'self_evolution.dart';
import 'multi_agent_society.dart';
import 'memory_transaction.dart';
import '../embedding_service.dart';
import '../runtime/agent_runtime.dart';
import '../runtime/context_assembly_engine.dart';
import '../runtime/conflict_resolver.dart';
import '../runtime/identity_engine.dart';
import '../runtime/priority_manager.dart';
import '../../providers/ai_provider.dart';

class CognitiveEngine {
  final EntityStore entityStore;
  final GoalStore goalStore;
  final UnderstandingEngine understandingEngine;
  final WorkingMemory workingMemory;
  final SpeakerGraph speakerGraph;
  final EpisodicMemoryStore episodicMemoryStore;
  final ProceduralMemoryStore proceduralMemoryStore;
  final AttentionEngine attentionEngine;
  final RecallEngine recallEngine;
  final PerceptionEngine perceptionEngine;
  final ReasoningEngine reasoningEngine;
  final PredictionEngine predictionEngine;
  final SelfEvolutionEngine selfEvolutionEngine;
  final MultiAgentSociety multiAgentSociety;
  final ConflictResolver conflictResolver;
  final IdentityEngine identityEngine;
  final ContextAssemblyEngine contextAssemblyEngine;
  final PriorityManager priorityManager;
  final AgentRuntime agentRuntime;

  static const _eventsKey = 'cognitive_events';
  static const _snapshotsKey = 'cognitive_snapshots';

  List<MemoryEvent> _events = [];
  List<MemorySnapshot> _snapshots = [];
  String? _activeWorkspaceId;

  Timer? _decayTimer;
  static const _decayInterval = Duration(hours: 24);

  CognitiveEngine({
    required this.entityStore,
    required this.goalStore,
    required this.understandingEngine,
    required this.workingMemory,
    required this.speakerGraph,
    required this.episodicMemoryStore,
    required this.proceduralMemoryStore,
    required this.attentionEngine,
    required this.recallEngine,
    required this.perceptionEngine,
    required this.reasoningEngine,
    required this.predictionEngine,
    required this.selfEvolutionEngine,
    required this.multiAgentSociety,
    required this.conflictResolver,
    required this.identityEngine,
    required this.contextAssemblyEngine,
    required this.priorityManager,
    required this.agentRuntime,
  });

  Future<void> init(DatabaseService db) async {
    await entityStore.init();
    await goalStore.init();
    await speakerGraph.init();
    await episodicMemoryStore.init();
    await proceduralMemoryStore.init();
    await selfEvolutionEngine.init(db);
    await multiAgentSociety.init();
    await conflictResolver.init();
    await identityEngine.init();
    contextAssemblyEngine.setEventsProvider(() => _events);
    try {
      final chatService = ChatService.instance;
      understandingEngine.setChatService(chatService);
    } catch (_) {}
    try {
      final evJson = await db.getCache(_eventsKey);
      if (evJson != null) {
        final list = jsonDecode(evJson) as List<dynamic>;
        _events = list.map((e) => MemoryEvent.fromJson(e as Map<String, dynamic>)).toList();
      }
      final snJson = await db.getCache(_snapshotsKey);
      if (snJson != null) {
        final list = jsonDecode(snJson) as List<dynamic>;
        _snapshots = list.map((e) => MemorySnapshot.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e, st) {
      AppLogger.instance.error('CognitiveEngine init failed', error: e, stackTrace: st);
    }
    startDecayTimer(db);
  }

  void dispose() {
    _decayTimer?.cancel();
  }

  // ── Core: Process Message ──

  Future<MemoryEvent?> processMessage(
    String message, {
    String? speakerId,
    String? workspaceId,
    List<String>? contextBefore,
    List<String>? contextAfter,
    DatabaseService? db,
    Map<String, dynamic>? preAnalyzed,
  }) async {
    final perception = perceptionEngine.perceive(message, speakerId: speakerId);

    UnderstandingResult result;
    if (preAnalyzed != null) {
      result = _understandingResultFromJson(preAnalyzed, message);
    } else {
      result = await understandingEngine.analyzeWithAI(message, speakerId: speakerId);
    }

    if (result.importance < 20) return null;

    final event = MemoryEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}_${message.hashCode.abs()}',
      timestamp: DateTime.now(),
      eventType: result.eventType,
      summary: result.summary,
      importance: result.importance,
      persistence: result.persistence,
      confidence: result.confidence,
      memoryType: result.memoryType,
      intent: result.intent,
      domain: perception.domain,
      workspaceId: workspaceId ?? _activeWorkspaceId,
      speakerId: speakerId,
      source: 'conversation',
      lifecycle: MemoryLifecycle.active,
      reason: result.reason,
      properties: {
        if (result.entityName != null) 'entityName': result.entityName,
        if (result.entityType != null) 'entityType': result.entityType!.name,
        if (result.relationType != null) 'relationType': result.relationType!.name,
        if (result.relatedEntityName != null) 'relatedEntityName': result.relatedEntityName,
        'format': perception.format.name,
        'isQuestion': perception.isQuestion,
        'isCommand': perception.isCommand,
        'isEmotional': perception.isEmotional,
        if (perception.language != null) 'language': perception.language,
        if (perception.detectedTopics.isNotEmpty) 'topics': perception.detectedTopics.join(','),
        if (result.entities.isNotEmpty) 'extractedEntities': result.entities.map((e) => e.toJson()).toList(),
        if (result.relations.isNotEmpty) 'extractedRelations': result.relations.map((r) => r.toJson()).toList(),
        if (result.events.isNotEmpty) 'extractedEvents': result.events.map((e) => e.toJson()).toList(),
        'fromAI': result.fromAI,
      },
    );

    _events.add(event);

    try {
      final embeddingService = EmbeddingService.instance;
      await embeddingService.getEmbedding(event.summary);
      embeddingService.associateEventId(event.summary, event.id);
    } catch (_) {}

    if (contextBefore != null || contextAfter != null) {
      final snapshot = MemorySnapshot(
        id: 'snap_${event.id}',
        eventId: event.id,
        rawMessage: message,
        contextBefore: contextBefore ?? [],
        contextAfter: contextAfter ?? [],
        createdAt: DateTime.now(),
      );
      _snapshots.add(snapshot);
    }

    for (final extracted in result.entities) {
      final entity = await entityStore.findOrCreateEntity(
        name: extracted.name,
        type: extracted.type,
        domain: perception.domain,
        workspaceId: workspaceId ?? _activeWorkspaceId,
        properties: extracted.properties,
      );
      for (final alias in extracted.aliases) {
        await entityStore.addAlias(entity.id, alias);
      }
    }

    for (final extractedRel in result.relations) {
      final fromEntity = entityStore.getEntityByName(extractedRel.fromEntity);
      final toEntity = entityStore.getEntityByName(extractedRel.toEntity);
      if (fromEntity != null && toEntity != null) {
        await entityStore.addRelation(
          fromEntityId: fromEntity.id,
          toEntityId: toEntity.id,
          type: extractedRel.type,
          sourceEventId: event.id,
          metadata: extractedRel.metadata,
        );
      }
    }

    if (result.entityName != null && result.entityType != null && result.entities.isEmpty) {
      final entity = await entityStore.findOrCreateEntity(
        name: result.entityName!,
        type: result.entityType!,
        domain: perception.domain,
        workspaceId: workspaceId ?? _activeWorkspaceId,
      );
      if (result.relationType != null && result.relatedEntityName != null) {
        final relatedEntityType = _inferRelatedEntityType(
          result.relationType!,
          result.entityType!,
        );
        final related = await entityStore.findOrCreateEntity(
          name: result.relatedEntityName!,
          type: relatedEntityType,
          domain: perception.domain,
          workspaceId: workspaceId ?? _activeWorkspaceId,
        );
        await entityStore.addRelation(
          fromEntityId: related.id,
          toEntityId: entity.id,
          type: result.relationType!,
          sourceEventId: event.id,
        );
      }
    }

    if (result.memoryType == MemoryType.goal && result.importance >= 60) {
      await goalStore.createGoal(
        title: result.summary,
        workspaceId: workspaceId ?? _activeWorkspaceId,
        priority: result.importance,
      );
    }

    if (speakerId != null) {
      await speakerGraph.recordSpeaker(
        speakerId: speakerId,
        speakerType: speakerId == 'agent' ? 'agent' : 'user',
      );
    }

    attentionEngine.updateWorkingMemory(message, workspaceId: workspaceId);

    final conflicts = conflictResolver.detectConflicts(event, _events);
    if (conflicts.isNotEmpty) {
      for (final conflict in conflicts) {
        if (conflict.strategy == ResolutionStrategy.latestWins) {
          await conflictResolver.resolveConflict(conflict.id, winnerId: event.id);
        }
      }
    }

    await identityEngine.processClaim(event);
    await identityEngine.recordBehavior(event);

    if (db != null) await _commitTransaction(db);
    return event;
  }

  EntityType _inferRelatedEntityType(RelationType relationType, EntityType primaryType) {
    switch (relationType) {
      case RelationType.owns:
      case RelationType.created:
      case RelationType.decided:
        return EntityType.person;
      case RelationType.uses:
      case RelationType.dependsOn:
      case RelationType.supports:
        return EntityType.tech;
      case RelationType.partOf:
        return EntityType.project;
      case RelationType.knows:
        return EntityType.person;
      case RelationType.prefers:
        return primaryType == EntityType.person ? EntityType.tech : EntityType.person;
      case RelationType.blocks:
        return EntityType.task;
    }
  }

  UnderstandingResult _understandingResultFromJson(Map<String, dynamic> json, String rawMessage) {
    IntentType intent;
    try {
      intent = IntentType.values.firstWhere(
        (e) => e.name == json['intent'],
        orElse: () => IntentType.fact,
      );
    } catch (_) {
      intent = IntentType.fact;
    }

    EmotionType emotion;
    try {
      emotion = EmotionType.values.firstWhere(
        (e) => e.name == json['emotion'],
        orElse: () => EmotionType.neutral,
      );
    } catch (_) {
      emotion = EmotionType.neutral;
    }

    MemoryPersistence persistence;
    try {
      persistence = MemoryPersistence.values.firstWhere(
        (e) => e.name == json['persistence'] || e.name.toLowerCase() == (json['persistence'] as String?)?.toLowerCase(),
        orElse: () => MemoryPersistence.shortTerm,
      );
    } catch (_) {
      persistence = MemoryPersistence.shortTerm;
    }

    MemoryType memoryType;
    try {
      memoryType = MemoryType.values.firstWhere(
        (e) => e.name == json['memoryType'],
        orElse: () => MemoryType.fact,
      );
    } catch (_) {
      memoryType = MemoryType.fact;
    }

    MemoryDomain domain;
    try {
      domain = MemoryDomain.values.firstWhere(
        (e) => e.name == json['domain'],
        orElse: () => MemoryDomain.project,
      );
    } catch (_) {
      domain = MemoryDomain.project;
    }

    final entities = <ExtractedEntity>[];
    final entitiesJson = json['entities'] as List<dynamic>?;
    if (entitiesJson != null) {
      for (final e in entitiesJson) {
        final map = e as Map<String, dynamic>;
        EntityType entityType;
        try {
          entityType = EntityType.values.firstWhere(
            (t) => t.name == map['type'],
            orElse: () => EntityType.concept,
          );
        } catch (_) {
          entityType = EntityType.concept;
        }
        entities.add(ExtractedEntity(
          name: map['name'] as String? ?? '',
          type: entityType,
          aliases: (map['aliases'] as List<dynamic>?)?.cast<String>() ?? [],
          properties: (map['properties'] as Map<String, dynamic>?) ?? {},
        ));
      }
    }

    final relations = <ExtractedRelation>[];
    final relationsJson = json['relations'] as List<dynamic>?;
    if (relationsJson != null) {
      for (final r in relationsJson) {
        final map = r as Map<String, dynamic>;
        RelationType relType;
        try {
          relType = RelationType.values.firstWhere(
            (t) => t.name == map['type'],
            orElse: () => RelationType.knows,
          );
        } catch (_) {
          relType = RelationType.knows;
        }
        relations.add(ExtractedRelation(
          fromEntity: map['fromEntity'] as String? ?? '',
          toEntity: map['toEntity'] as String? ?? '',
          type: relType,
          metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
        ));
      }
    }

    final events = <ExtractedEvent>[];
    final eventsJson = json['events'] as List<dynamic>?;
    if (eventsJson != null) {
      for (final ev in eventsJson) {
        final map = ev as Map<String, dynamic>;
        events.add(ExtractedEvent(
          type: map['eventType'] as String? ?? map['type'] as String? ?? 'statement',
          properties: {'description': map['description'] ?? ''},
        ));
      }
    }

    return UnderstandingResult(
      intent: intent,
      emotion: emotion,
      importance: (json['importance'] as num?)?.toInt() ?? 50,
      persistence: persistence,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 80,
      memoryType: memoryType,
      domain: domain,
      eventType: json['eventType'] as String? ?? (events.isNotEmpty ? events.first.type : 'statement'),
      summary: json['summary'] as String? ?? rawMessage.substring(0, rawMessage.length > 100 ? 100 : rawMessage.length),
      entities: entities,
      relations: relations,
      events: events,
      fromAI: true,
      workspaceId: json['workspaceId'] as String?,
      topic: json['topic'] as String?,
    ).withLegacyFields();
  }

  Map<String, dynamic> _createAgentAnalysis(String agentResponse, Map<String, dynamic>? userAnalysis) {
    final hasEntities = userAnalysis?['entities'] != null &&
        (userAnalysis!['entities'] as List).isNotEmpty;
    final userDomain = userAnalysis?['domain'] as String? ?? 'project';

    return {
      'intent': 'fact',
      'importance': hasEntities ? 60 : 30,
      'persistence': 'shortTerm',
      'memoryType': 'fact',
      'domain': userDomain,
      'summary': agentResponse.length > 100
          ? agentResponse.substring(0, 100)
          : agentResponse,
      'confidence': 80,
      'entities': <Map<String, dynamic>>[],
      'relations': <Map<String, dynamic>>[],
      'events': <Map<String, dynamic>>[
        {'eventType': 'agent_response', 'description': 'Agent provided response'}
      ],
    };
  }

  // ── Reflection (Enhanced) ──

  Future<void> reflect(
    String userMessage,
    String agentResponse, {
    String? workspaceId,
    required DatabaseService db,
    Map<String, dynamic>? preAnalyzedUser,
  }) async {
    final userEvent = await processMessage(userMessage, workspaceId: workspaceId, db: db, preAnalyzed: preAnalyzedUser);
    final agentAnalysis = _createAgentAnalysis(agentResponse, preAnalyzedUser);
    final agentEvent = await processMessage(agentResponse, speakerId: 'agent', workspaceId: workspaceId, db: db, preAnalyzed: agentAnalysis);

    await _updateEntityStatesFromEvents([userEvent, agentEvent], db: db);
    await _updateGoalProgressFromEvents([userEvent, agentEvent], db: db);
    await _tryCreateEpisode(userMessage, agentResponse, [userEvent, agentEvent], workspaceId: workspaceId);
    await selfEvolutionEngine.observeInteraction(
      userMessage: userMessage,
      agentResponse: agentResponse,
      db: db,
    );

    await _tryRecordLessonsFromFailures(workspaceId: workspaceId);

    await _tryRecordKnowledge(userMessage, agentResponse, workspaceId: workspaceId);

    await _commitTransaction(db);
  }

  Future<void> _commitTransaction(DatabaseService db) async {
    final tx = MemoryTransaction(db);

    entityStore.registerWithTransaction(tx);
    goalStore.registerWithTransaction(tx);
    identityEngine.registerWithTransaction(tx);
    episodicMemoryStore.registerWithTransaction(tx);
    proceduralMemoryStore.registerWithTransaction(tx);
    speakerGraph.registerWithTransaction(tx);
    selfEvolutionEngine.registerWithTransaction(tx);
    conflictResolver.registerWithTransaction(tx);

    tx.register(_eventsKey, () => jsonEncode(_events.map((e) => e.toJson()).toList()));
    tx.register(_snapshotsKey, () => jsonEncode(_snapshots.map((e) => e.toJson()).toList()));

    await tx.commit();
  }

  Future<void> _tryRecordLessonsFromFailures({String? workspaceId}) async {
    final overdueGoals = goalStore.getOverdueGoals();
    for (final goal in overdueGoals) {
      if (goal.progress < 30) {
        await proceduralMemoryStore.recordLesson(
          lesson: '目标"${goal.title}"逾期且进度不足30%，需要更细粒度的子目标分解',
          trigger: goal.title.toLowerCase().split(RegExp(r'\s+')).first,
          action: '分解为更小的子目标并设定更近的截止日期',
        );
      }
    }

    final blockedGoals = goalStore.getBlockedGoals();
    for (final goal in blockedGoals) {
      await proceduralMemoryStore.recordLesson(
        lesson: '目标"${goal.title}"被阻塞: ${goal.blockers.join(",")}',
        trigger: goal.title.toLowerCase().split(RegExp(r'\s+')).first,
        action: '先解除阻塞因素再推进目标',
      );
    }

    final highDepEntities = entityStore.entities.where((e) {
      final deps = entityStore.getRelationsFrom(e.id)
          .where((r) => r.type == RelationType.dependsOn)
          .length;
      return deps > 3 && e.lifecycle == MemoryLifecycle.active;
    }).toList();

    for (final entity in highDepEntities) {
      await proceduralMemoryStore.recordLesson(
        lesson: '实体${entity.name}耦合度过高(>3依赖)，修改时需谨慎',
        trigger: entity.name.toLowerCase(),
        action: '评估影响范围后再修改，考虑解耦',
      );
    }

    final blockingEntities = entityStore.entities.where((e) {
      final blocks = entityStore.getRelationsFrom(e.id)
          .where((r) => r.type == RelationType.blocks)
          .length;
      return blocks > 0 && e.lifecycle == MemoryLifecycle.active;
    }).toList();

    for (final entity in blockingEntities) {
      await proceduralMemoryStore.recordLesson(
        lesson: '实体${entity.name}正在阻塞其他实体',
        trigger: entity.name.toLowerCase(),
        action: '优先解决${entity.name}的阻塞状态',
      );
    }
  }

  Future<void> _tryRecordKnowledge(
    String userMessage,
    String agentResponse, {
    String? workspaceId,
  }) async {
    try {
      final knowledge = getIt<KnowledgeLayerService>();
      if (!knowledge.isInitialized) return;

      final userLower = userMessage.toLowerCase();
      final agentLower = agentResponse.toLowerCase();

      final isProjectSpecific = workspaceId != null;
      final layer = isProjectSpecific ? KnowledgeLayer.project : KnowledgeLayer.personal;

      if (userLower.contains('记住') || userLower.contains('记下来') ||
          userLower.contains('不要忘') || userLower.contains('always') ||
          userLower.contains('remember') || userLower.contains('note that')) {
        final content = userMessage.length > 200
            ? '${userMessage.substring(0, 200)}...'
            : userMessage;
        await knowledge.addEntry(
          title: 'User Preference',
          content: content,
          layer: layer,
          workspaceId: workspaceId,
          tags: ['preference', 'user-requested'],
        );
        return;
      }

      if (agentLower.contains('plan') && agentLower.contains('step') &&
          (agentLower.contains('<<<plan>>>') || agentLower.contains('执行计划'))) {
        final content = agentResponse.length > 300
            ? '${agentResponse.substring(0, 300)}...'
            : agentResponse;
        await knowledge.addEntry(
          title: 'Plan Created',
          content: content,
          layer: KnowledgeLayer.agent,
          workspaceId: workspaceId,
          tags: ['plan', 'auto-recorded'],
        );
        return;
      }

      if (userLower.contains('怎么') || userLower.contains('如何') ||
          userLower.contains('how to') || userLower.contains('how do')) {
        final content = '${userMessage}\n→ ${agentResponse.length > 200 ? '${agentResponse.substring(0, 200)}...' : agentResponse}';
        await knowledge.addEntry(
          title: 'How-to: ${userMessage.length > 50 ? '${userMessage.substring(0, 50)}...' : userMessage}',
          content: content,
          layer: layer,
          workspaceId: workspaceId,
          tags: ['how-to', 'auto-recorded'],
        );
      }
    } catch (e) {
      AppLogger.instance.warning('Knowledge recording failed', error: e);
    }
  }

  Future<void> _updateEntityStatesFromEvents(List<MemoryEvent?> events, {DatabaseService? db}) async {
    for (final event in events) {
      if (event == null) continue;

      final entityName = event.properties['entityName'] as String?;
      if (entityName == null) continue;

      final entity = entityStore.getEntityByName(entityName);
      if (entity == null) continue;

      String? newState;
      switch (event.memoryType) {
        case MemoryType.goal:
          newState = 'goal_set';
        case MemoryType.decision:
          newState = 'decision_made';
        case MemoryType.experience:
          newState = 'experienced';
        default:
          continue;
      }

      await entityStore.setEntityState(
        entity.id,
        newState,
        sourceEventId: event.id,
      );
    }
  }

  Future<void> _updateGoalProgressFromEvents(List<MemoryEvent?> events, {DatabaseService? db}) async {
    for (final event in events) {
      if (event == null) continue;
      if (event.memoryType != MemoryType.goal) continue;

      final activeGoals = goalStore.getActiveGoals(workspaceId: event.workspaceId);
      for (final goal in activeGoals) {
        if (goal.status != GoalStatus.inProgress) continue;

        final titleLower = goal.title.toLowerCase();
        final summaryLower = event.summary.toLowerCase();
        if (!_isRelevantToGoal(titleLower, summaryLower)) continue;

        final newProgress = (goal.progress + 10).clamp(0, 100);
        await goalStore.updateGoalProgress(goal.id, newProgress);
      }
    }
  }

  bool _isRelevantToGoal(String goalTitle, String eventSummary) {
    final goalWords = goalTitle.split(RegExp(r'\s+')).where((w) => w.length > 1).toSet();
    final eventWords = eventSummary.split(RegExp(r'\s+')).where((w) => w.length > 1).toSet();
    return goalWords.intersection(eventWords).isNotEmpty;
  }

  Future<void> _tryCreateEpisode(
    String userMessage,
    String agentResponse,
    List<MemoryEvent?> events, {
    String? workspaceId,
  }) async {
    final hasImportantEvent = events.any((e) => e != null && e.importance >= 70);
    if (!hasImportantEvent) return;

    final scene = userMessage.length > 80 ? '${userMessage.substring(0, 77)}...' : userMessage;
    final eventIds = events.whereType<MemoryEvent>().map((e) => e.id).toList();

    await episodicMemoryStore.createEpisode(
      scene: scene,
      participants: ['user', 'agent'],
      workspaceId: workspaceId,
      relatedEventIds: eventIds,
    );
  }

  // ── Workspace (delegated to WorkspaceService) ──

  String? get activeWorkspaceId => _activeWorkspaceId;

  void setActiveWorkspace(String? workspaceId) {
    _activeWorkspaceId = workspaceId;
  }

  // ── Events ──

  List<MemoryEvent> get events => List.unmodifiable(_events);

  List<MemoryEvent> getRecentEvents({int limit = 20, String? workspaceId}) {
    var filtered = _events.where((e) => e.lifecycle != MemoryLifecycle.frozen).toList();
    if (workspaceId != null) {
      filtered = filtered.where((e) => e.workspaceId == workspaceId).toList();
    }
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.take(limit).toList();
  }

  List<MemoryEvent> getImportantEvents({int minImportance = 80}) =>
      _events.where((e) => e.importance >= minImportance).toList()
        ..sort((a, b) => b.importance.compareTo(a.importance));

  MemorySnapshot? getSnapshot(String eventId) {
    for (final s in _snapshots) {
      if (s.eventId == eventId) return s;
    }
    return null;
  }

  Future<UnderstandingResult> understand(String message, {String? speakerId}) async {
    final perception = perceptionEngine.perceive(message, speakerId: speakerId);
    final result = await understandingEngine.analyzeWithAI(message, speakerId: speakerId);

    String? topic;
    if (result.entities.isNotEmpty) {
      topic = result.entities.first.name;
    } else if (perception.detectedTopics.isNotEmpty) {
      topic = perception.detectedTopics.first;
    }

    String? resolvedWorkspaceId;
    try {
      final ws = getIt<WorkspaceService>();
      if (!ws.isInitialized) await ws.init();
      final workspace = await ws.resolveWorkspace(
        _activeWorkspaceId,
        topic,
      );
      if (workspace != null) {
        resolvedWorkspaceId = workspace.id;
        if (_activeWorkspaceId != workspace.id) {
          _activeWorkspaceId = workspace.id;
        }
      }
    } catch (e) {
      resolvedWorkspaceId = _activeWorkspaceId;
    }

    final needsReasoning = result.intent == IntentType.command ||
        result.intent == IntentType.decision ||
        result.intent == IntentType.goal ||
        result.importance >= 70;

    if (needsReasoning) {
      try {
        final reasoningConclusions = reasoningEngine.reason(
          message,
          perception,
          _events.length > 10 ? _events.sublist(_events.length - 10) : _events,
        );
        if (reasoningConclusions.isNotEmpty) {
          AppLogger.instance.info(
            'Reasoning: ${reasoningConclusions.first.summary} '
            '(confidence: ${reasoningConclusions.first.confidence.toStringAsFixed(0)}%)',
          );
        }
      } catch (e) {
        AppLogger.instance.warning('Reasoning failed', error: e);
      }
    }

    return UnderstandingResult(
      intent: result.intent,
      emotion: result.emotion,
      importance: result.importance,
      persistence: result.persistence,
      confidence: result.confidence,
      memoryType: result.memoryType,
      domain: result.domain,
      eventType: result.eventType,
      summary: result.summary,
      entityName: result.entityName,
      entityType: result.entityType,
      relationType: result.relationType,
      relatedEntityName: result.relatedEntityName,
      reason: result.reason,
      entities: result.entities,
      relations: result.relations,
      events: result.events,
      fromAI: result.fromAI,
      workspaceId: resolvedWorkspaceId,
      topic: topic,
    ).withLegacyFields();
  }

  // ── Reasoning ──

  List<ReasoningConclusion> reason(String message, {String? speakerId, String? workspaceId}) {
    final perception = perceptionEngine.perceive(message, speakerId: speakerId);
    final recentEvents = getRecentEvents(limit: 20, workspaceId: workspaceId);
    return reasoningEngine.reason(message, perception, recentEvents);
  }

  // ── Prediction ──

  List<Prediction> predict({String? workspaceId}) =>
      predictionEngine.predict(workspaceId: workspaceId);

  // ── Recall ──

  Future<RecallResult> recall(RecallQuery query) async => recallEngine.recall(query, _events);

  // ── Event Lifecycle Decay ──

  void startDecayTimer(DatabaseService db) {
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(_decayInterval, (_) async {
      await runDecay(db);
    });
  }

  Future<void> runDecay(DatabaseService db) async {
    await _decayEvents();
    await _decaySnapshots();
    await entityStore.decayLifecycle();
    await _commitTransaction(db);
  }

  Future<void> _decayEvents() async {
    final now = DateTime.now();
    for (var i = 0; i < _events.length; i++) {
      final event = _events[i];
      if (event.persistence == MemoryPersistence.permanent) continue;
      if (event.lifecycle == MemoryLifecycle.frozen) continue;

      final age = now.difference(event.timestamp);
      MemoryLifecycle newLifecycle;
      switch (event.persistence) {
        case MemoryPersistence.ephemeral:
          newLifecycle = age.inDays > 1 ? MemoryLifecycle.warm : event.lifecycle;
          if (age.inDays > 7) newLifecycle = MemoryLifecycle.frozen;
        case MemoryPersistence.shortTerm:
          newLifecycle = age.inDays > 30 ? MemoryLifecycle.warm : event.lifecycle;
          if (age.inDays > 180) newLifecycle = MemoryLifecycle.frozen;
        case MemoryPersistence.longTerm:
          newLifecycle = age.inDays > 365 ? MemoryLifecycle.warm : event.lifecycle;
          if (age.inDays > 730) newLifecycle = MemoryLifecycle.frozen;
        case MemoryPersistence.permanent:
          continue;
      }

      if (newLifecycle != event.lifecycle) {
        _events[i] = event.copyWith(lifecycle: newLifecycle);
      }
    }
  }

  Future<void> _decaySnapshots() async {
    final now = DateTime.now();
    final activeEventIds = _events
        .where((e) => e.lifecycle == MemoryLifecycle.active)
        .map((e) => e.id)
        .toSet();

    _snapshots.removeWhere((s) {
      if (activeEventIds.contains(s.eventId)) return false;
      final age = now.difference(s.createdAt);
      return age.inDays > 90;
    });
  }

  // ── Context for AI Prompt ──

  Future<String> buildMemoryContext({String? workspaceId, int maxItems = 20, UnderstandingResult? understanding}) async {
    final buffer = StringBuffer();

    final clue = understanding?.summary ?? (_events.isNotEmpty ? _events.last.summary : '');
    final wsId = understanding?.workspaceId ?? workspaceId;

    final assembled = await contextAssemblyEngine.assemble(
      clue,
      workspaceId: wsId,
      perception: understanding != null ? PerceptionResult(
        domain: understanding.domain,
        detectedEntities: understanding.entities.map((e) => e.name).toList(),
        detectedTopics: [if (understanding.topic != null) understanding.topic!],
      ) : null,
    );
    final assembledStr = assembled.toPromptString();
    if (assembledStr.isNotEmpty) buffer.writeln(assembledStr);

    final activeGoals = goalStore.getActiveGoals(workspaceId: wsId);
    if (activeGoals.isNotEmpty) {
      buffer.writeln('\n[Active Goals]');
      for (final goal in activeGoals.take(5)) {
        buffer.writeln('- ${goal.title} (progress: ${goal.progress}%, priority: ${goal.priority})');
      }
    }

    if (understanding != null) {
      buffer.writeln('\n[Understanding]');
      buffer.writeln('- Intent: ${understanding.intent.name}');
      buffer.writeln('- Emotion: ${understanding.emotion.name}');
      buffer.writeln('- Importance: ${understanding.importance}/100');
      buffer.writeln('- Confidence: ${understanding.confidence.toStringAsFixed(0)}%');
      if (understanding.entities.isNotEmpty) {
        buffer.writeln('- Entities: ${understanding.entities.map((e) => e.name).join(", ")}');
      }
      if (understanding.topic != null) {
        buffer.writeln('- Topic: ${understanding.topic}');
      }
    }

    try {
      final ws = getIt<WorkspaceService>();
      if (ws.isInitialized && wsId != null) {
        final projectPrompt = ws.buildProjectContextPrompt(wsId);
        if (projectPrompt.isNotEmpty) {
          buffer.writeln('\n$projectPrompt');
        }
      }
    } catch (_) {}

    final selfContext = selfEvolutionEngine.buildSelfContext();
    if (selfContext.isNotEmpty) buffer.writeln('\n$selfContext');

    final identityContext = identityEngine.buildIdentityContext();
    if (identityContext.isNotEmpty) buffer.writeln('\n$identityContext');

    final predictions = predictionEngine.predict(workspaceId: wsId);
    if (predictions.isNotEmpty) {
      buffer.writeln('\n[Predictions]');
      for (final p in predictions.take(5)) {
        buffer.writeln('- [${p.type.name}] ${p.description} (${p.probability.toStringAsFixed(0)}%)');
        if (p.suggestedAction != null) {
          buffer.writeln('  → ${p.suggestedAction}');
        }
      }
    }

    try {
      final toolMemory = getIt<ToolMemory>();
      if (toolMemory.isInitialized) {
        final toolContext = toolMemory.buildToolMemoryContext();
        if (toolContext.isNotEmpty) buffer.writeln('\n$toolContext');
      }
    } catch (_) {}

    try {
      final agentService = getIt<AgentService>();
      if (agentService.isInitialized) {
        final agentContext = agentService.buildSocietyContext();
        if (agentContext.isNotEmpty) buffer.writeln('\n$agentContext');
      }
    } catch (_) {}

    try {
      final planningEngine = getIt<PlanningEngine>();
      if (planningEngine.isInitialized) {
        final planContext = planningEngine.buildPlanContext();
        if (planContext.isNotEmpty) buffer.writeln('\n$planContext');
      }
    } catch (_) {}

    try {
      final stateService = getIt<StateService>();
      if (stateService.isInitialized) {
        final stateContext = stateService.buildStateContext(workspaceId: wsId);
        if (stateContext.isNotEmpty) buffer.writeln('\n$stateContext');
      }
    } catch (_) {}

    try {
      final capRegistry = getIt<CapabilityRegistry>();
      if (capRegistry.isInitialized) {
        final capContext = capRegistry.buildCapabilityContext();
        if (capContext.isNotEmpty) buffer.writeln('\n$capContext');
      }
    } catch (_) {}

    try {
      final worldState = getIt<WorldStateService>();
      if (worldState.isInitialized) {
        final wsContext = worldState.buildWorldStateContext(workspaceId: wsId);
        if (wsContext.isNotEmpty) buffer.writeln('\n$wsContext');
      }
    } catch (_) {}

    try {
      final capGraph = getIt<CapabilityGraph>();
      if (capGraph.isInitialized) {
        final graphContext = capGraph.buildGraphContext();
        if (graphContext.isNotEmpty) buffer.writeln('\n$graphContext');
      }
    } catch (_) {}

    try {
      final crossApp = getIt<CrossAppActionEngine>();
      if (crossApp.isInitialized) {
        final chainContext = crossApp.buildChainContext(workspaceId: wsId);
        if (chainContext.isNotEmpty) buffer.writeln('\n$chainContext');
      }
    } catch (_) {}

    try {
      final wsGraph = getIt<WorkspaceGraph>();
      if (wsGraph.isInitialized) {
        final graphContext = wsGraph.buildWorkspaceGraphContext(workspaceId: wsId);
        if (graphContext.isNotEmpty) buffer.writeln('\n$graphContext');
        if (wsId != null) {
          final wsNode = wsGraph.getNode(wsId);
          if (wsNode != null) {
            final recoveryContext = wsGraph.buildRecoveryContext(wsNode.name);
            if (recoveryContext.isNotEmpty) buffer.writeln('\n$recoveryContext');
          }
        }
      }
    } catch (_) {}

    try {
      final eventStore = getIt<EventStore>();
      if (eventStore.isInitialized) {
        final eventContext = eventStore.buildEventContext();
        if (eventContext.isNotEmpty) buffer.writeln('\n$eventContext');
      }
    } catch (_) {}

    try {
      final knowledge = getIt<KnowledgeLayerService>();
      if (knowledge.isInitialized) {
        final knContext = knowledge.buildKnowledgeContext(workspaceId: wsId);
        if (knContext.isNotEmpty) buffer.writeln('\n$knContext');
      }
    } catch (_) {}

    return buffer.toString();
  }

  // ── Stats ──

  int get eventCount => _events.length;
  int get snapshotCount => _snapshots.length;
}
