import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../stability/security.dart';
import 'runtime_law.dart';
import 'constitutional_trace.dart';
import 'constitutional_civilization.dart';

enum LawForkResolution { keepLocal, adoptRemote, merge, conflict }

class LawManifest {
  final String nodeId;
  final int epoch;
  final Map<RuntimeLawId, int> lawVersions;
  final int hash;

  const LawManifest({
    required this.nodeId,
    required this.epoch,
    required this.lawVersions,
    required this.hash,
  });

  factory LawManifest.forNode(String nodeId, int epoch) {
    final versions = <RuntimeLawId, int>{};
    for (final law in RuntimeConstitution.laws) {
      versions[law.id] = 1;
    }
    var hash = 0;
    for (final entry in versions.entries) {
      hash = ((hash << 5) - hash) + entry.key.index + entry.value;
      hash = hash & 0xFFFFFFFF;
    }
    return LawManifest(
      nodeId: nodeId,
      epoch: epoch,
      lawVersions: versions,
      hash: hash,
    );
  }

  LawManifest bumpVersion(RuntimeLawId lawId) {
    final newVersions = Map<RuntimeLawId, int>.from(lawVersions);
    newVersions[lawId] = (newVersions[lawId] ?? 0) + 1;
    var hash = 0;
    for (final entry in newVersions.entries) {
      hash = ((hash << 5) - hash) + entry.key.index + entry.value;
      hash = hash & 0xFFFFFFFF;
    }
    return LawManifest(
      nodeId: nodeId,
      epoch: epoch + 1,
      lawVersions: newVersions,
      hash: hash,
    );
  }

  bool isCompatibleWith(LawManifest other) {
    for (final lawId in RuntimeLawId.values) {
      final local = lawVersions[lawId] ?? 0;
      final remote = other.lawVersions[lawId] ?? 0;
      if (local != remote) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'node': nodeId,
    'epoch': epoch,
    'versions': lawVersions.map((k, v) => MapEntry(k.name, v)),
    'hash': hash,
  };
}

class ConsensusVote {
  final String voterId;
  final String amendmentId;
  final bool support;
  final String? reason;
  final int timestamp;

  const ConsensusVote({
    required this.voterId,
    required this.amendmentId,
    required this.support,
    this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'voter': voterId,
    'amendment': amendmentId,
    'support': support,
    'reason': reason,
    'ts': timestamp,
  };
}

class ConsensusResult {
  final String amendmentId;
  final int totalVotes;
  final int supportVotes;
  final int opposeVotes;
  final double supportRatio;
  final bool passed;
  final int decidedAt;

  const ConsensusResult({
    required this.amendmentId,
    required this.totalVotes,
    required this.supportVotes,
    required this.opposeVotes,
    required this.supportRatio,
    required this.passed,
    required this.decidedAt,
  });

  Map<String, dynamic> toJson() => {
    'amendment': amendmentId,
    'total': totalVotes,
    'support': supportVotes,
    'oppose': opposeVotes,
    'ratio': supportRatio.toStringAsFixed(3),
    'passed': passed,
    'decided': decidedAt,
  };
}

class LawFork {
  final String forkId;
  final RuntimeLawId lawId;
  final LawManifest localManifest;
  final LawManifest remoteManifest;
  final LawForkResolution resolution;
  final int detectedAt;

  const LawFork({
    required this.forkId,
    required this.lawId,
    required this.localManifest,
    required this.remoteManifest,
    required this.resolution,
    required this.detectedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': forkId,
    'law': lawId.name,
    'local': localManifest.toJson(),
    'remote': remoteManifest.toJson(),
    'resolution': resolution.name,
    'detected': detectedAt,
  };
}

class ConstitutionalConsensus {
  final String localNodeId;
  final LawManifest _localManifest;
  final Map<String, LawManifest> _remoteManifests = {};
  final List<ConsensusVote> _votes = [];
  final Map<String, ConsensusResult> _results = {};
  final List<LawFork> _forks = [];
  final double _passThreshold;
  // ignore: unused_field
  final ConstitutionalTraceGraph? _traceGraph;
  int _forkSeq = 0;

