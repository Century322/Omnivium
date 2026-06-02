import '../stability/security.dart';
import 'runtime_law.dart';
import 'sandbox_runtime.dart';
import 'constitutional_trace.dart';

enum PolicyLoopholeSeverity { low, medium, high, critical }

class PolicyLoophole {
  final String loopholeId;
  final String description;
  final RuntimeLawId affectedLaw;
  final PolicyLoopholeSeverity severity;
  final int occurrenceCount;
  final List<String> affectedSandboxIds;
  final List<String> affectedCapabilityIds;
  final String suggestedFix;
  final int detectedAt;

  const PolicyLoophole({
    required this.loopholeId,
    required this.description,
    required this.affectedLaw,
    required this.severity,
    required this.occurrenceCount,
    required this.affectedSandboxIds,
    required this.affectedCapabilityIds,
    required this.suggestedFix,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': loopholeId,
    'desc': description,
    'law': affectedLaw.name,
    'severity': severity.name,
    'count': occurrenceCount,
    'sandboxes': affectedSandboxIds,
    'caps': affectedCapabilityIds,
    'fix': suggestedFix,
    'detected': detectedAt,
  };
}

class ConstitutionalAmendment {
  final String amendmentId;
  final String description;
  final RuntimeLawId targetLaw;
  final String rationale;
  final String proposedChange;
  final ConstitutionalAmendmentStatus status;
  final int proposedAt;
  final int? enactedAt;
  final int supportVotes;
  final int opposeVotes;

  const ConstitutionalAmendment({
    required this.amendmentId,
    required this.description,
    required this.targetLaw,
    required this.rationale,
    required this.proposedChange,
    required this.status,
    required this.proposedAt,
    this.enactedAt,
    this.supportVotes = 0,
    this.opposeVotes = 0,
  });

  ConstitutionalAmendment copyWith({
    ConstitutionalAmendmentStatus? status,
    int? enactedAt,
    int? supportVotes,
    int? opposeVotes,
  }) => ConstitutionalAmendment(
    amendmentId: amendmentId,
    description: description,
    targetLaw: targetLaw,
    rationale: rationale,
    proposedChange: proposedChange,
    status: status ?? this.status,
    proposedAt: proposedAt,
    enactedAt: enactedAt ?? this.enactedAt,
    supportVotes: supportVotes ?? this.supportVotes,
    opposeVotes: opposeVotes ?? this.opposeVotes);

  Map<String, dynamic> toJson() => {
    'id': amendmentId,
    'desc': description,
    'law': targetLaw.name,
    'rationale': rationale,
    'change': proposedChange,
    'status': status.name,
    'proposed': proposedAt,
    'enacted': enactedAt,
    'support': supportVotes,
    'oppose': opposeVotes,
  };
}

enum ConstitutionalAmendmentStatus { proposed, underReview, enacted, rejected }

class ConstitutionalEvolutionEngine {
  final ConstitutionalTraceGraph _traceGraph;
  final List<PolicyLoophole> _loopholes = [];
  final List<ConstitutionalAmendment> _amendments = [];
  int _amendmentSeq = 0;

  ConstitutionalEvolutionEngine(this._traceGraph);

  List<PolicyLoophole> get loopholes => List.unmodifiable(_loopholes);
  List<ConstitutionalAmendment> get amendments =>
      List.unmodifiable(_amendments);

