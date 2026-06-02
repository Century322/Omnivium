import 'cognitive_types.dart';
import 'entity_layer.dart';
import 'entity_store.dart';
import 'goal_runtime.dart';
import 'goal_store.dart';
import 'memory_event.dart';
import 'working_memory.dart';

class AttentionFocus {
  final String focusType;
  final String focusId;
  final String label;
  final double score;
  final DateTime focusedAt;

  const AttentionFocus({
    required this.focusType,
    required this.focusId,
    required this.label,
    required this.score,
    required this.focusedAt,
  });
}

class AttentionEngine {
  final WorkingMemory workingMemory;
  final EntityStore entityStore;
  final GoalStore goalStore;

  AttentionEngine({
    required this.workingMemory,
    required this.entityStore,
    required this.goalStore,
  });

  List<AttentionFocus> computeAttention({String? workspaceId}) {
    final focuses = <AttentionFocus>[];
    final now = DateTime.now();

    for (final goal in goalStore.getActiveGoals(workspaceId: workspaceId)) {
      if (goal.status == GoalStatus.inProgress) {
        final urgency = goal.isOverdue ? 2.0 : 1.0;
        final priorityFactor = goal.priority / 100.0;
        focuses.add(AttentionFocus(
          focusType: 'goal',
          focusId: goal.id,
          label: goal.title,
          score: urgency * priorityFactor * 30,
          focusedAt: now,
        ));
      }
    }

    for (final entityId in workingMemory.activeEntityIds) {
      final entity = entityStore.getEntity(entityId);
      if (entity == null) continue;
      final recency = 1.0 / (1.0 + now.difference(entity.lastAccessedAt).inHours * 0.05);
      focuses.add(AttentionFocus(
        focusType: 'entity',
        focusId: entity.id,
        label: entity.name,
        score: recency * 20,
        focusedAt: now,
      ));
    }

    for (final item in workingMemory.items.take(10)) {
      focuses.add(AttentionFocus(
        focusType: 'memory',
        focusId: item.id,
        label: item.content.length > 50 ? '${item.content.substring(0, 50)}...' : item.content,
        score: item.relevanceScore * 15 + item.importance * 0.1,
        focusedAt: item.lastAccessedAt,
      ));
    }

    focuses.sort((a, b) => b.score.compareTo(a.score));
    return focuses.take(10).toList();
  }

  void updateWorkingMemory(String message, {String? workspaceId}) {
    workingMemory.setWorkspace(workspaceId);

    final recentEntities = entityStore.entities
        .where((e) => e.lifecycle == MemoryLifecycle.active)
        .toList()
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));

    for (final entity in recentEntities.take(5)) {
      workingMemory.addEntity(entity.id);
    }

    final activeGoals = goalStore.getActiveGoals(workspaceId: workspaceId);
    for (final goal in activeGoals.take(3)) {
      workingMemory.addGoal(goal.id);
    }

    workingMemory.addItem(WorkingMemoryItem(
      id: 'wm_${DateTime.now().millisecondsSinceEpoch}_${message.hashCode.abs()}',
      content: message,
      type: MemoryType.fact,
      importance: 50,
      addedAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      relevanceScore: 1.0,
    ));
  }

  String buildAttentionContext({String? workspaceId}) {
    final focuses = computeAttention(workspaceId: workspaceId);
    if (focuses.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Current Attention]');
    for (final focus in focuses) {
      buffer.writeln('- [${focus.focusType}] ${focus.label} (score: ${focus.score.toStringAsFixed(1)})');
    }
    return buffer.toString();
  }
}
