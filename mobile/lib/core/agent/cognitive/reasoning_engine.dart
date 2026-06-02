import 'cognitive_types.dart';
import 'entity_store.dart';
import 'goal_store.dart';
import 'memory_event.dart';
import 'perception_engine.dart';
import 'working_memory.dart';

class ReasoningConclusion {
  final String summary;
  final ReasoningType type;
  final double confidence;
  final List<String> evidence;
  final List<String> implications;
  final Map<String, dynamic> properties;

  const ReasoningConclusion({
    required this.summary,
    required this.type,
    this.confidence = 50,
    this.evidence = const [],
    this.implications = const [],
    this.properties = const {},
  });
}

enum ReasoningType {
  deduction,
  induction,
  analogy,
  causation,
  contradiction,
  dependency,
}

class ReasoningEngine {
  final EntityStore entityStore;
  final GoalStore goalStore;
  final WorkingMemory workingMemory;

  ReasoningEngine({
    required this.entityStore,
    required this.goalStore,
    required this.workingMemory,
  });

  List<ReasoningConclusion> reason(String message, PerceptionResult perception, List<MemoryEvent> recentEvents) {
    final conclusions = <ReasoningConclusion>[];

    conclusions.addAll(_reasonFromEntities(perception));
    conclusions.addAll(_reasonFromGoals(perception));
    conclusions.addAll(_reasonFromDependencies(perception));
    conclusions.addAll(_reasonFromHistory(recentEvents, perception));
    conclusions.addAll(_reasonFromContradictions(recentEvents, perception));

    conclusions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return conclusions.take(5).toList();
  }

  List<ReasoningConclusion> _reasonFromEntities(PerceptionResult perception) {
    final conclusions = <ReasoningConclusion>[];

    for (final entityName in perception.detectedEntities) {
      final entity = entityStore.getEntityByName(entityName);
      if (entity == null) continue;

      final relations = entityStore.getRelatedEntities(entity.id);
      if (relations.isEmpty) continue;

      final relationDesc = relations.map((r) => '${r.name}(${r.type.name})').join(', ');
      conclusions.add(ReasoningConclusion(
        summary: '$entityName 与 ${relations.length} 个实体相关: $relationDesc',
        type: ReasoningType.deduction,
        confidence: 70,
        evidence: ['entity:${entity.id}', 'relations:${relations.length}'],
        implications: ['用户提到 $entityName 时可能涉及相关实体'],
      ));

      final subGraph = entityStore.extractSubGraph(entity.id, radius: 2);
      final blockedEntities = subGraph.relations
          .where((r) => r.type == RelationType.blocks)
          .toList();
      if (blockedEntities.isNotEmpty) {
        final blockedNames = blockedEntities.map((r) {
          final from = subGraph.entities.where((e) => e.id == r.fromEntityId).firstOrNull;
          final to = subGraph.entities.where((e) => e.id == r.toEntityId).firstOrNull;
          return '${from?.name ?? "?"} blocks ${to?.name ?? "?"}';
        }).join(', ');
        conclusions.add(ReasoningConclusion(
          summary: '存在阻塞关系: $blockedNames',
          type: ReasoningType.causation,
          confidence: 75,
          evidence: blockedEntities.map((r) => 'relation:${r.id}').toList(),
          implications: ['需要解决阻塞才能推进'],
        ));
      }
    }

    return conclusions;
  }

  List<ReasoningConclusion> _reasonFromGoals(PerceptionResult perception) {
    final conclusions = <ReasoningConclusion>[];

    final activeGoals = goalStore.getActiveGoals();
    final overdueGoals = goalStore.getOverdueGoals();

    if (overdueGoals.isNotEmpty) {
      final titles = overdueGoals.map((g) => g.title).join(', ');
      conclusions.add(ReasoningConclusion(
        summary: '存在逾期目标: $titles',
        type: ReasoningType.causation,
        confidence: 90,
        evidence: overdueGoals.map((g) => 'goal:${g.id}').toList(),
        implications: ['逾期目标可能需要优先处理', '可能影响其他依赖目标'],
      ));
    }

    final blockedGoals = goalStore.getBlockedGoals();
    if (blockedGoals.isNotEmpty) {
      final titles = blockedGoals.map((g) => '${g.title}(${g.blockers.join(",")})').join(', ');
      conclusions.add(ReasoningConclusion(
        summary: '存在被阻塞的目标: $titles',
        type: ReasoningType.dependency,
        confidence: 85,
        evidence: blockedGoals.map((g) => 'goal:${g.id}').toList(),
        implications: ['需要先解除阻塞因素'],
      ));
    }

    for (final goal in activeGoals) {
      if (goal.progress > 0 && goal.progress < 100) {
        final subGoals = goalStore.getSubGoals(goal.id);
        final completedSubs = subGoals.where((s) => s.status == GoalStatus.completed).length;
        if (subGoals.isNotEmpty && completedSubs > 0) {
          conclusions.add(ReasoningConclusion(
            summary: '目标"${goal.title}"进度${goal.progress}%，$completedSubs/${subGoals.length}子目标已完成',
            type: ReasoningType.induction,
            confidence: 65,
            evidence: ['goal:${goal.id}', 'subGoals:${subGoals.length}', 'completed:$completedSubs'],
            implications: ['可推算完成时间', '剩余子目标可能需要关注'],
          ));
        }
      }
    }

    return conclusions;
  }