  List<PolicyLoophole> scanForLoopholes() {
    final stats = _traceGraph.computeStatistics();
    final newLoopholes = <PolicyLoophole>[];

    for (final entry in stats.violationCounts.entries) {
      final law = entry.key;
      final count = entry.value;

      PolicyLoopholeSeverity severity;
      if (count >= 20) {
        severity = PolicyLoopholeSeverity.critical;
      } else if (count >= 10) {
        severity = PolicyLoopholeSeverity.high;
      } else if (count >= 5) {
        severity = PolicyLoopholeSeverity.medium;
      } else {
        continue;
      }

      final violations = _traceGraph.violationsForLaw(law);
      final sandboxIds = violations.map((v) => v.sandboxId).toSet().toList();
      final capIds = violations
          .where((v) => v.capabilityId != null)
          .map((v) => v.capabilityId!)
          .cast<String>()
          .toSet()
          .toList();

      final existing = _loopholes.where((l) => l.affectedLaw == law).isNotEmpty;
      if (existing) continue;

      newLoopholes.add(
        PolicyLoophole(
          loopholeId: 'loophole-${law.name}-$count',
          description:
              'Law ${law.name} violated $count times across ${sandboxIds.length} sandboxes',
          affectedLaw: law,
          severity: severity,
          occurrenceCount: count,
          affectedSandboxIds: sandboxIds,
          affectedCapabilityIds: capIds,
          suggestedFix: _suggestFix(law, count, sandboxIds.length),
          detectedAt: violations.last.timestamp));
    }

    if (stats.complianceRate < 0.5 && stats.totalDecisions > 10) {
      final alreadyExists = _loopholes.any(
        (l) => l.loopholeId == 'systemic-low-compliance');
      if (!alreadyExists) {
        newLoopholes.add(
          PolicyLoophole(
            loopholeId: 'systemic-low-compliance',
            description:
                'System compliance rate is ${(stats.complianceRate * 100).toStringAsFixed(1)}% — below 50% threshold',
            affectedLaw: RuntimeLawId.noBypassCapabilityRouter,
            severity: PolicyLoopholeSeverity.critical,
            occurrenceCount: stats.totalViolations,
            affectedSandboxIds: stats.mostDangerousSandboxes(),
            affectedCapabilityIds: stats.mostAbusedCapabilities(),
            suggestedFix:
                'Review and strengthen policy enforcement; consider reducing trust levels for high-violation plugins',
            detectedAt: _traceGraph.decisions.last.timestamp));
      }
    }

    _loopholes.addAll(newLoopholes);
    return newLoopholes;
  }

  ConstitutionalAmendment proposeAmendment({
    required String description,
    required RuntimeLawId targetLaw,
    required String rationale,
    required String proposedChange,
    required int timestamp,
  }) {
    final amendment = ConstitutionalAmendment(
      amendmentId: 'amendment-${_amendmentSeq++}',
      description: description,
      targetLaw: targetLaw,
      rationale: rationale,
      proposedChange: proposedChange,
      status: ConstitutionalAmendmentStatus.proposed,
      proposedAt: timestamp);
    _amendments.add(amendment);
    return amendment;
  }

  ConstitutionalAmendment reviewAmendment(
    String amendmentId, {
    bool approve = false,
  }) {
    final idx = _amendments.indexWhere((a) => a.amendmentId == amendmentId);
    if (idx < 0) throw StateError('Amendment $amendmentId not found');

    final current = _amendments[idx];
    final updated = current.copyWith(
      status: approve
          ? ConstitutionalAmendmentStatus.enacted
          : ConstitutionalAmendmentStatus.rejected,
      enactedAt: approve
          ? _traceGraph.decisions.lastOrNull?.timestamp ?? 0
          : null);
    _amendments[idx] = updated;
    return updated;
  }

  List<ConstitutionalAmendment> autoProposeFromLoopholes(int timestamp) {
    final proposals = <ConstitutionalAmendment>[];

    for (final loophole in _loopholes) {
      if (loophole.severity == PolicyLoopholeSeverity.critical ||
          loophole.severity == PolicyLoopholeSeverity.high) {
        final alreadyProposed = _amendments.any(
          (a) =>
              a.targetLaw == loophole.affectedLaw &&
              a.status != ConstitutionalAmendmentStatus.rejected);
        if (!alreadyProposed) {
          proposals.add(
            proposeAmendment(
              description: 'Auto-proposed fix for ${loophole.affectedLaw.name}',
              targetLaw: loophole.affectedLaw,
              rationale: loophole.description,
              proposedChange: loophole.suggestedFix,
              timestamp: timestamp));
        }
      }
    }

    return proposals;
  }

