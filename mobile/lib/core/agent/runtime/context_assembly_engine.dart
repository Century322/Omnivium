import '../cognitive/cognitive_types.dart';
import '../cognitive/entity_layer.dart';
import '../cognitive/entity_store.dart';
import '../cognitive/goal_store.dart';
import '../cognitive/memory_event.dart';
import '../cognitive/working_memory.dart';
import '../cognitive/attention_engine.dart';
import '../cognitive/recall_engine.dart';
import '../cognitive/perception_engine.dart';
import '../cognitive/procedural_memory.dart';

class AssembledContext {
  final String workspaceId;
  final String? activeGoalId;
  final List<String> activeEntityIds;
  final List<MemoryEvent> relevantEvents;
  final List<MemoryEntity> relevantEntities;
  final List<EntityRelation> relevantRelations;
  final String attentionSummary;
  final String procedureHints;
  final int totalTokenEstimate;

  const AssembledContext({
    required this.workspaceId,
    this.activeGoalId,
    this.activeEntityIds = const [],
    this.relevantEvents = const [],
    this.relevantEntities = const [],
    this.relevantRelations = const [],
    this.attentionSummary = '',
    this.procedureHints = '',
    this.totalTokenEstimate = 0,
  });

  String toPromptString() {
    final buffer = StringBuffer();

    if (relevantEntities.isNotEmpty) {
      buffer.writeln('[Active Entities]');
      for (final e in relevantEntities.take(8)) {
        buffer.writeln('- ${e.name} (${e.type.name}): ${e.currentState}');
      }
    }

    if (relevantEvents.isNotEmpty) {
      buffer.writeln('\n[Relevant Memory]');
      for (final e in relevantEvents.take(10)) {
        buffer.writeln('- [${e.memoryType.name}] ${e.summary}');
      }
    }

    if (relevantRelations.isNotEmpty) {
      buffer.writeln('\n[Key Relations]');
      for (final r in relevantRelations.take(5)) {
        buffer.writeln('- ${r.type.name}: ${r.fromEntityId} → ${r.toEntityId}');
      }
    }

    if (attentionSummary.isNotEmpty) {
      buffer.writeln('\n$attentionSummary');
    }

    if (procedureHints.isNotEmpty) {
      buffer.writeln('\n$procedureHints');
    }

    return buffer.toString();
  }
}

class ContextAssemblyEngine {
  final EntityStore entityStore;
  final GoalStore goalStore;
  final WorkingMemory workingMemory;
  final AttentionEngine attentionEngine;
  final RecallEngine recallEngine;
  final ProceduralMemoryStore proceduralMemoryStore;

  List<MemoryEvent> Function()? _eventsProvider;

  static const _maxContextTokens = 2000;
  static const _avgCharsPerToken = 4;

  ContextAssemblyEngine({
    required this.entityStore,
    required this.goalStore,
    required this.workingMemory,
    required this.attentionEngine,
    required this.recallEngine,
    required this.proceduralMemoryStore,
    List<MemoryEvent> Function()? eventsProvider,
  }) : _eventsProvider = eventsProvider;

  void setEventsProvider(List<MemoryEvent> Function() provider) {
    _eventsProvider = provider;
  }

  Future<AssembledContext> assemble(String currentInput, {String? workspaceId, PerceptionResult? perception}) async {
    final wsId = workspaceId ?? workingMemory.currentWorkspaceId ?? 'default';
    final activeEntities = <MemoryEntity>[];
    final activeEntityIds = <String>[];
    final relevantEvents = <MemoryEvent>[];
    final relevantRelations = <EntityRelation>[];
    var tokenBudget = _maxContextTokens;

    final attention = attentionEngine.computeAttention(workspaceId: wsId);
    for (final focus in attention) {
      if (focus.focusType == 'entity') {
        final entity = entityStore.getEntity(focus.focusId);
        if (entity != null && entity.lifecycle == MemoryLifecycle.active) {
          activeEntities.add(entity);
          activeEntityIds.add(entity.id);
        }
      }
    }

    if (perception != null) {
      for (final entityName in perception.detectedEntities) {
        final entity = entityStore.getEntityByName(entityName);
        if (entity != null && !activeEntityIds.contains(entity.id)) {
          activeEntities.add(entity);
          activeEntityIds.add(entity.id);
        }
      }
    }

    for (final entityId in activeEntityIds) {
      final relations = entityStore.getRelationsFrom(entityId)
          .where((r) => r.type == RelationType.dependsOn || r.type == RelationType.blocks || r.type == RelationType.uses)
          .take(3);
      relevantRelations.addAll(relations);
    }

    final recallQuery = RecallQuery(
      clue: currentInput,
      workspaceId: wsId,
      minImportance: 30,
    );
    final recallResult = await recallEngine.recall(recallQuery, _getRecentEvents());
    for (final event in recallResult.events) {
      if (tokenBudget <= 0) break;
      final estimatedTokens = (event.summary.length / _avgCharsPerToken).ceil();
      if (estimatedTokens <= tokenBudget) {
        relevantEvents.add(event);
        tokenBudget -= estimatedTokens;
      }
    }

    final activeGoals = goalStore.getActiveGoals(workspaceId: wsId);
    String? activeGoalId;
    if (activeGoals.isNotEmpty) {
      final topGoal = activeGoals.first;
      activeGoalId = topGoal.id;
      final goalEvents = _getRecentEvents()
          .where((e) => e.memoryType == MemoryType.goal && _isRelevantToGoal(topGoal.title, e.summary))
          .take(3);
      for (final event in goalEvents) {
        if (!relevantEvents.any((e) => e.id == event.id)) {
          relevantEvents.add(event);
        }
      }
    }

    final attentionContext = attentionEngine.buildAttentionContext(workspaceId: wsId);

    final triggeredProcedures = proceduralMemoryStore.getTriggeredProcedures(currentInput);
    final procedureHints = triggeredProcedures.isNotEmpty
        ? triggeredProcedures.map((p) => 'IF "${p.trigger}" THEN ${p.action}').join('\n')
        : '';

    return AssembledContext(
      workspaceId: wsId,
      activeGoalId: activeGoalId,
      activeEntityIds: activeEntityIds,
      relevantEvents: relevantEvents,
      relevantEntities: activeEntities,
      relevantRelations: relevantRelations,
      attentionSummary: attentionContext,
      procedureHints: procedureHints.isNotEmpty ? '[Triggered Procedures]\n$procedureHints' : '',
      totalTokenEstimate: _maxContextTokens - tokenBudget,
    );
  }

  List<MemoryEvent> _getRecentEvents() {
    if (_eventsProvider != null) {
      return _eventsProvider!();
    }
    return [];
  }

  bool _isRelevantToGoal(String goalTitle, String eventSummary) {
    final goalWords = goalTitle.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1).toSet();
    final eventWords = eventSummary.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1).toSet();
    return goalWords.intersection(eventWords).isNotEmpty;
  }
}
