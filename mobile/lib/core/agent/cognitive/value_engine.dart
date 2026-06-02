import 'cognitive_types.dart';
import 'entity_layer.dart';
import 'entity_store.dart';
import 'goal_store.dart';
import 'memory_event.dart';
import 'reasoning_engine.dart';

@Deprecated('DORMANT MODULE: ValueEngine is not part of the runtime cognitive pipeline. Do not call from main flow. Kept for future reactivation when Planning phase is implemented.')
class ValueAssessment {
  final String action;
  final double benefitScore;
  final double riskScore;
  final double costScore;
  final double consistencyScore;
  final double overallScore;
  final String recommendation;
  final List<String> riskFactors;
  final List<String> benefitFactors;

  const ValueAssessment({
    required this.action,
    this.benefitScore = 50,
    this.riskScore = 20,
    this.costScore = 30,
    this.consistencyScore = 70,
    this.overallScore = 50,
    this.recommendation = 'neutral',
    this.riskFactors = const [],
    this.benefitFactors = const [],
  });

  bool get isRecommended => overallScore >= 60;
  bool get isRisky => riskScore >= 60;
  bool get isCostly => costScore >= 60;
}

@Deprecated('DORMANT MODULE: ValueEngine is not part of the runtime cognitive pipeline. Do not call from main flow. Kept for future reactivation when Planning phase is implemented.')
class ValueEngine {
  final EntityStore entityStore;
  final GoalStore goalStore;

  ValueEngine({
    required this.entityStore,
    required this.goalStore,
  });

  ValueAssessment assess(String action, {List<ReasoningConclusion>? reasoning, List<MemoryEvent>? recentEvents}) {
    final benefit = _assessBenefit(action, reasoning: reasoning);
    final risk = _assessRisk(action, reasoning: reasoning, recentEvents: recentEvents);
    final cost = _assessCost(action);
    final consistency = _assessConsistency(action, recentEvents: recentEvents);

    final overall = _computeOverall(benefit.$1, risk.$1, cost.$1, consistency.$1);

    String recommendation;
    if (overall >= 75) {
      recommendation = 'strongly_recommended';
    } else if (overall >= 60) {
      recommendation = 'recommended';
    } else if (overall >= 40) {
      recommendation = 'neutral';
    } else if (overall >= 25) {
      recommendation = 'cautious';
    } else {
      recommendation = 'not_recommended';
    }

    return ValueAssessment(
      action: action,
      benefitScore: benefit.$1,
      riskScore: risk.$1,
      costScore: cost.$1,
      consistencyScore: consistency.$1,
      overallScore: overall,
      recommendation: recommendation,
      riskFactors: risk.$2,
      benefitFactors: benefit.$2,
    );
  }

  (double, List<String>) _assessBenefit(String action, {List<ReasoningConclusion>? reasoning}) {
    var score = 50.0;
    final factors = <String>[];

    final activeGoals = goalStore.getActiveGoals();
    for (final goal in activeGoals) {
      if (_isRelevantToAction(action, goal.title)) {
        score += 15;
        factors.add('推进目标: ${goal.title}');
      }
    }

    final overdueGoals = goalStore.getOverdueGoals();
    if (overdueGoals.isNotEmpty) {
      for (final goal in overdueGoals) {
        if (_isRelevantToAction(action, goal.title)) {
          score += 20;
          factors.add('解决逾期目标: ${goal.title}');
        }
      }
    }

    if (reasoning != null) {
      for (final conclusion in reasoning) {
        if (conclusion.type == ReasoningType.causation && conclusion.confidence > 60) {
          score += 10;
          factors.add('因果推理支持: ${conclusion.summary}');
        }
      }
    }

    return (score.clamp(0, 100), factors);
  }

  (double, List<String>) _assessRisk(String action, {List<ReasoningConclusion>? reasoning, List<MemoryEvent>? recentEvents}) {
    var score = 10.0;
    final factors = <String>[];

    final blockedGoals = goalStore.getBlockedGoals();
    if (blockedGoals.isNotEmpty) {
      for (final goal in blockedGoals) {
        if (_isRelevantToAction(action, goal.title)) {
          score += 25;
          factors.add('目标被阻塞: ${goal.title}');
        }
      }
    }

    final highDepEntities = entityStore.entities.where((e) {
      final deps = entityStore.getRelationsFrom(e.id)
          .where((r) => r.type == RelationType.dependsOn)
          .length;
      return deps > 3;
    }).toList();

    for (final entity in highDepEntities) {
      if (action.toLowerCase().contains(entity.name.toLowerCase())) {
        score += 15;
        factors.add('高耦合实体: ${entity.name}');
      }
    }

    if (reasoning != null) {
      for (final conclusion in reasoning) {
        if (conclusion.type == ReasoningType.contradiction) {
          score += 20;
          factors.add('存在矛盾: ${conclusion.summary}');
        }
        if (conclusion.type == ReasoningType.dependency && conclusion.confidence > 60) {
          score += 10;
          factors.add('依赖风险: ${conclusion.summary}');
        }
      }
    }

    if (recentEvents != null) {
      final recentErrors = recentEvents.where((e) =>
          e.memoryType == MemoryType.experience && e.importance >= 60).take(3);
      for (final error in recentErrors) {
        if (_isRelevantToAction(action, error.summary)) {
          score += 15;
          factors.add('历史经验: ${error.summary}');
        }
      }
    }

    return (score.clamp(0, 100), factors);
  }