  String _suggestFix(RuntimeLawId law, int count, int sandboxCount) {
    switch (law) {
      case RuntimeLawId.noBypassCapabilityRouter:
        return 'Enforce stricter CapabilityRouter gating for $sandboxCount sandboxes; consider reducing allowed capabilities';
      case RuntimeLawId.noBypassScheduler:
        return 'Add Scheduler proof requirement for all task creation paths';
      case RuntimeLawId.noGlobalStateSharing:
        return 'Implement state isolation audit for $sandboxCount sandboxes';
      case RuntimeLawId.noSideChannels:
        return 'Deploy side-channel detection for all inter-sandbox communication';
      case RuntimeLawId.noUntracedOperations:
        return 'Add mandatory trace span injection at execution entry points';
      case RuntimeLawId.noBudgetBypass:
        return 'Reduce budget limits for high-violation sandboxes; add budget proof requirement';
      case RuntimeLawId.noDirectThreadCreation:
        return 'Block all direct isolate/thread spawn outside Scheduler';
      case RuntimeLawId.allOpsMustBeJournaled:
        return 'Add journal enforcement at WAL level';
      case RuntimeLawId.allOpsMustBeTraced:
        return 'Add trace proof requirement at all operation entry points';
      case RuntimeLawId.trustLevelMustBeRespected:
        return 'Review trust level assignments for $sandboxCount sandboxes; consider downgrading';
    }
  }
}

class ReputationScore {
  final String entityId;
  final double score;
  final int totalInteractions;
  final int violations;
  final int compliantActions;
  final double complianceRatio;
  final TrustLevel effectiveTrustLevel;
  final int lastUpdated;

  const ReputationScore({
    required this.entityId,
    required this.score,
    required this.totalInteractions,
    required this.violations,
    required this.compliantActions,
    required this.complianceRatio,
    required this.effectiveTrustLevel,
    required this.lastUpdated,
  });

  ReputationScore copyWith({
    double? score,
    int? totalInteractions,
    int? violations,
    int? compliantActions,
    double? complianceRatio,
    TrustLevel? effectiveTrustLevel,
    int? lastUpdated,
  }) => ReputationScore(
    entityId: entityId,
    score: score ?? this.score,
    totalInteractions: totalInteractions ?? this.totalInteractions,
    violations: violations ?? this.violations,
    compliantActions: compliantActions ?? this.compliantActions,
    complianceRatio: complianceRatio ?? this.complianceRatio,
    effectiveTrustLevel: effectiveTrustLevel ?? this.effectiveTrustLevel,
    lastUpdated: lastUpdated ?? this.lastUpdated);

  Map<String, dynamic> toJson() => {
    'entity': entityId,
    'score': score.toStringAsFixed(2),
    'interactions': totalInteractions,
    'violations': violations,
    'compliant': compliantActions,
    'ratio': complianceRatio.toStringAsFixed(3),
    'trust': effectiveTrustLevel.name,
    'updated': lastUpdated,
  };
}

class TrustDecayPolicy {
  final double decayRate;
  final double minimumScore;
  final double violationPenalty;
  final double complianceReward;
  final Duration decayInterval;

  const TrustDecayPolicy({
    this.decayRate = 0.01,
    this.minimumScore = 0.0,
    this.violationPenalty = 5.0,
    this.complianceReward = 0.1,
    this.decayInterval = const Duration(hours: 1),
  });
}

class ReputationEconomy {
  final TrustDecayPolicy _policy;
  final Map<String, ReputationScore> _scores = {};
  final ConstitutionalTraceGraph _traceGraph;

  ReputationEconomy(this._traceGraph, {TrustDecayPolicy? policy})
    : _policy = policy ?? const TrustDecayPolicy();