  List<ReasoningConclusion> _reasonFromDependencies(PerceptionResult perception) {
    final conclusions = <ReasoningConclusion>[];

    for (final entityName in perception.detectedEntities) {
      final entity = entityStore.getEntityByName(entityName);
      if (entity == null) continue;

      final paths = entityStore.findPaths(entity.id, entity.id, maxDepth: 3);
      if (paths.length > 1) {
        conclusions.add(ReasoningConclusion(
          summary: '$entityName 存在 ${paths.length} 条循环依赖路径',
          type: ReasoningType.dependency,
          confidence: 60,
          evidence: ['circular_dependency:${entity.name}'],
          implications: ['循环依赖可能导致问题', '需要检查架构合理性'],
        ));
      }

      final deps = entityStore.getRelationsFrom(entity.id)
          .where((r) => r.type == RelationType.dependsOn)
          .toList();
      if (deps.length > 3) {
        conclusions.add(ReasoningConclusion(
          summary: '$entityName 依赖 ${deps.length} 个其他实体，耦合度较高',
          type: ReasoningType.deduction,
          confidence: 70,
          evidence: deps.map((d) => 'dep:${d.toEntityId}').toList(),
          implications: ['高耦合可能导致维护困难', '修改时需注意影响范围'],
        ));
      }
    }

    return conclusions;
  }

  List<ReasoningConclusion> _reasonFromHistory(List<MemoryEvent> recentEvents, PerceptionResult perception) {
    final conclusions = <ReasoningConclusion>[];

    final recentDecisions = recentEvents.where((e) => e.memoryType == MemoryType.decision).toList();
    if (recentDecisions.length >= 2) {
      final lastDecision = recentDecisions.first;
      conclusions.add(ReasoningConclusion(
        summary: '最近决策: ${lastDecision.summary}',
        type: ReasoningType.deduction,
        confidence: 60,
        evidence: ['event:${lastDecision.id}'],
        implications: ['当前对话可能受此决策影响'],
      ));
    }

    final recentGoals = recentEvents.where((e) => e.memoryType == MemoryType.goal).toList();
    if (recentGoals.isNotEmpty) {
      final latestGoal = recentGoals.first;
      conclusions.add(ReasoningConclusion(
        summary: '最近目标: ${latestGoal.summary}',
        type: ReasoningType.induction,
        confidence: 55,
        evidence: ['event:${latestGoal.id}'],
        implications: ['用户可能仍在追求此目标'],
      ));
    }

    return conclusions;
  }

  List<ReasoningConclusion> _reasonFromContradictions(List<MemoryEvent> recentEvents, PerceptionResult perception) {
    final conclusions = <ReasoningConclusion>[];

    final preferences = recentEvents.where((e) => e.memoryType == MemoryType.preference).toList();
    for (var i = 0; i < preferences.length; i++) {
      for (var j = i + 1; j < preferences.length; j++) {
        final a = preferences[i];
        final b = preferences[j];
        if (a.domain == b.domain && a.summary.toLowerCase() != b.summary.toLowerCase()) {
          final similarity = _textSimilarity(a.summary, b.summary);
          if (similarity > 0.3 && similarity < 0.8) {
            conclusions.add(ReasoningConclusion(
              summary: '可能存在矛盾偏好: "${a.summary}" vs "${b.summary}"',
              type: ReasoningType.contradiction,
              confidence: 50,
              evidence: ['event:${a.id}', 'event:${b.id}'],
              implications: ['需要确认用户真实意图', '可能偏好已改变'],
            ));
          }
        }
      }
    }

    return conclusions;
  }

  double _textSimilarity(String a, String b) {
    final wordsA = a.toLowerCase().split(RegExp(r'\s+')).toSet();
    final wordsB = b.toLowerCase().split(RegExp(r'\s+')).toSet();
    if (wordsA.isEmpty || wordsB.isEmpty) return 0;
    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;
    return union > 0 ? intersection / union : 0;
  }

  String buildReasoningContext(List<ReasoningConclusion> conclusions) {
    if (conclusions.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Reasoning]');
    for (final c in conclusions) {
      buffer.writeln('- [${c.type.name}] ${c.summary} (confidence: ${c.confidence.toStringAsFixed(0)}%)');
    }
    return buffer.toString();
  }
}
