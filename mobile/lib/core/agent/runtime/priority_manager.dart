import '../cognitive/cognitive_types.dart';
import '../cognitive/entity_store.dart';
import '../cognitive/goal_runtime.dart';
import '../cognitive/goal_store.dart';
import '../cognitive/memory_event.dart';
import 'agent_runtime.dart';

class PriorityItem {
  final String id;
  final String type;
  final String description;
  final double score;
  final String reason;

  const PriorityItem({
    required this.id,
    required this.type,
    required this.description,
    required this.score,
    required this.reason,
  });
}

class PriorityManager {
  final GoalStore goalStore;
  final EntityStore entityStore;

  PriorityManager({required this.goalStore, required this.entityStore});

  List<PriorityItem> prioritizeGoals({String? workspaceId}) {
    final goals = goalStore.getActiveGoals(workspaceId: workspaceId);
    final items = <PriorityItem>[];

    for (final goal in goals) {
      var score = goal.priority.toDouble();
      String reason = '基础优先级: ${goal.priority}';

      if (goal.isOverdue) {
        score += 30;
        reason += ' + 逾期加成: 30';
      }

      if (goal.progress > 0 && goal.progress < 100) {
        score += 15;
        reason += ' + 进行中加成: 15';
      }

      if (goal.progress >= 80) {
        score += 20;
        reason += ' + 即将完成加成: 20';
      }

      final blockedGoals = goalStore.getBlockedGoals();
      if (blockedGoals.any((b) => b.dependencies.contains(goal.id))) {
        score += 25;
        reason += ' + 阻塞他人加成: 25';
      }

      final daysLeft = goal.deadline?.difference(DateTime.now()).inDays;
      if (daysLeft != null && daysLeft <= 3 && daysLeft > 0) {
        score += 20;
        reason += ' + 即将到期加成: 20';
      }

      items.add(PriorityItem(
        id: goal.id,
        type: 'goal',
        description: goal.title,
        score: score,
        reason: reason,
      ));
    }

    items.sort((a, b) => b.score.compareTo(a.score));
    return items;
  }

  TaskPriority mapToTaskPriority(double score) {
    if (score >= 90) return TaskPriority.critical;
    if (score >= 70) return TaskPriority.urgent;
    if (score >= 50) return TaskPriority.high;
    if (score >= 30) return TaskPriority.normal;
    return TaskPriority.low;
  }

  List<PriorityItem> prioritizeEntities({String? workspaceId}) {
    final entities = entityStore.entities
        .where((e) => e.lifecycle == MemoryLifecycle.active)
        .toList();
    final items = <PriorityItem>[];

    for (final entity in entities) {
      var score = 50.0;
      String reason = '';

      final relations = entityStore.getRelationsFrom(entity.id);
      final blockingCount = relations.where((r) => r.type == RelationType.blocks).length;
      if (blockingCount > 0) {
        score += blockingCount * 15;
        reason += '阻塞${blockingCount}个实体';
      }

      final depCount = relations.where((r) => r.type == RelationType.dependsOn).length;
      if (depCount > 3) {
        score += 10;
        reason += '${reason.isNotEmpty ? ", " : ""}高耦合($depCount依赖)';
      }

      final daysSinceAccess = DateTime.now().difference(entity.lastAccessedAt).inDays;
      if (daysSinceAccess < 1) {
        score += 20;
        reason += '${reason.isNotEmpty ? ", " : ""}近期活跃';
      }

      items.add(PriorityItem(
        id: entity.id,
        type: 'entity',
        description: entity.name,
        score: score,
        reason: reason.isNotEmpty ? reason : '基础优先级',
      ));
    }

    items.sort((a, b) => b.score.compareTo(a.score));
    return items;
  }

  String buildPriorityContext({String? workspaceId}) {
    final goalPriorities = prioritizeGoals(workspaceId: workspaceId);
    if (goalPriorities.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Priority Queue]');
    for (final item in goalPriorities.take(5)) {
      buffer.writeln('- [${item.type}] ${item.description} (score: ${item.score.toStringAsFixed(0)}, ${item.reason})');
    }
    return buffer.toString();
  }
}