  Map<String, ReputationScore> get scores => Map.unmodifiable(_scores);
  TrustDecayPolicy get policy => _policy;

  ReputationScore scoreFor(String entityId) =>
      _scores[entityId] ??
      ReputationScore(
        entityId: entityId,
        score: 100.0,
        totalInteractions: 0,
        violations: 0,
        compliantActions: 0,
        complianceRatio: 1.0,
        effectiveTrustLevel: TrustLevel.verified,
        lastUpdated: 0);

  ReputationScore recordCompliance(String entityId, int timestamp) {
    final current = scoreFor(entityId);
    final newScore = (current.score + _policy.complianceReward).clamp(
      0.0,
      100.0);
    final newCompliant = current.compliantActions + 1;
    final newTotal = current.totalInteractions + 1;
    final ratio = newCompliant / newTotal;

    final updated = current.copyWith(
      score: newScore,
      totalInteractions: newTotal,
      compliantActions: newCompliant,
      complianceRatio: ratio,
      effectiveTrustLevel: _computeTrustLevel(newScore),
      lastUpdated: timestamp);
    _scores[entityId] = updated;
    return updated;
  }

  ReputationScore recordViolation(
    String entityId,
    int timestamp, {
    SandboxViolationType? type,
  }) {
    final current = scoreFor(entityId);
    final penalty = _penaltyForType(type);
    final newScore = (current.score - penalty).clamp(
      _policy.minimumScore,
      100.0);
    final newViolations = current.violations + 1;
    final newTotal = current.totalInteractions + 1;
    final newCompliant = current.compliantActions;
    final ratio = newTotal > 0 ? newCompliant / newTotal : 0.0;

    final updated = current.copyWith(
      score: newScore,
      totalInteractions: newTotal,
      violations: newViolations,
      complianceRatio: ratio,
      effectiveTrustLevel: _computeTrustLevel(newScore),
      lastUpdated: timestamp);
    _scores[entityId] = updated;
    return updated;
  }

  ReputationScore applyDecay(String entityId, int timestamp) {
    final current = scoreFor(entityId);
    final newScore = (current.score - _policy.decayRate).clamp(
      _policy.minimumScore,
      100.0);

    final updated = current.copyWith(
      score: newScore,
      effectiveTrustLevel: _computeTrustLevel(newScore),
      lastUpdated: timestamp);
    _scores[entityId] = updated;
    return updated;
  }

  double constitutionalScore() {
    if (_scores.isEmpty) return 100.0;
    final totalScore = _scores.values
        .map((s) => s.score)
        .reduce((a, b) => a + b);
    return totalScore / _scores.length;
  }

  List<String> lowestReputationEntities({int limit = 5}) {
    final sorted = _scores.values.toList()
      ..sort((a, b) => a.score.compareTo(b.score));
    return sorted.take(limit).map((e) => e.entityId).toList();
  }

  List<String> highestReputationEntities({int limit = 5}) {
    final sorted = _scores.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(limit).map((e) => e.entityId).toList();
  }

  void syncFromTraceGraph() {
    for (final decision in _traceGraph.decisions) {
      final entityId = decision.callerId ?? decision.sandboxId;
      if (decision.compliant) {
        recordCompliance(entityId, decision.timestamp);
      } else {
        recordViolation(entityId, decision.timestamp);
      }
    }
  }

  double _penaltyForType(SandboxViolationType? type) {
    if (type == null) return _policy.violationPenalty;
    switch (type) {
      case SandboxViolationType.bypassAttempt:
        return _policy.violationPenalty * 3;
      case SandboxViolationType.trustInsufficient:
        return _policy.violationPenalty * 2;
      case SandboxViolationType.executionTimeExceeded:
      case SandboxViolationType.memoryExceeded:
        return _policy.violationPenalty * 2;
      default:
        return _policy.violationPenalty;
    }
  }

