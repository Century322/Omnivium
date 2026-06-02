import 'cognitive_types.dart';
import 'entity_layer.dart';
import 'entity_store.dart';
import 'goal_runtime.dart';
import 'goal_store.dart';
import 'memory_event.dart';

class Prediction {
  final String description;
  final PredictionType type;
  final double probability;
  final DateTime? estimatedTime;
  final List<String> basedOn;
  final String? suggestedAction;

  const Prediction({
    required this.description,
    required this.type,
    this.probability = 50,
    this.estimatedTime,
    this.basedOn = const [],
    this.suggestedAction,
  });
}

enum PredictionType {
  goalCompletion,
  goalFailure,
  entityStateChange,
  risk,
  opportunity,
  deadline,
}

class PredictionEngine {
  final EntityStore entityStore;
  final GoalStore goalStore;

  PredictionEngine({
    required this.entityStore,
    required this.goalStore,
  });

  List<Prediction> predict({String? workspaceId}) {
    final predictions = <Prediction>[];

    predictions.addAll(_predictGoalOutcomes(workspaceId));
    predictions.addAll(_predictDeadlines(workspaceId));
    predictions.addAll(_predictEntityStateChanges(workspaceId));
    predictions.addAll(_predictRisks(workspaceId));
    predictions.addAll(_predictOpportunities(workspaceId));

    predictions.sort((a, b) => b.probability.compareTo(a.probability));
    return predictions.take(8).toList();
  }

  List<Prediction> _predictGoalOutcomes(String? workspaceId) {
    final predictions = <Prediction>[];

    final activeGoals = goalStore.getActiveGoals(workspaceId: workspaceId);
    for (final goal in activeGoals) {
      if (goal.status != GoalStatus.inProgress) continue;

      final subGoals = goalStore.getSubGoals(goal.id);
      if (subGoals.isEmpty) continue;

      final completedSubs = subGoals.where((s) => s.status == GoalStatus.completed).length;
      final totalSubs = subGoals.length;
      final completionRate = completedSubs / totalSubs;

      if (completionRate > 0.7) {
        final remaining = totalSubs - completedSubs;
        predictions.add(Prediction(
          description: '目标"${goal.title}"即将完成 ($completedSubs/$totalSubs 子目标已完成)',
          type: PredictionType.goalCompletion,
          probability: 60 + completionRate * 30,
          basedOn: ['goal:${goal.id}', 'completion_rate:${completionRate.toStringAsFixed(2)}'],
          suggestedAction: '关注剩余 $remaining 个子目标的完成',
        ));
      } else if (completionRate < 0.3 && goal.isOverdue) {
        predictions.add(Prediction(
          description: '目标"${goal.title}"可能无法按时完成 (仅 $completedSubs/$totalSubs 完成，已逾期)',
          type: PredictionType.goalFailure,
          probability: 70 + (1 - completionRate) * 20,
          basedOn: ['goal:${goal.id}', 'overdue:true', 'completion_rate:${completionRate.toStringAsFixed(2)}'],
          suggestedAction: '重新评估目标可行性，考虑调整范围或截止日期',
        ));
      } else if (completionRate < 0.3) {
        predictions.add(Prediction(
          description: '目标"${goal.title}"进度缓慢 ($completedSubs/$totalSubs)',
          type: PredictionType.goalFailure,
          probability: 40 + (1 - completionRate) * 20,
          basedOn: ['goal:${goal.id}', 'completion_rate:${completionRate.toStringAsFixed(2)}'],
          suggestedAction: '检查是否有阻塞因素，考虑分解为更小的子目标',
        ));
      }
    }

    return predictions;
  }

  List<Prediction> _predictDeadlines(String? workspaceId) {
    final predictions = <Prediction>[];
    final now = DateTime.now();

    final activeGoals = goalStore.getActiveGoals(workspaceId: workspaceId);
    for (final goal in activeGoals) {
      if (goal.deadline == null) continue;
      if (goal.status == GoalStatus.completed) continue;

      final daysUntilDeadline = goal.deadline!.difference(now).inDays;

      if (daysUntilDeadline <= 0) {
        predictions.add(Prediction(
          description: '目标"${goal.title}"已逾期 ${-daysUntilDeadline} 天',
          type: PredictionType.deadline,
          probability: 95,
          estimatedTime: goal.deadline,
          basedOn: ['goal:${goal.id}', 'days_overdue:${-daysUntilDeadline}'],
          suggestedAction: '立即处理或重新设定截止日期',
        ));
      } else if (daysUntilDeadline <= 3) {
        predictions.add(Prediction(
          description: '目标"${goal.title}"将在 $daysUntilDeadline 天内到期',
          type: PredictionType.deadline,
          probability: 80,
          estimatedTime: goal.deadline,
          basedOn: ['goal:${goal.id}', 'days_remaining:$daysUntilDeadline'],
          suggestedAction: '优先完成此目标',
        ));
      } else if (daysUntilDeadline <= 7 && goal.progress < 50) {
        predictions.add(Prediction(
          description: '目标"${goal.title}"进度${goal.progress}%但仅剩 $daysUntilDeadline 天',
          type: PredictionType.deadline,
          probability: 65,
          estimatedTime: goal.deadline,
          basedOn: ['goal:${goal.id}', 'days_remaining:$daysUntilDeadline', 'progress:${goal.progress}'],
          suggestedAction: '加快进度或调整范围',
        ));
      }
    }

    return predictions;
  }

