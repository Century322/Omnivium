import 'dart:convert';
import '../../app_logger.dart';
import '../../database_service.dart';
import '../cognitive/cognitive_types.dart';
import '../cognitive/entity_store.dart';
import '../cognitive/goal_store.dart';
import '../cognitive/memory_event.dart';
import '../cognitive/memory_transaction.dart';

enum ConflictType {
  decisionContradiction,
  goalConflict,
  preferenceChange,
  ruleViolation,
  resourceContention,
}

enum ResolutionStrategy {
  latestWins,
  importanceWins,
  manualReview,
  merge,
  keepBoth,
}

class ConflictRecord {
  final String id;
  final ConflictType type;
  final String description;
  final String eventAId;
  final String eventBId;
  final ResolutionStrategy strategy;
  final String? winnerId;
  final String? resolution;
  final DateTime detectedAt;
  final bool resolved;

  const ConflictRecord({
    required this.id,
    required this.type,
    required this.description,
    required this.eventAId,
    required this.eventBId,
    required this.strategy,
    this.winnerId,
    this.resolution,
    required this.detectedAt,
    this.resolved = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name, 'description': description,
    'eventAId': eventAId, 'eventBId': eventBId, 'strategy': strategy.name,
    'winnerId': winnerId, 'resolution': resolution,
    'detectedAt': detectedAt.toIso8601String(), 'resolved': resolved,
  };

  factory ConflictRecord.fromJson(Map<String, dynamic> json) => ConflictRecord(
    id: json['id'] as String,
    type: ConflictType.values.byName(json['type'] as String),
    description: json['description'] as String,
    eventAId: json['eventAId'] as String,
    eventBId: json['eventBId'] as String,
    strategy: ResolutionStrategy.values.byName(json['strategy'] as String),
    winnerId: json['winnerId'] as String?,
    resolution: json['resolution'] as String?,
    detectedAt: DateTime.parse(json['detectedAt'] as String),
    resolved: json['resolved'] as bool? ?? false,
  );
}

class ConflictResolver {
  static const _conflictsKey = 'cognitive_conflicts';

  final EntityStore entityStore;
  final GoalStore goalStore;
  final DatabaseService _db;

  List<ConflictRecord> _conflicts = [];
  bool _initialized = false;
  bool _dirty = false;