  ConstitutionalConsensus({
    required this.localNodeId,
    int initialEpoch = 0,
    double passThreshold = 0.6,
    ConstitutionalTraceGraph? traceGraph,
  }) : _localManifest = LawManifest.forNode(localNodeId, initialEpoch),
       _passThreshold = passThreshold,
       _traceGraph = traceGraph;

  LawManifest get localManifest => _localManifest;
  Map<String, LawManifest> get remoteManifests =>
      Map.unmodifiable(_remoteManifests);
  List<LawFork> get forks => List.unmodifiable(_forks);
  double get passThreshold => _passThreshold;

  void registerRemoteNode(String nodeId, LawManifest manifest) {
    _remoteManifests[nodeId] = manifest;
  }

  LawFork detectFork(LawManifest remoteManifest) {
    final conflictingLaws = <RuntimeLawId>[];

    for (final lawId in RuntimeLawId.values) {
      final localVer = _localManifest.lawVersions[lawId] ?? 0;
      final remoteVer = remoteManifest.lawVersions[lawId] ?? 0;
      if (localVer != remoteVer) {
        conflictingLaws.add(lawId);
      }
    }

    LawForkResolution resolution;
    if (conflictingLaws.isEmpty) {
      resolution = LawForkResolution.merge;
    } else {
      final localEpoch = _localManifest.epoch;
      final remoteEpoch = remoteManifest.epoch;
      if (remoteEpoch > localEpoch) {
        resolution = LawForkResolution.adoptRemote;
      } else if (localEpoch > remoteEpoch) {
        resolution = LawForkResolution.keepLocal;
      } else {
        resolution = LawForkResolution.conflict;
      }
    }

    final fork = LawFork(
      forkId: 'fork-${_forkSeq++}',
      lawId: conflictingLaws.isNotEmpty
          ? conflictingLaws.first
          : RuntimeLawId.noBypassCapabilityRouter,
      localManifest: _localManifest,
      remoteManifest: remoteManifest,
      resolution: resolution,
      detectedAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (resolution != LawForkResolution.merge) {
      _forks.add(fork);
    }

    return fork;
  }

  ConsensusVote castVote({
    required String voterId,
    required String amendmentId,
    required bool support,
    String? reason,
    required int timestamp,
  }) {
    final vote = ConsensusVote(
      voterId: voterId,
      amendmentId: amendmentId,
      support: support,
      reason: reason,
      timestamp: timestamp,
    );
    _votes.add(vote);
    return vote;
  }

  ConsensusResult tallyVotes(String amendmentId, int timestamp) {
    final amendmentVotes = _votes
        .where((v) => v.amendmentId == amendmentId)
        .toList();
    final support = amendmentVotes.where((v) => v.support).length;
    final oppose = amendmentVotes.where((v) => !v.support).length;
    final total = amendmentVotes.length;
    final ratio = total > 0 ? support / total : 0.0;
    final passed = ratio >= _passThreshold && total > 0;

    final result = ConsensusResult(
      amendmentId: amendmentId,
      totalVotes: total,
      supportVotes: support,
      opposeVotes: oppose,
      supportRatio: ratio,
      passed: passed,
      decidedAt: timestamp,
    );

    _results[amendmentId] = result;
    return result;
  }

  ConsensusResult? resultFor(String amendmentId) => _results[amendmentId];

  List<ConsensusVote> votesFor(String amendmentId) =>
      _votes.where((v) => v.amendmentId == amendmentId).toList();

  int totalNodes() => 1 + _remoteManifests.length;
}

class TrustPassport {
  final String entityId;
  final String issuingRuntime;
  final double reputationScore;
  final TrustLevel trustLevel;
  final int totalInteractions;
  final double complianceRatio;
  final int issuedAt;
  final int expiresAt;
  final String signature;

  const TrustPassport({
    required this.entityId,
    required this.issuingRuntime,
    required this.reputationScore,
    required this.trustLevel,
    required this.totalInteractions,
    required this.complianceRatio,
    required this.issuedAt,
    required this.expiresAt,
    required this.signature,
  });

  bool get isValid => DateTime.now().millisecondsSinceEpoch < expiresAt;

  Map<String, dynamic> toJson() => {
    'entity': entityId,
    'issuer': issuingRuntime,
    'score': reputationScore.toStringAsFixed(2),
    'trust': trustLevel.name,
    'interactions': totalInteractions,
    'ratio': complianceRatio.toStringAsFixed(3),
    'issued': issuedAt,
    'expires': expiresAt,
    'sig': signature,
  };