  TrustLevel _computeTrustLevel(double score) {
    if (score >= 90) return TrustLevel.system;
    if (score >= 70) return TrustLevel.signed;
    if (score >= 50) return TrustLevel.verified;
    if (score >= 20) return TrustLevel.untrusted;
    return TrustLevel.blocked;
  }
}

enum SanctionType { warning, restriction, suspension, termination }

class Sanction {
  final String sanctionId;
  final String sandboxId;
  final SanctionType type;
  final String reason;
  final RuntimeLawId? violatedLaw;
  final int imposedAt;
  final int? liftedAt;
  final bool isReversible;

  const Sanction({
    required this.sanctionId,
    required this.sandboxId,
    required this.type,
    required this.reason,
    this.violatedLaw,
    required this.imposedAt,
    this.liftedAt,
    this.isReversible = true,
  });

  Sanction copyWith({int? liftedAt}) => Sanction(
    sanctionId: sanctionId,
    sandboxId: sandboxId,
    type: type,
    reason: reason,
    violatedLaw: violatedLaw,
    imposedAt: imposedAt,
    liftedAt: liftedAt ?? this.liftedAt,
    isReversible: isReversible);

  bool get isActive => liftedAt == null;
  bool get isLifted => liftedAt != null;

  Map<String, dynamic> toJson() => {
    'id': sanctionId,
    'sandbox': sandboxId,
    'type': type.name,
    'reason': reason,
    'law': violatedLaw?.name,
    'imposed': imposedAt,
    'lifted': liftedAt,
    'reversible': isReversible,
  };
}

class Appeal {
  final String appealId;
  final String sandboxId;
  final String sanctionId;
  final String grounds;
  final String evidence;
  final AppealStatus status;
  final int filedAt;
  final int? resolvedAt;
  final String? resolution;

  const Appeal({
    required this.appealId,
    required this.sandboxId,
    required this.sanctionId,
    required this.grounds,
    required this.evidence,
    required this.status,
    required this.filedAt,
    this.resolvedAt,
    this.resolution,
  });

  Appeal copyWith({
    AppealStatus? status,
    int? resolvedAt,
    String? resolution,
  }) => Appeal(
    appealId: appealId,
    sandboxId: sandboxId,
    sanctionId: sanctionId,
    grounds: grounds,
    evidence: evidence,
    status: status ?? this.status,
    filedAt: filedAt,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    resolution: resolution ?? this.resolution);

  Map<String, dynamic> toJson() => {
    'id': appealId,
    'sandbox': sandboxId,
    'sanction': sanctionId,
    'grounds': grounds,
    'evidence': evidence,
    'status': status.name,
    'filed': filedAt,
    'resolved': resolvedAt,
    'resolution': resolution,
  };
}

enum AppealStatus {
  filed,
  underReview,
  upheld,
  overturned,
  partiallyOverturned,
}

class RuntimeJudiciary {
  final List<Sanction> _sanctions = [];
  final List<Appeal> _appeals = [];
  final ConstitutionalTraceGraph _traceGraph;
  final ImmutableAuditLedger _ledger;
  int _sanctionSeq = 0;
  int _appealSeq = 0;

  RuntimeJudiciary(this._traceGraph, this._ledger);

  List<Sanction> get sanctions => List.unmodifiable(_sanctions);
  List<Appeal> get appeals => List.unmodifiable(_appeals);

  List<Sanction> activeSanctionsFor(String sandboxId) =>
      _sanctions.where((s) => s.sandboxId == sandboxId && s.isActive).toList();