  List<Prediction> _predictEntityStateChanges(String? workspaceId) {
    final predictions = <Prediction>[];

    for (final entity in entityStore.entities) {
      if (entity.lifecycle != MemoryLifecycle.active) continue;
      if (workspaceId != null && entity.workspaceId != workspaceId) continue;

      final relations = entityStore.getRelationsFrom(entity.id);
      final blockingRelations = relations.where((r) => r.type == RelationType.blocks).toList();

      if (blockingRelations.isNotEmpty) {
        final blockedNames = <String>[];
        for (final r in blockingRelations) {
          final blocked = entityStore.getEntity(r.toEntityId);
          if (blocked != null) blockedNames.add(blocked.name);
        }
        if (blockedNames.isNotEmpty) {
          predictions.add(Prediction(
            description: '${entity.name} 正在阻塞: ${blockedNames.join(", ")}',
            type: PredictionType.entityStateChange,
            probability: 70,
            basedOn: ['entity:${entity.id}', 'blocking:${blockedNames.length}'],
            suggestedAction: '解决 ${entity.name} 的阻塞状态以推进其他实体',
          ));
        }
      }

      final stateHistory = entityStore.getStateHistory(entity.id);
      if (stateHistory.length >= 2) {
        final recent = stateHistory.take(2).toList();
        if (recent.length == 2) {
          final timeDiff = recent[0].since.difference(recent[1].since).inDays;
          if (timeDiff < 3) {
            predictions.add(Prediction(
              description: '${entity.name} 状态频繁变化 (${recent[1].state} → ${recent[0].state})',
              type: PredictionType.entityStateChange,
              probability: 55,
              basedOn: ['entity:${entity.id}', 'state_changes:${stateHistory.length}'],
              suggestedAction: '关注 ${entity.name} 的稳定性',
            ));
          }
        }
      }
    }

    return predictions;
  }

  List<Prediction> _predictRisks(String? workspaceId) {
    final predictions = <Prediction>[];

    final blockedGoals = goalStore.getBlockedGoals();
    if (blockedGoals.isNotEmpty) {
      predictions.add(Prediction(
        description: '${blockedGoals.length} 个目标被阻塞，可能影响整体进度',
        type: PredictionType.risk,
        probability: 75,
        basedOn: ['blocked_goals:${blockedGoals.length}'],
        suggestedAction: '优先解除阻塞因素',
      ));
    }

    final highDepEntities = entityStore.entities.where((e) {
      final deps = entityStore.getRelationsFrom(e.id)
          .where((r) => r.type == RelationType.dependsOn)
          .length;
      return deps > 3;
    }).toList();

    if (highDepEntities.length >= 2) {
      predictions.add(Prediction(
        description: '${highDepEntities.length} 个实体存在高耦合，修改可能引发连锁影响',
        type: PredictionType.risk,
        probability: 60,
        basedOn: highDepEntities.map((e) => 'entity:${e.id}').toList(),
        suggestedAction: '考虑解耦或制定变更影响分析',
      ));
    }

    return predictions;
  }

  List<Prediction> _predictOpportunities(String? workspaceId) {
    final predictions = <Prediction>[];

    final nearCompleteGoals = goalStore.getActiveGoals(workspaceId: workspaceId)
        .where((g) => g.progress >= 80 && g.progress < 100)
        .toList();

    for (final goal in nearCompleteGoals) {
      predictions.add(Prediction(
        description: '目标"${goal.title}"已完成 ${goal.progress}%，即将达成',
        type: PredictionType.opportunity,
        probability: 80,
        basedOn: ['goal:${goal.id}', 'progress:${goal.progress}'],
        suggestedAction: '集中精力完成最后 ${100 - goal.progress}%',
      ));
    }

    final activeEntities = entityStore.entities
        .where((e) => e.lifecycle == MemoryLifecycle.active)
        .toList();

    if (activeEntities.length >= 3) {
      final names = activeEntities.take(3).map((e) => e.name).join(', ');
      predictions.add(Prediction(
        description: '高重要性实体活跃: $names，可能存在协同机会',
        type: PredictionType.opportunity,
        probability: 50,
        basedOn: activeEntities.take(3).map((e) => 'entity:${e.id}').toList(),
        suggestedAction: '检查这些实体之间是否可以建立新的关联',
      ));
    }

    return predictions;
  }

  String buildPredictionContext(List<Prediction> predictions) {
    if (predictions.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Predictions]');
    for (final p in predictions) {
      buffer.writeln('- [${p.type.name}] ${p.description} (probability: ${p.probability.toStringAsFixed(0)}%)');
      if (p.suggestedAction != null) {
        buffer.writeln('  → ${p.suggestedAction}');
      }
    }
    return buffer.toString();
  }
}