  factory TrustPassport.fromReputation(
    ReputationScore score,
    String issuingRuntime,
    int ttl,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sig = _computeSignature(
      score.entityId,
      issuingRuntime,
      score.score,
      now,
    );
    return TrustPassport(
      entityId: score.entityId,
      issuingRuntime: issuingRuntime,
      reputationScore: score.score,
      trustLevel: score.effectiveTrustLevel,
      totalInteractions: score.totalInteractions,
      complianceRatio: score.complianceRatio,
      issuedAt: now,
      expiresAt: now + ttl,
      signature: sig,
    );
  }

  static String _computeSignature(
    String entityId,
    String issuer,
    double score,
    int issuedAt,
  ) {
    final input = utf8.encode(
      '$entityId|$issuer|${score.toStringAsFixed(2)}|$issuedAt',
    );
    final digest = sha256.convert(input);
    return 'passport_${digest.toString().substring(0, 32)}';
  }
}

class FederatedReputation {
  final String localRuntimeId;
  // ignore: unused_field
  final ConstitutionalTraceGraph? _traceGraph;
  final Map<String, TrustPassport> _passports = {};
  final Map<String, double> _federatedScores = {};

  FederatedReputation({
    required this.localRuntimeId,
    ConstitutionalTraceGraph? traceGraph,
  }) : _traceGraph = traceGraph;

  Map<String, TrustPassport> get passports => Map.unmodifiable(_passports);
  int get passportCount => _passports.length;

  TrustPassport issuePassport(ReputationScore score, {int ttl = 3600000}) {
    final passport = TrustPassport.fromReputation(score, localRuntimeId, ttl);
    _passports[score.entityId] = passport;
    return passport;
  }

  bool verifyPassport(TrustPassport passport) {
    final expectedSig = TrustPassport._computeSignature(
      passport.entityId,
      passport.issuingRuntime,
      passport.reputationScore,
      passport.issuedAt,
    );
    return passport.signature == expectedSig && passport.isValid;
  }

  bool importPassport(TrustPassport passport) {
    if (!verifyPassport(passport)) return false;
    if (passport.issuingRuntime == localRuntimeId) return false;

    _passports['${passport.issuingRuntime}:${passport.entityId}'] = passport;
    _updateFederatedScore(passport.entityId);
    return true;
  }

  double federatedScoreFor(String entityId) {
    return _federatedScores[entityId] ?? 100.0;
  }

  TrustLevel federatedTrustLevelFor(String entityId) {
    final score = federatedScoreFor(entityId);
    if (score >= 90) return TrustLevel.system;
    if (score >= 70) return TrustLevel.signed;
    if (score >= 50) return TrustLevel.verified;
    if (score >= 20) return TrustLevel.untrusted;
    return TrustLevel.blocked;
  }

  Map<String, double> allFederatedScores() =>
      Map.unmodifiable(_federatedScores);

  void _updateFederatedScore(String entityId) {
    final relevantPassports = _passports.entries
        .where((e) => e.key.endsWith(':$entityId') || e.key == entityId)
        .map((e) => e.value)
        .where((p) => p.isValid)
        .toList();

    if (relevantPassports.isEmpty) {
      _federatedScores[entityId] = 100.0;
      return;
    }

    double totalScore = 0;
    double totalWeight = 0;
    for (final passport in relevantPassports) {
      final weight = passport.complianceRatio;
      totalScore += passport.reputationScore * weight;
      totalWeight += weight;
    }

    _federatedScores[entityId] = totalWeight > 0
        ? totalScore / totalWeight
        : 100.0;
  }
}

enum LegislativeStage {
  proposed,
  simulating,
  impactAnalysis,
  judiciaryReview,
  consensusVoting,
  enacted,
  rejected,
}

class LegislativeProposal {
  final String proposalId;
  final String description;
  final RuntimeLawId targetLaw;
  final String proposedChange;
  final LegislativeStage stage;
  final String rationale;
  final int proposedAt;
  final int? enactedAt;
  final Map<String, dynamic> simulationResult;
  final Map<String, dynamic> impactAnalysis;
  final Map<String, dynamic> judiciaryReview;
  final ConsensusResult? consensusResult;

