import 'dart:convert';
import '../../app_logger.dart';
import '../../database_service.dart';
import '../cognitive/cognitive_types.dart';
import '../cognitive/entity_store.dart';
import '../cognitive/goal_store.dart';
import '../cognitive/goal_runtime.dart';
import '../cognitive/memory_event.dart';
import '../cognitive/memory_transaction.dart';

class IdentityClaim {
  final String id;
  final String claim;
  final String category;
  final DateTime claimedAt;
  final double confidence;

  const IdentityClaim({
    required this.id,
    required this.claim,
    required this.category,
    required this.claimedAt,
    this.confidence = 80,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'claim': claim, 'category': category,
    'claimedAt': claimedAt.toIso8601String(), 'confidence': confidence,
  };

  factory IdentityClaim.fromJson(Map<String, dynamic> json) => IdentityClaim(
    id: json['id'] as String,
    claim: json['claim'] as String,
    category: json['category'] as String,
    claimedAt: DateTime.parse(json['claimedAt'] as String),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 80,
  );
}

class IdentityBehavior {
  final String id;
  final String behavior;
  final String category;
  final DateTime observedAt;
  final String sourceEventId;
  final double consistency;

  const IdentityBehavior({
    required this.id,
    required this.behavior,
    required this.category,
    required this.observedAt,
    required this.sourceEventId,
    this.consistency = 50,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'behavior': behavior, 'category': category,
    'observedAt': observedAt.toIso8601String(), 'sourceEventId': sourceEventId,
    'consistency': consistency,
  };

  factory IdentityBehavior.fromJson(Map<String, dynamic> json) => IdentityBehavior(
    id: json['id'] as String,
    behavior: json['behavior'] as String,
    category: json['category'] as String,
    observedAt: DateTime.parse(json['observedAt'] as String),
    sourceEventId: json['sourceEventId'] as String,
    consistency: (json['consistency'] as num?)?.toDouble() ?? 50,
  );
}

class IdentityEvidence {
  final String id;
  final String claimId;
  final String description;
  final bool supports;
  final double weight;
  final DateTime observedAt;
  final String sourceEventId;

  const IdentityEvidence({
    required this.id,
    required this.claimId,
    required this.description,
    required this.supports,
    this.weight = 1.0,
    required this.observedAt,
    required this.sourceEventId,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'claimId': claimId, 'description': description,
    'supports': supports, 'weight': weight,
    'observedAt': observedAt.toIso8601String(), 'sourceEventId': sourceEventId,
  };

  factory IdentityEvidence.fromJson(Map<String, dynamic> json) => IdentityEvidence(
    id: json['id'] as String,
    claimId: json['claimId'] as String,
    description: json['description'] as String,
    supports: json['supports'] as bool,
    weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
    observedAt: DateTime.parse(json['observedAt'] as String),
    sourceEventId: json['sourceEventId'] as String,
  );
}

class IdentityConsistency {
  final String category;
  final String claim;
  final String? actualBehavior;
  final double consistencyScore;
  final String assessment;
  final double supportScore;
  final double opposeScore;

  const IdentityConsistency({
    required this.category,
    required this.claim,
    this.actualBehavior,
    required this.consistencyScore,
    required this.assessment,
    this.supportScore = 0,
    this.opposeScore = 0,
  });
}

class IdentityModel {
  final String userId;
  List<IdentityClaim> claims;
  List<IdentityBehavior> behaviors;
  List<IdentityEvidence> evidences;
  DateTime lastUpdated;