  Sanction imposeSanction({
    required String sandboxId,
    required SanctionType type,
    required String reason,
    RuntimeLawId? violatedLaw,
    required int timestamp,
    bool isReversible = true,
  }) {
    final sanction = Sanction(
      sanctionId: 'sanction-${_sanctionSeq++}',
      sandboxId: sandboxId,
      type: type,
      reason: reason,
      violatedLaw: violatedLaw,
      imposedAt: timestamp,
      isReversible: isReversible);
    _sanctions.add(sanction);

    _ledger.append(
      entryType: 'sanction.imposed',
      sandboxId: sandboxId,
      data: {
        'sanctionId': sanction.sanctionId,
        'type': type.name,
        'reason': reason,
      },
      timestamp: timestamp);

    return sanction;
  }

  Sanction? liftSanction(String sanctionId, int timestamp) {
    final idx = _sanctions.indexWhere((s) => s.sanctionId == sanctionId);
    if (idx < 0) return null;

    final current = _sanctions[idx];
    if (!current.isReversible) return null;
    if (!current.isActive) return null;

    final lifted = current.copyWith(liftedAt: timestamp);
    _sanctions[idx] = lifted;

    _ledger.append(
      entryType: 'sanction.lifted',
      sandboxId: lifted.sandboxId,
      data: {'sanctionId': sanctionId, 'originalType': current.type.name},
      timestamp: timestamp);

    return lifted;
  }

  Appeal fileAppeal({
    required String sandboxId,
    required String sanctionId,
    required String grounds,
    required String evidence,
    required int timestamp,
  }) {
    final appeal = Appeal(
      appealId: 'appeal-${_appealSeq++}',
      sandboxId: sandboxId,
      sanctionId: sanctionId,
      grounds: grounds,
      evidence: evidence,
      status: AppealStatus.filed,
      filedAt: timestamp);
    _appeals.add(appeal);

    _ledger.append(
      entryType: 'appeal.filed',
      sandboxId: sandboxId,
      data: {
        'appealId': appeal.appealId,
        'sanctionId': sanctionId,
        'grounds': grounds,
      },
      timestamp: timestamp);

    return appeal;
  }

  Appeal reviewAppeal(
    String appealId, {
    bool overturn = false,
    bool partial = false,
    int? timestamp,
  }) {
    final idx = _appeals.indexWhere((a) => a.appealId == appealId);
    if (idx < 0) throw StateError('Appeal $appealId not found');

    final current = _appeals[idx];
    final ts = timestamp ?? _traceGraph.decisions.lastOrNull?.timestamp ?? 0;

    AppealStatus status;
    String resolution;

    if (overturn && partial) {
      status = AppealStatus.partiallyOverturned;
      resolution = 'Sanction partially overturned on appeal';
    } else if (overturn) {
      status = AppealStatus.overturned;
      resolution = 'Sanction overturned on appeal';
      final sanctionIdx = _sanctions.indexWhere(
        (s) => s.sanctionId == current.sanctionId);
      if (sanctionIdx >= 0 && _sanctions[sanctionIdx].isReversible) {
        _sanctions[sanctionIdx] = _sanctions[sanctionIdx].copyWith(
          liftedAt: ts);
      }
    } else {
      status = AppealStatus.upheld;
      resolution = 'Sanction upheld on review';
    }

    final updated = current.copyWith(
      status: status,
      resolvedAt: ts,
      resolution: resolution);
    _appeals[idx] = updated;

    _ledger.append(
      entryType: 'appeal.resolved',
      sandboxId: current.sandboxId,
      data: {
        'appealId': appealId,
        'status': status.name,
        'resolution': resolution,
      },
      timestamp: ts);

    return updated;
  }

  bool isSanctioned(String sandboxId) =>
      _sanctions.any((s) => s.sandboxId == sandboxId && s.isActive);

  SanctionType? highestActiveSanction(String sandboxId) {
    final active = activeSanctionsFor(sandboxId);
    if (active.isEmpty) return null;
    return active
        .map((s) => s.type)
        .reduce((a, b) => a.index > b.index ? a : b);
  }

  List<LawDecisionRecord> gatherEvidence(String sandboxId) =>
      _traceGraph.violationsForSandbox(sandboxId);
}