  const LegislativeProposal({
    required this.proposalId,
    required this.description,
    required this.targetLaw,
    required this.proposedChange,
    required this.stage,
    required this.rationale,
    required this.proposedAt,
    this.enactedAt,
    this.simulationResult = const {},
    this.impactAnalysis = const {},
    this.judiciaryReview = const {},
    this.consensusResult,
  });

  LegislativeProposal copyWith({
    LegislativeStage? stage,
    int? enactedAt,
    Map<String, dynamic>? simulationResult,
    Map<String, dynamic>? impactAnalysis,
    Map<String, dynamic>? judiciaryReview,
    ConsensusResult? consensusResult,
  }) => LegislativeProposal(
    proposalId: proposalId,
    description: description,
    targetLaw: targetLaw,
    proposedChange: proposedChange,
    stage: stage ?? this.stage,
    rationale: rationale,
    proposedAt: proposedAt,
    enactedAt: enactedAt ?? this.enactedAt,
    simulationResult: simulationResult ?? this.simulationResult,
    impactAnalysis: impactAnalysis ?? this.impactAnalysis,
    judiciaryReview: judiciaryReview ?? this.judiciaryReview,
    consensusResult: consensusResult ?? this.consensusResult,
  );

  Map<String, dynamic> toJson() => {
    'id': proposalId,
    'desc': description,
    'law': targetLaw.name,
    'change': proposedChange,
    'stage': stage.name,
    'rationale': rationale,
    'proposed': proposedAt,
    'enacted': enactedAt,
    'simulation': simulationResult,
    'impact': impactAnalysis,
    'judiciary': judiciaryReview,
    'consensus': consensusResult?.toJson(),
  };
}

class AutonomousLegislature {
  final ConstitutionalConsensus _consensus;
  final ConstitutionalTraceGraph _traceGraph;
  final ReputationEconomy _reputationEconomy;
  // ignore: unused_field
  final RuntimeJudiciary _judiciary;
  final List<LegislativeProposal> _proposals = [];
  int _proposalSeq = 0;

  AutonomousLegislature({
    required ConstitutionalConsensus consensus,
    required ConstitutionalTraceGraph traceGraph,
    required ReputationEconomy reputationEconomy,
    required RuntimeJudiciary judiciary,
  }) : _consensus = consensus,
       _traceGraph = traceGraph,
       _reputationEconomy = reputationEconomy,
       _judiciary = judiciary;

  List<LegislativeProposal> get proposals => List.unmodifiable(_proposals);
  LegislativeProposal? activeProposal;

  LegislativeProposal propose({
    required String description,
    required RuntimeLawId targetLaw,
    required String proposedChange,
    required String rationale,
    required int timestamp,
  }) {
    final proposal = LegislativeProposal(
      proposalId: 'leg-${_proposalSeq++}',
      description: description,
      targetLaw: targetLaw,
      proposedChange: proposedChange,
      stage: LegislativeStage.proposed,
      rationale: rationale,
      proposedAt: timestamp,
    );
    _proposals.add(proposal);
    activeProposal = proposal;
    return proposal;
  }

  LegislativeProposal simulate() {
    if (activeProposal == null) throw StateError('No active proposal');
    final proposal = activeProposal!;

    final stats = _traceGraph.computeStatistics();
    final lawViolations = stats.violationCounts[proposal.targetLaw] ?? 0;
    final totalDecisions = stats.totalDecisions;
    final affectedSandboxes = _traceGraph
        .violationsForLaw(proposal.targetLaw)
        .map((d) => d.sandboxId)
        .toSet()
        .length;

    final simulationResult = {
      'currentViolations': lawViolations,
      'totalDecisions': totalDecisions,
      'affectedSandboxes': affectedSandboxes,
      'estimatedReduction': lawViolations > 0
          ? (lawViolations * 0.7).round()
          : 0,
      'riskLevel': lawViolations > 20
          ? 'high'
          : lawViolations > 10
          ? 'medium'
          : 'low',
    };

    final updated = proposal.copyWith(
      stage: LegislativeStage.simulating,
      simulationResult: simulationResult,
    );
    _updateProposal(updated);
    return updated;
  }