  IdentityModel({
    required this.userId,
    this.claims = const [],
    this.behaviors = const [],
    this.evidences = const [],
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'claims': claims.map((c) => c.toJson()).toList(),
    'behaviors': behaviors.map((b) => b.toJson()).toList(),
    'evidences': evidences.map((e) => e.toJson()).toList(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory IdentityModel.fromJson(Map<String, dynamic> json) => IdentityModel(
    userId: json['userId'] as String,
    claims: (json['claims'] as List<dynamic>?)?.map((e) => IdentityClaim.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    behaviors: (json['behaviors'] as List<dynamic>?)?.map((e) => IdentityBehavior.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    evidences: (json['evidences'] as List<dynamic>?)?.map((e) => IdentityEvidence.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated'] as String) : DateTime.now(),
  );
}

class IdentityEngine {
  static const _identityKey = 'cognitive_identity';

  final EntityStore entityStore;
  final GoalStore goalStore;
  final DatabaseService _db;

  IdentityModel? _model;
  bool _initialized = false;
  bool _dirty = false;

  IdentityEngine({required this.entityStore, required this.goalStore, required DatabaseService db}) : _db = db;

  IdentityModel? get model => _model;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final json = await _db.getCache(_identityKey);
      if (json != null) {
        _model = IdentityModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } else {
        _model = IdentityModel(userId: 'default_user');
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('IdentityEngine init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persist() async {
    if (_model == null || !_dirty) return;
    _dirty = false;
    try {
      _model!.lastUpdated = DateTime.now();
      await _db.putCache(_identityKey, jsonEncode(_model!.toJson()));
    } catch (e, st) {
      AppLogger.instance.error('IdentityEngine persist failed', error: e, stackTrace: st);
    }
  }

  void _markDirty() => _dirty = true;

  void registerWithTransaction(MemoryTransaction tx) {
    if (!_dirty || _model == null) return;
    _model!.lastUpdated = DateTime.now();
    tx.register(_identityKey, () => jsonEncode(_model!.toJson()));
    _dirty = false;
  }

  Future<void> processClaim(MemoryEvent event) async {
    if (_model == null) return;
    if (event.memoryType != MemoryType.fact && event.memoryType != MemoryType.preference) return;

    final claim = _extractClaim(event);
    if (claim == null) return;

    final existing = _model!.claims.where((c) => c.category == claim.category).toList();
    if (existing.isNotEmpty) {
      final idx = _model!.claims.indexOf(existing.first);
      _model!.claims[idx] = IdentityClaim(
        id: existing.first.id,
        claim: claim.claim,
        category: claim.category,
        claimedAt: DateTime.now(),
        confidence: (existing.first.confidence + 5).clamp(0, 100),
      );
    } else {
      _model!.claims.add(claim);
    }

    _markDirty();
  }

  Future<void> recordBehavior(MemoryEvent event) async {
    if (_model == null) return;

    final behavior = _extractBehavior(event);
    if (behavior != null) {
      _model!.behaviors.add(behavior);
      if (_model!.behaviors.length > 100) {
        _model!.behaviors = _model!.behaviors.skip(_model!.behaviors.length - 100).toList();
      }
    }

    for (final claim in _model!.claims) {
      final evidence = _extractEvidence(event, claim);
      if (evidence != null) {
        _model!.evidences.add(evidence);
        if (_model!.evidences.length > 200) {
          _model!.evidences = _model!.evidences.skip(_model!.evidences.length - 200).toList();
        }
      }
    }

    _markDirty();
  }

  IdentityEvidence? _extractEvidence(MemoryEvent event, IdentityClaim claim) {
    final summary = event.summary.toLowerCase();
    final claimLower = claim.claim.toLowerCase();

    final categoryKeywords = _categoryKeywords[claim.category] ?? {};
    final positiveWords = categoryKeywords['positive'] ?? <String>[];
    final negativeWords = categoryKeywords['negative'] ?? <String>[];

    bool? supports;
    for (final w in positiveWords) {
      if (summary.contains(w)) { supports = true; break; }
    }
    if (supports == null) {
      for (final w in negativeWords) {
        if (summary.contains(w)) { supports = false; break; }
      }
    }

    if (supports == null) return null;

    final claimIsPositive = positiveWords.any((w) => claimLower.contains(w));
    final evidenceSupportsClaim = (claimIsPositive && supports) || (!claimIsPositive && !supports);

    return IdentityEvidence(
      id: 'ev_${DateTime.now().millisecondsSinceEpoch}_${event.id.hashCode.abs()}',
      claimId: claim.id,
      description: event.summary,
      supports: evidenceSupportsClaim,
      weight: event.importance / 100.0,
      observedAt: DateTime.now(),
      sourceEventId: event.id,
    );
  }

  static const _categoryKeywords = <String, Map<String, List<String>>>{
    'work_style': {
      'positive': ['勤奋', '努力', '认真', '完成', 'hardworking', 'diligent', 'done', 'completed', '实现', '交付', '上线'],
      'negative': ['懒', '拖延', '放弃', 'lazy', 'procrastinate', 'abandon', 'quit', '推迟', '延期', '搁置'],
    },
    'social': {
      'positive': ['外向', '社交', 'extrovert', '聊天', '分享', '讨论'],
      'negative': ['内向', '安静', 'introvert', '独处', '沉默'],
    },
    'tech_preference': {
      'positive': ['喜欢', '偏好', '简洁', 'like', 'prefer', 'love'],
      'negative': ['讨厌', '不喜欢', '复杂', 'hate', 'dislike'],
    },
    'schedule': {
      'positive': ['早起', '准时', 'early bird', '按时'],
      'negative': ['夜猫', '迟到', 'night owl', '拖延'],
    },
  };

  List<IdentityConsistency> analyzeConsistency() {
    if (_model == null) return [];

    final results = <IdentityConsistency>[];

    for (final claim in _model!.claims) {
      final claimEvidences = _model!.evidences.where((e) => e.claimId == claim.id).toList();
      final relatedBehaviors = _model!.behaviors.where((b) => b.category == claim.category).toList();

      if (claimEvidences.isEmpty && relatedBehaviors.isEmpty) {
        final absenceScore = _computeAbsenceScore(claim);
        String assessment;
        if (absenceScore < 30) {
          assessment = '言行不一致：声称${claim.claim}但长期无相关行为';
        } else if (absenceScore < 50) {
          assessment = '缺乏行为支撑：无相关行为数据验证';
        } else {
          assessment = '无行为数据验证';
        }

        results.add(IdentityConsistency(
          category: claim.category,
          claim: claim.claim,
          consistencyScore: absenceScore,
          assessment: assessment,
        ));
        continue;
      }

      if (claimEvidences.isEmpty) {
        final matchingBehaviors = relatedBehaviors.where((b) => _isConsistent(claim.claim, b.behavior)).toList();
        final behaviorScore = relatedBehaviors.isNotEmpty
            ? (matchingBehaviors.length / relatedBehaviors.length * 100)
            : 50.0;

        final absencePenalty = _computeAbsencePenalty(claim);
        final finalScore = (behaviorScore * (1 - absencePenalty)).clamp(0.0, 100.0).toDouble();

        String assessment;
        if (finalScore >= 80) {
          assessment = '言行一致';
        } else if (finalScore >= 50) {
          assessment = '部分一致';
        } else {
          assessment = '言行不一致';
        }

        results.add(IdentityConsistency(
          category: claim.category,
          claim: claim.claim,
          actualBehavior: relatedBehaviors.last.behavior,
          consistencyScore: finalScore,
          assessment: assessment,
        ));
        continue;
      }

      final supportScore = claimEvidences.where((e) => e.supports).fold(0.0, (sum, e) => sum + e.weight);
      final opposeScore = claimEvidences.where((e) => !e.supports).fold(0.0, (sum, e) => sum + e.weight);
      final totalScore = supportScore + opposeScore;
      var consistencyScore = totalScore > 0 ? (supportScore / totalScore * 100) : 50.0;

      final absencePenalty = _computeAbsencePenalty(claim);
      consistencyScore = (consistencyScore * (1 - absencePenalty)).clamp(0.0, 100.0).toDouble();

      String assessment;
      if (consistencyScore >= 80) {
        assessment = '证据支持';
      } else if (consistencyScore >= 50) {
        assessment = '部分证据支持';
      } else {
        assessment = '证据矛盾';
      }

      results.add(IdentityConsistency(
        category: claim.category,
        claim: claim.claim,
        actualBehavior: claimEvidences.last.description,
        consistencyScore: consistencyScore,
        assessment: assessment,
        supportScore: supportScore,
        opposeScore: opposeScore,
      ));
    }

    return results;
  }

  double _computeAbsenceScore(IdentityClaim claim) {
    final now = DateTime.now();
    final claimAge = now.difference(claim.claimedAt).inDays;

    if (claimAge < 7) return 50.0;

    final goalEvidence = _analyzeGoalProgress(claim);

    if (goalEvidence.hasGoals) {
      if (goalEvidence.completionRate <= 0.1 && claimAge >= 14) return 10.0;
      if (goalEvidence.completionRate <= 0.1 && claimAge >= 30) return 5.0;
      if (goalEvidence.completionRate <= 0.3 && claimAge >= 30) return 20.0;
      if (goalEvidence.completionRate >= 0.7) return 70.0;
      if (goalEvidence.completionRate >= 0.5) return 50.0;
      return 30.0;
    }

    final categoryBehaviors = _model!.behaviors.where((b) => b.category == claim.category).toList();
    final recentBehaviors = categoryBehaviors.where((b) =>
      now.difference(b.observedAt).inDays <= claimAge
    ).length;

    if (recentBehaviors == 0 && claimAge >= 30) return 40.0;
    if (recentBehaviors == 0 && claimAge >= 14) return 45.0;

    return 50.0;
  }

  double _computeAbsencePenalty(IdentityClaim claim) {
    final now = DateTime.now();
    final claimAge = now.difference(claim.claimedAt).inDays;

    if (claimAge < 7) return 0.0;

    final goalEvidence = _analyzeGoalProgress(claim);

    if (goalEvidence.hasGoals) {
      if (goalEvidence.completionRate <= 0.1 && claimAge >= 30) return 0.7;
      if (goalEvidence.completionRate <= 0.1 && claimAge >= 14) return 0.4;
      if (goalEvidence.completionRate <= 0.3 && claimAge >= 30) return 0.3;
      if (goalEvidence.completionRate >= 0.7) return 0.0;
      return 0.1;
    }

    final recentBehaviors = _model!.behaviors.where((b) =>
      b.category == claim.category && now.difference(b.observedAt).inDays <= claimAge
    ).length;

    if (recentBehaviors == 0 && claimAge >= 30) return 0.2;
    if (recentBehaviors == 0 && claimAge >= 14) return 0.1;

    return 0.0;
  }

  _GoalEvidence _analyzeGoalProgress(IdentityClaim claim) {
    final activeGoals = goalStore.getActiveGoals();
    final now = DateTime.now();

    final relevantGoals = <GoalNode>[];
    for (final goal in activeGoals) {
      if (_isGoalRelevantToClaim(goal, claim)) {
        relevantGoals.add(goal);
      }
    }

    if (relevantGoals.isEmpty) {
      return _GoalEvidence(hasGoals: false, completionRate: 0, totalGoals: 0, overdueCount: 0);
    }

    final totalProgress = relevantGoals.fold<int>(0, (sum, g) => sum + g.progress);
    final completionRate = totalProgress / (relevantGoals.length * 100);
    final overdueCount = relevantGoals.where((g) => g.isOverdue).length;

    return _GoalEvidence(
      hasGoals: true,
      completionRate: completionRate,
      totalGoals: relevantGoals.length,
      overdueCount: overdueCount,
    );
  }

  bool _isGoalRelevantToClaim(GoalNode goal, IdentityClaim claim) {
    final titleLower = goal.title.toLowerCase();

    switch (claim.category) {
      case 'work_style':
        return true;
      case 'social':
        return titleLower.contains('社交') || titleLower.contains('分享') ||
            titleLower.contains('沟通') || titleLower.contains('social') ||
            titleLower.contains('connect');
      case 'tech_preference':
        return titleLower.contains('学习') || titleLower.contains('开发') ||
            titleLower.contains('技术') || titleLower.contains('learn') ||
            titleLower.contains('build') || titleLower.contains('tech');
      case 'schedule':
        return titleLower.contains('早起') || titleLower.contains('习惯') ||
            titleLower.contains('作息') || titleLower.contains('routine') ||
            titleLower.contains('schedule');
      default:
        return true;
    }
  }

  IdentityClaim? _extractClaim(MemoryEvent event) {
    final summary = event.summary.toLowerCase();
    final categories = <String, List<String>>{
      'work_style': ['勤奋', '努力', '认真', 'hardworking', 'diligent', 'lazy', '懒', '拖延'],
      'social': ['外向', '内向', 'extrovert', 'introvert', '社交', '安静'],
      'tech_preference': ['flutter', 'react', 'python', 'rust', '简洁', '详细'],
      'schedule': ['早起', '夜猫', 'early bird', 'night owl', '准时', '迟到'],
    };

    for (final entry in categories.entries) {
      for (final kw in entry.value) {
        if (summary.contains(kw)) {
          return IdentityClaim(
            id: 'claim_${DateTime.now().millisecondsSinceEpoch}',
            claim: event.summary,
            category: entry.key,
            claimedAt: DateTime.now(),
            confidence: event.confidence.toDouble(),
          );
        }
      }
    }
    return null;
  }

  IdentityBehavior? _extractBehavior(MemoryEvent event) {
    if (event.memoryType == MemoryType.decision || event.memoryType == MemoryType.goal) {
      final category = _inferBehaviorCategory(event);
      return IdentityBehavior(
        id: 'beh_${DateTime.now().millisecondsSinceEpoch}',
        behavior: event.summary,
        category: category,
        observedAt: DateTime.now(),
        sourceEventId: event.id,
        consistency: 70,
      );
    }
    return null;
  }

  String _inferBehaviorCategory(MemoryEvent event) {
    final summary = event.summary.toLowerCase();
    final categoryMap = <String, List<String>>{
      'work_style': ['完成', '实现', '交付', '上线', 'done', 'completed', '推迟', '延期', '搁置', '放弃', 'abandon', 'quit'],
      'social': ['讨论', '分享', '聊天', '讨论', '独处', '沉默'],
      'tech_preference': ['flutter', 'react', 'python', 'rust', '选择', '决定', '采用'],
      'schedule': ['早起', '夜猫', '准时', '迟到', '按时'],
    };

    for (final entry in categoryMap.entries) {
      for (final kw in entry.value) {
        if (summary.contains(kw)) return entry.key;
      }
    }
    return 'action';
  }

  bool _isConsistent(String claim, String behavior) {
    final claimLower = claim.toLowerCase();
    final behaviorLower = behavior.toLowerCase();

    final positiveWords = ['勤奋', '努力', '认真', '完成', 'hardworking', 'diligent', 'done', 'completed'];
    final negativeWords = ['懒', '拖延', '放弃', 'lazy', 'procrastinate', 'abandon', 'quit'];

    var claimPositive = false;
    var claimNegative = false;
    for (final w in positiveWords) { if (claimLower.contains(w)) claimPositive = true; }
    for (final w in negativeWords) { if (claimLower.contains(w)) claimNegative = true; }

    var behaviorPositive = false;
    var behaviorNegative = false;
    for (final w in positiveWords) { if (behaviorLower.contains(w)) behaviorPositive = true; }
    for (final w in negativeWords) { if (behaviorLower.contains(w)) behaviorNegative = true; }

    if (claimPositive && behaviorPositive) return true;
    if (claimNegative && behaviorNegative) return true;
    if (claimPositive && behaviorNegative) return false;
    if (claimNegative && behaviorPositive) return false;

    return true;
  }

  String buildIdentityContext() {
    if (_model == null || _model!.claims.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[User Identity]');

    final consistency = analyzeConsistency();
    for (final c in consistency.take(5)) {
      buffer.write('- ${c.category}: claims "${c.claim}" → ${c.assessment} (${c.consistencyScore.toStringAsFixed(0)}%)');
      if (c.supportScore > 0 || c.opposeScore > 0) {
        buffer.write(' [support=${c.supportScore.toStringAsFixed(1)}, oppose=${c.opposeScore.toStringAsFixed(1)}]');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}

class _GoalEvidence {
  final bool hasGoals;
  final double completionRate;
  final int totalGoals;
  final int overdueCount;

  const _GoalEvidence({
    required this.hasGoals,
    required this.completionRate,
    required this.totalGoals,
    required this.overdueCount,
  });
}