  ConflictResolver({
    required this.entityStore,
    required this.goalStore,
    required DatabaseService db,
  }) : _db = db;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final json = await _db.getCache(_conflictsKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _conflicts = list.map((e) => ConflictRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('ConflictResolver init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persist() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      await _db.putCache(_conflictsKey, jsonEncode(_conflicts.map((c) => c.toJson()).toList()));
    } catch (e, st) {
      AppLogger.instance.error('ConflictResolver persist failed', error: e, stackTrace: st);
    }
  }

  void _markDirty() => _dirty = true;

  void registerWithTransaction(MemoryTransaction tx) {
    if (!_dirty) return;
    tx.register(_conflictsKey, () => jsonEncode(_conflicts.map((c) => c.toJson()).toList()));
    _dirty = false;
  }

  List<ConflictRecord> get conflicts => List.unmodifiable(_conflicts);
  List<ConflictRecord> get unresolvedConflicts => _conflicts.where((c) => !c.resolved).toList();

  List<ConflictRecord> detectConflicts(MemoryEvent newEvent, List<MemoryEvent> existingEvents) {
    final detected = <ConflictRecord>[];

    if (newEvent.memoryType == MemoryType.decision) {
      detected.addAll(_detectDecisionConflicts(newEvent, existingEvents));
    }
    if (newEvent.memoryType == MemoryType.preference) {
      detected.addAll(_detectPreferenceConflicts(newEvent, existingEvents));
    }
    if (newEvent.memoryType == MemoryType.rule) {
      detected.addAll(_detectRuleConflicts(newEvent, existingEvents));
    }
    if (newEvent.memoryType == MemoryType.goal) {
      detected.addAll(_detectGoalConflicts(newEvent));
    }

    _conflicts.addAll(detected);
    if (detected.isNotEmpty) _markDirty();
    return detected;
  }

  List<ConflictRecord> _detectDecisionConflicts(MemoryEvent newEvent, List<MemoryEvent> existingEvents) {
    final conflicts = <ConflictRecord>[];
    final newDomain = newEvent.domain;

    for (final existing in existingEvents) {
      if (existing.memoryType != MemoryType.decision) continue;
      if (existing.domain != newDomain) continue;
      if (existing.id == newEvent.id) continue;

      if (_isContradictory(newEvent.summary, existing.summary)) {
        conflicts.add(ConflictRecord(
          id: 'conflict_${DateTime.now().millisecondsSinceEpoch}',
          type: ConflictType.decisionContradiction,
          description: '决策冲突: "${existing.summary}" vs "${newEvent.summary}"',
          eventAId: existing.id,
          eventBId: newEvent.id,
          strategy: ResolutionStrategy.latestWins,
          detectedAt: DateTime.now(),
        ));
      }
    }
    return conflicts;
  }

  List<ConflictRecord> _detectPreferenceConflicts(MemoryEvent newEvent, List<MemoryEvent> existingEvents) {
    final conflicts = <ConflictRecord>[];
    final newEntity = newEvent.properties['entityName'] as String?;

    for (final existing in existingEvents) {
      if (existing.memoryType != MemoryType.preference) continue;
      final existingEntity = existing.properties['entityName'] as String?;
      if (newEntity == null || existingEntity == null) continue;
      if (newEntity.toLowerCase() != existingEntity.toLowerCase()) continue;

      if (_isOppositePreference(newEvent.summary, existing.summary)) {
        conflicts.add(ConflictRecord(
          id: 'conflict_${DateTime.now().millisecondsSinceEpoch}',
          type: ConflictType.preferenceChange,
          description: '偏好变化: "${existing.summary}" → "${newEvent.summary}"',
          eventAId: existing.id,
          eventBId: newEvent.id,
          strategy: ResolutionStrategy.latestWins,
          detectedAt: DateTime.now(),
        ));
      }
    }
    return conflicts;
  }

  List<ConflictRecord> _detectRuleConflicts(MemoryEvent newEvent, List<MemoryEvent> existingEvents) {
    final conflicts = <ConflictRecord>[];

    for (final existing in existingEvents) {
      if (existing.memoryType != MemoryType.rule) continue;
      if (_isContradictory(newEvent.summary, existing.summary)) {
        conflicts.add(ConflictRecord(
          id: 'conflict_${DateTime.now().millisecondsSinceEpoch}',
          type: ConflictType.ruleViolation,
          description: '规则冲突: "${existing.summary}" vs "${newEvent.summary}"',
          eventAId: existing.id,
          eventBId: newEvent.id,
          strategy: ResolutionStrategy.manualReview,
          detectedAt: DateTime.now(),
        ));
      }
    }
    return conflicts;
  }

  List<ConflictRecord> _detectGoalConflicts(MemoryEvent newEvent) {
    final conflicts = <ConflictRecord>[];
    final activeGoals = goalStore.getActiveGoals(workspaceId: newEvent.workspaceId);

    for (final goal in activeGoals) {
      if (_isResourceConflict(newEvent.summary, goal.title)) {
        conflicts.add(ConflictRecord(
          id: 'conflict_${DateTime.now().millisecondsSinceEpoch}',
          type: ConflictType.resourceContention,
          description: '资源冲突: 新目标"${newEvent.summary}"与现有目标"${goal.title}"可能争夺资源',
          eventAId: goal.id,
          eventBId: newEvent.id,
          strategy: ResolutionStrategy.importanceWins,
          detectedAt: DateTime.now(),
        ));
      }
    }
    return conflicts;
  }

  Future<ConflictRecord> resolveConflict(String conflictId, {String? resolution, String? winnerId}) async {
    final idx = _conflicts.indexWhere((c) => c.id == conflictId);
    if (idx < 0) throw StateError('Conflict not found: $conflictId');

    final conflict = _conflicts[idx];
    final resolved = ConflictRecord(
      id: conflict.id,
      type: conflict.type,
      description: conflict.description,
      eventAId: conflict.eventAId,
      eventBId: conflict.eventBId,
      strategy: conflict.strategy,
      winnerId: winnerId ?? _autoResolve(conflict),
      resolution: resolution ?? _generateResolution(conflict),
      detectedAt: conflict.detectedAt,
      resolved: true,
    );

    _conflicts[idx] = resolved;
    _markDirty();
    return resolved;
  }

  String? _autoResolve(ConflictRecord conflict) {
    switch (conflict.strategy) {
      case ResolutionStrategy.latestWins:
        return conflict.eventBId;
      case ResolutionStrategy.importanceWins:
        return null;
      case ResolutionStrategy.manualReview:
        return null;
      case ResolutionStrategy.merge:
        return null;
      case ResolutionStrategy.keepBoth:
        return null;
    }
  }

  String _generateResolution(ConflictRecord conflict) {
    switch (conflict.strategy) {
      case ResolutionStrategy.latestWins:
        return '采用最新决策';
      case ResolutionStrategy.importanceWins:
        return '按重要性决定';
      case ResolutionStrategy.manualReview:
        return '需要人工审核';
      case ResolutionStrategy.merge:
        return '合并两者';
      case ResolutionStrategy.keepBoth:
        return '保留两者';
    }
  }

  bool _isContradictory(String a, String b) {
    final pairs = [
      ['使用', '放弃'], ['采用', '移除'], ['添加', '删除'], ['开启', '关闭'],
      ['use', 'abandon'], ['adopt', 'remove'], ['add', 'delete'], ['enable', 'disable'],
      ['flutter', 'react native'], ['python', 'rust'],
    ];
    final lowerA = a.toLowerCase();
    final lowerB = b.toLowerCase();
    for (final pair in pairs) {
      if ((lowerA.contains(pair[0]) && lowerB.contains(pair[1])) ||
          (lowerA.contains(pair[1]) && lowerB.contains(pair[0]))) {
        return true;
      }
    }
    return false;
  }

  bool _isOppositePreference(String a, String b) {
    final opposites = [
      ['喜欢', '不喜欢'], ['偏好', '讨厌'], ['简洁', '详细'],
      ['like', 'dislike'], ['prefer', 'hate'], ['brief', 'detailed'],
    ];
    final lowerA = a.toLowerCase();
    final lowerB = b.toLowerCase();
    for (final pair in opposites) {
      if ((lowerA.contains(pair[0]) && lowerB.contains(pair[1])) ||
          (lowerA.contains(pair[1]) && lowerB.contains(pair[0]))) {
        return true;
      }
    }
    return false;
  }

  bool _isResourceConflict(String a, String b) {
    final conflictKeywords = ['重构', 'refactor', '重写', 'rewrite', '迁移', 'migrate'];
    final lowerA = a.toLowerCase();
    final lowerB = b.toLowerCase();
    for (final kw in conflictKeywords) {
      if (lowerA.contains(kw) && lowerB.contains(kw)) return true;
    }
    return false;
  }

  String buildConflictContext() {
    final unresolved = unresolvedConflicts;
    if (unresolved.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Unresolved Conflicts: ${unresolved.length}]');
    for (final c in unresolved.take(3)) {
      buffer.writeln('- ${c.description} (${c.strategy.name})');
    }
    return buffer.toString();
  }
}