  LegislativeProposal analyzeImpact() {
    if (activeProposal == null) throw StateError('No active proposal');
    final proposal = activeProposal!;

    final sim = proposal.simulationResult;
    final constitutionalScore = _reputationEconomy.constitutionalScore();
    final lowestEntities = _reputationEconomy.lowestReputationEntities(
      limit: 3,
    );

    final impactAnalysis = {
      'constitutionalHealthScore': constitutionalScore.toStringAsFixed(2),
      'highestRiskEntities': lowestEntities,
      'estimatedComplianceImprovement': sim['estimatedReduction'] ?? 0,
      'breakingChange': false,
      'affectedTrustLevels': ['untrusted', 'blocked'],
    };

    final updated = proposal.copyWith(
      stage: LegislativeStage.impactAnalysis,
      impactAnalysis: impactAnalysis,
    );
    _updateProposal(updated);
    return updated;
  }

  LegislativeProposal judiciaryCheck() {
    if (activeProposal == null) throw StateError('No active proposal');
    final proposal = activeProposal!;

    final targetLaw = proposal.targetLaw;
    final stats = _traceGraph.computeStatistics();
    final currentViolations = stats.violationCounts[targetLaw] ?? 0;
    final isConstitutional =
        currentViolations > 0 || proposal.proposedChange.isNotEmpty;
    final conflictsWithExisting = _detectLawConflict(
      targetLaw,
      proposal.proposedChange,
    );

    final recommendation = isConstitutional && !conflictsWithExisting
        ? 'proceed'
        : conflictsWithExisting
        ? 'review'
        : 'reject';

    final review = {
      'constitutional': isConstitutional,
      'conflictsWithExisting': conflictsWithExisting,
      'compatibleWithCurrentLaw': !conflictsWithExisting,
      'currentViolations': currentViolations,
      'recommendation': recommendation,
    };

    final updated = proposal.copyWith(
      stage: LegislativeStage.judiciaryReview,
      judiciaryReview: review,
    );
    _updateProposal(updated);
    return updated;
  }

  bool _detectLawConflict(RuntimeLawId targetLaw, String proposedChange) {
    final existingProposals = _proposals.where(
      (p) => p.targetLaw == targetLaw && p.stage != LegislativeStage.rejected,
    );
    final currentId = activeProposal?.proposalId;
    for (final p in existingProposals) {
      if (p.proposedChange == proposedChange && p.proposalId != currentId) {
        return true;
      }
    }
    return false;
  }

  LegislativeProposal submitToVote(int timestamp) {
    if (activeProposal == null) throw StateError('No active proposal');
    final proposal = activeProposal!;

    final review = proposal.judiciaryReview;
    final recommendation = review['recommendation'];
    if (recommendation == 'reject') {
      final rejected = proposal.copyWith(stage: LegislativeStage.rejected);
      _updateProposal(rejected);
      return rejected;
    }
    if (recommendation == 'review') {
      final updated = proposal.copyWith(
        stage: LegislativeStage.consensusVoting,
      );
      _updateProposal(updated);
      return updated;
    }

    final updated = proposal.copyWith(stage: LegislativeStage.consensusVoting);
    _updateProposal(updated);
    return updated;
  }

  LegislativeProposal enact(int timestamp) {
    if (activeProposal == null) throw StateError('No active proposal');
    final proposal = activeProposal!;

    final result = _consensus.tallyVotes(proposal.proposalId, timestamp);

    if (result.passed) {
      final enacted = proposal.copyWith(
        stage: LegislativeStage.enacted,
        enactedAt: timestamp,
        consensusResult: result,
      );
      _updateProposal(enacted);
      activeProposal = null;
      return enacted;
    } else {
      final rejected = proposal.copyWith(
        stage: LegislativeStage.rejected,
        consensusResult: result,
      );
      _updateProposal(rejected);
      activeProposal = null;
      return rejected;
    }
  }

  LegislativeProposal runFullPipeline(int timestamp) {
    simulate();
    analyzeImpact();
    judiciaryCheck();
    submitToVote(timestamp);
    return enact(timestamp);
  }

  void _updateProposal(LegislativeProposal updated) {
    final idx = _proposals.indexWhere(
      (p) => p.proposalId == updated.proposalId,
    );
    if (idx >= 0) {
      _proposals[idx] = updated;
      activeProposal = updated;
    }
  }
}