  (double, List<String>) _assessCost(String action) {
    var score = 20.0;
    final factors = <String>[];

    final lower = action.toLowerCase();

    final highCostKeywords = ['重构', 'refactor', '重写', 'rewrite', '迁移', 'migrate', '替换', 'replace'];
    final mediumCostKeywords = ['修改', 'modify', '更新', 'update', '添加', 'add', '集成', 'integrate'];
    final lowCostKeywords = ['查看', 'view', '搜索', 'search', '读取', 'read', '显示', 'show'];

    for (final kw in highCostKeywords) {
      if (lower.contains(kw)) {
        score += 30;
        factors.add('高成本操作: $kw');
      }
    }
    for (final kw in mediumCostKeywords) {
      if (lower.contains(kw)) {
        score += 15;
        factors.add('中等成本操作: $kw');
      }
    }
    for (final kw in lowCostKeywords) {
      if (lower.contains(kw)) {
        score -= 10;
      }
    }

    return (score.clamp(0, 100), factors);
  }

  (double, List<String>) _assessConsistency(String action, {List<MemoryEvent>? recentEvents}) {
    var score = 80.0;
    final factors = <String>[];

    if (recentEvents == null) return (score, factors);

    final decisions = recentEvents.where((e) => e.memoryType == MemoryType.decision).toList();
    for (final decision in decisions) {
      if (_isContradictory(action, decision.summary)) {
        score -= 25;
        factors.add('与决策冲突: ${decision.summary}');
      } else if (_isRelevantToAction(action, decision.summary)) {
        score += 10;
        factors.add('与决策一致: ${decision.summary}');
      }
    }

    final rules = recentEvents.where((e) => e.memoryType == MemoryType.rule).toList();
    for (final rule in rules) {
      if (_violatesRule(action, rule.summary)) {
        score -= 30;
        factors.add('违反规则: ${rule.summary}');
      }
    }

    return (score.clamp(0, 100), factors);
  }

  double _computeOverall(double benefit, double risk, double cost, double consistency) {
    return (benefit * 0.35 + (100 - risk) * 0.25 + (100 - cost) * 0.15 + consistency * 0.25).clamp(0, 100);
  }

  bool _isRelevantToAction(String action, String target) {
    final actionWords = action.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1).toSet();
    final targetWords = target.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 1).toSet();
    return actionWords.intersection(targetWords).isNotEmpty;
  }

  bool _isContradictory(String action, String decision) {
    final contradictionPairs = [
      ['使用', '放弃'], ['采用', '移除'], ['添加', '删除'],
      ['use', 'abandon'], ['adopt', 'remove'], ['add', 'delete'],
    ];
    final lower = action.toLowerCase();
    final decisionLower = decision.toLowerCase();
    for (final pair in contradictionPairs) {
      if ((lower.contains(pair[0]) && decisionLower.contains(pair[1])) ||
          (lower.contains(pair[1]) && decisionLower.contains(pair[0]))) {
        return true;
      }
    }
    return false;
  }

  bool _violatesRule(String action, String rule) {
    final lower = action.toLowerCase();
    final ruleLower = rule.toLowerCase();
    if (ruleLower.contains('不要') || ruleLower.contains("don't") || ruleLower.contains('禁止')) {
      final forbidden = ruleLower.replaceAll(RegExp(r"(不要|don't|禁止|forbidden|must not)"), '').trim();
      if (forbidden.isNotEmpty && lower.contains(forbidden)) return true;
    }
    return false;
  }

  String buildValueContext(ValueAssessment assessment) {
    final buffer = StringBuffer();
    buffer.writeln('[Value Assessment: ${assessment.action}]');
    buffer.writeln('- Benefit: ${assessment.benefitScore.toStringAsFixed(0)}/100');
    buffer.writeln('- Risk: ${assessment.riskScore.toStringAsFixed(0)}/100');
    buffer.writeln('- Cost: ${assessment.costScore.toStringAsFixed(0)}/100');
    buffer.writeln('- Consistency: ${assessment.consistencyScore.toStringAsFixed(0)}/100');
    buffer.writeln('- Overall: ${assessment.overallScore.toStringAsFixed(0)}/100 (${assessment.recommendation})');
    if (assessment.riskFactors.isNotEmpty) {
      buffer.writeln('- Risk factors: ${assessment.riskFactors.join("; ")}');
    }
    return buffer.toString();
  }
}
