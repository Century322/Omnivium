import '../stability/security.dart';
import 'runtime_law.dart';
import 'constitutional_trace.dart';
import 'constitutional_civilization.dart';
import 'constitutional_sovereign.dart';
import 'constitutional_civilization_layer.dart';
import 'civilization_network.dart';
import 'sovereign_identity.dart';

enum KernelCall {
  lawEnforce,
  trustQuery,
  governanceAdjudicate,
  diplomacySync,
  evolutionPropose,
  economicsTransact,
  sovereigntyIdentify,
  consensusVote,
  judiciaryTry,
  legislatureEnact,
  reputationScore,
  federationJoin,
  passportIssue,
  passportVerify,
  byzantineReport,
  heartbeat,
}

class KernelResult {
  final bool success;
  final String? error;
  final Map<String, dynamic> data;

  const KernelResult({required this.success, this.error, this.data = const {}});

  factory KernelResult.ok(Map<String, dynamic> data) =>
      KernelResult(success: true, data: data);

  factory KernelResult.fail(String error) =>
      KernelResult(success: false, error: error);
}

class CivilizationKernel {
  final String nodeId;
  final RuntimeLawEnforcer _enforcer;
  final ConstitutionalTraceGraph _traceGraph;
  final ImmutableAuditLedger _ledger;
  final ConstitutionalEvolutionEngine _evolutionEngine;
  final ReputationEconomy _reputationEconomy;
  final RuntimeJudiciary _judiciary;
  final ConstitutionalConsensus _consensus;
  final FederatedReputation _federatedReputation;
  final AutonomousLegislature _legislature;
  final CivilizationTransport _transport;
  final ResourceEconomy _economy;
  final CivilizationNetwork? _network;
  final SovereignIdentity _identity;
  final List<KernelCall> _callLog = [];
  final Map<KernelCall, int> _callCounts = {};
  // ignore: unused_field
  int _kernelSeq = 0;

  CivilizationKernel._internal({
    required this.nodeId,
    required RuntimeLawEnforcer enforcer,
    required ConstitutionalTraceGraph traceGraph,
    required ImmutableAuditLedger ledger,
    required ConstitutionalEvolutionEngine evolutionEngine,
    required ReputationEconomy reputationEconomy,
    required RuntimeJudiciary judiciary,
    required ConstitutionalConsensus consensus,
    required FederatedReputation federatedReputation,
    required AutonomousLegislature legislature,
    required CivilizationTransport transport,
    required ResourceEconomy economy,
    required CivilizationNetwork? network,
    required SovereignIdentity identity,
  }) : _enforcer = enforcer,
       _traceGraph = traceGraph,
       _ledger = ledger,
       _evolutionEngine = evolutionEngine,
       _reputationEconomy = reputationEconomy,
       _judiciary = judiciary,
       _consensus = consensus,
       _federatedReputation = federatedReputation,
       _legislature = legislature,
       _transport = transport,
       _economy = economy,
       _network = network,
       _identity = identity;

  factory CivilizationKernel({
    required String nodeId,
    required RuntimeLawEnforcer enforcer,
    ConstitutionalTraceGraph? traceGraph,
    ImmutableAuditLedger? ledger,
    bool enableNetwork = false,
  }) {
    final sharedTraceGraph = traceGraph ?? ConstitutionalTraceGraph();
    final sharedLedger = ledger ?? ImmutableAuditLedger();
    final sharedConsensus = ConstitutionalConsensus(localNodeId: nodeId);
    final sharedReputationEconomy = ReputationEconomy(sharedTraceGraph);
    final sharedJudiciary = RuntimeJudiciary(sharedTraceGraph, sharedLedger);
    return CivilizationKernel._internal(
      nodeId: nodeId,
      enforcer: enforcer,
      traceGraph: sharedTraceGraph,
      ledger: sharedLedger,
      evolutionEngine: ConstitutionalEvolutionEngine(sharedTraceGraph),
      reputationEconomy: sharedReputationEconomy,
      judiciary: sharedJudiciary,
      consensus: sharedConsensus,
      federatedReputation: FederatedReputation(localRuntimeId: nodeId),
      legislature: AutonomousLegislature(
        consensus: sharedConsensus,
        traceGraph: sharedTraceGraph,
        reputationEconomy: sharedReputationEconomy,
        judiciary: sharedJudiciary,
      ),
      transport: CivilizationTransport(localNodeId: nodeId),
      economy: ResourceEconomy(federationId: nodeId),
      network: enableNetwork ? CivilizationNetwork(localNodeId: nodeId) : null,
      identity: SovereignIdentity.generate(nodeId),
    );
  }

  ConstitutionalTraceGraph get traceGraph => _traceGraph;
  ImmutableAuditLedger get ledger => _ledger;
  ConstitutionalEvolutionEngine get evolutionEngine => _evolutionEngine;
  ReputationEconomy get reputationEconomy => _reputationEconomy;
  RuntimeJudiciary get judiciary => _judiciary;
  ConstitutionalConsensus get consensus => _consensus;
  FederatedReputation get federatedReputation => _federatedReputation;
  AutonomousLegislature get legislature => _legislature;
  CivilizationTransport get transport => _transport;
  ResourceEconomy get economy => _economy;
  CivilizationNetwork? get network => _network;
  SovereignIdentity get identity => _identity;
  List<KernelCall> get callLog => List.unmodifiable(_callLog);
  Map<KernelCall, int> get callCounts => Map.unmodifiable(_callCounts);

  KernelResult syscall(KernelCall call, Map<String, dynamic> params) {
    _recordCall(call);
    _ledger.append(
      entryType: 'kernel.syscall',
      sandboxId: nodeId,
      data: {'call': call.name, 'params': params},
      timestamp: _enforcer.clock.tick().physicalTime,
    );

    switch (call) {
      case KernelCall.lawEnforce:
        return _syscallLawEnforce(params);
      case KernelCall.trustQuery:
        return _syscallTrustQuery(params);
      case KernelCall.governanceAdjudicate:
        return _syscallGovernanceAdjudicate(params);
      case KernelCall.diplomacySync:
        return _syscallDiplomacySync(params);
      case KernelCall.evolutionPropose:
        return _syscallEvolutionPropose(params);
      case KernelCall.economicsTransact:
        return _syscallEconomicsTransact(params);
      case KernelCall.sovereigntyIdentify:
        return _syscallSovereigntyIdentify(params);
      case KernelCall.consensusVote:
        return _syscallConsensusVote(params);
      case KernelCall.judiciaryTry:
        return _syscallJudiciaryTry(params);
      case KernelCall.legislatureEnact:
        return _syscallLegislatureEnact(params);
      case KernelCall.reputationScore:
        return _syscallReputationScore(params);
      case KernelCall.federationJoin:
        return _syscallFederationJoin(params);
      case KernelCall.passportIssue:
        return _syscallPassportIssue(params);
      case KernelCall.passportVerify:
        return _syscallPassportVerify(params);
      case KernelCall.byzantineReport:
        return _syscallByzantineReport(params);
      case KernelCall.heartbeat:
        return _syscallHeartbeat(params);
    }
  }

  KernelResult _syscallLawEnforce(Map<String, dynamic> params) {
    final sandboxId = params['sandboxId'] as String?;
    final capabilityId = params['capabilityId'] as String?;
    final callerTrust = params['callerTrust'] as String?;
    final requiredTrust = params['requiredTrust'] as String?;
    final routed = params['routed'] as bool? ?? true;
    final traced = params['traced'] as bool? ?? true;

    if (sandboxId == null || capabilityId == null) {
      return KernelResult.fail('sandboxId and capabilityId required');
    }

    final callerLevel = _parseTrustLevel(callerTrust);
    final requiredLevel = _parseTrustLevel(requiredTrust);

    final result = _enforcer.enforceCapabilityRouting(
      sandboxId,
      capabilityId,
      routed,
    );
    if (!result.compliant) {
      _reputationEconomy.recordViolation(
        sandboxId,
        _enforcer.clock.tick().physicalTime,
      );
      return KernelResult.ok({
        'compliant': false,
        'violation': result.violation,
        'law': 'noBypassCapabilityRouter',
      });
    }

    final trustResult = _enforcer.enforceTrustLevel(
      sandboxId,
      requiredLevel,
      callerLevel,
    );
    if (!trustResult.compliant) {
      _reputationEconomy.recordViolation(
        sandboxId,
        _enforcer.clock.tick().physicalTime,
      );
      return KernelResult.ok({
        'compliant': false,
        'violation': trustResult.violation,
        'law': 'trustLevelMustBeRespected',
      });
    }

    final traceResult = _enforcer.enforceTracing(sandboxId, traced);
    if (!traceResult.compliant) {
      return KernelResult.ok({
        'compliant': false,
        'violation': traceResult.violation,
        'law': 'allOpsMustBeTraced',
      });
    }

    _reputationEconomy.recordCompliance(
      sandboxId,
      _enforcer.clock.tick().physicalTime,
    );
    return KernelResult.ok({'compliant': true, 'capability': capabilityId});
  }

  KernelResult _syscallTrustQuery(Map<String, dynamic> params) {
    final entityId = params['entityId'] as String?;
    if (entityId == null) return KernelResult.fail('entityId required');
    final score = _reputationEconomy.scoreFor(entityId);
    return KernelResult.ok({
      'entityId': entityId,
      'score': score.score.toStringAsFixed(2),
      'trustLevel': score.effectiveTrustLevel.name,
    });
  }

  KernelResult _syscallGovernanceAdjudicate(Map<String, dynamic> params) {
    final sandboxId = params['sandboxId'] as String?;
    final violationType = params['violationType'] as String?;
    if (sandboxId == null || violationType == null) {
      return KernelResult.fail('sandboxId and violationType required');
    }
    final sanction = _judiciary.imposeSanction(
      sandboxId: sandboxId,
      type: SanctionType.restriction,
      reason: violationType,
      timestamp: _enforcer.clock.tick().physicalTime,
    );
    return KernelResult.ok({
      'sandboxId': sandboxId,
      'sanctionType': sanction.type.name,
      'severity': sanction.reason,
    });
  }

  KernelResult _syscallDiplomacySync(Map<String, dynamic> params) {
    final targetId = params['targetId'] as String?;
    if (targetId == null) return KernelResult.fail('targetId required');
    final manifest = _consensus.localManifest;
    final msg = _transport.sendConstitutionSync(
      targetId,
      manifest,
      _enforcer.clock.tick().physicalTime,
    );
    return KernelResult.ok({
      'messageId': msg.epoch,
      'target': targetId,
      'epoch': manifest.epoch,
    });
  }

  KernelResult _syscallEvolutionPropose(Map<String, dynamic> params) {
    final description = params['description'] as String?;
    final targetLaw = params['targetLaw'] as String?;
    final proposedChange = params['proposedChange'] as String?;
    final rationale = params['rationale'] as String?;
    if (description == null || targetLaw == null) {
      return KernelResult.fail('description and targetLaw required');
    }
    final lawId = RuntimeLawId.values.firstWhere(
      (l) => l.name == targetLaw,
      orElse: () => RuntimeLawId.noBypassCapabilityRouter,
    );
    final proposal = _legislature.propose(
      description: description,
      targetLaw: lawId,
      proposedChange: proposedChange ?? '',
      rationale: rationale ?? '',
      timestamp: _enforcer.clock.tick().physicalTime,
    );
    return KernelResult.ok({
      'proposalId': proposal.proposalId,
      'stage': proposal.stage.name,
    });
  }

  KernelResult _syscallEconomicsTransact(Map<String, dynamic> params) {
    final entityId = params['entityId'] as String?;
    final action = params['action'] as String?;
    final amount = params['amount'] as double?;
    if (entityId == null || action == null || amount == null) {
      return KernelResult.fail('entityId, action, and amount required');
    }
    final timestamp = _enforcer.clock.tick().physicalTime;
    switch (action) {
      case 'earn':
        final result = _economy.earn(entityId, amount, timestamp);
        return KernelResult.ok({
          'balance': result.balance.toStringAsFixed(2),
          'action': 'earn',
        });
      case 'spend':
        final result = _economy.spend(entityId, amount, timestamp);
        if (result == null) return KernelResult.fail('insufficient balance');
        return KernelResult.ok({
          'balance': result.balance.toStringAsFixed(2),
          'action': 'spend',
        });
      case 'penalty':
        _economy.imposePenalty(entityId, amount, 'kernel_penalty', timestamp);
        return KernelResult.ok({
          'action': 'penalty',
          'amount': amount.toStringAsFixed(2),
        });
      default:
        return KernelResult.fail('unknown action: $action');
    }
  }

  KernelResult _syscallSovereigntyIdentify(Map<String, dynamic> params) {
    return KernelResult.ok({
      'did': _identity.did,
      'nodeId': _identity.nodeId,
      'publicKey': _identity.publicKey,
      'epoch': _identity.civilizationEpoch,
      'federation': _identity.federationId,
      'trustLevel': _identity.trustLevel.name,
      'verified': SovereignIdentity.verify(_identity),
    });
  }

  KernelResult _syscallConsensusVote(Map<String, dynamic> params) {
    final amendmentId = params['amendmentId'] as String?;
    final support = params['support'] as bool? ?? true;
    final reason = params['reason'] as String?;
    if (amendmentId == null) return KernelResult.fail('amendmentId required');
    final vote = _consensus.castVote(
      voterId: nodeId,
      amendmentId: amendmentId,
      support: support,
      reason: reason,
      timestamp: _enforcer.clock.tick().physicalTime,
    );
    return KernelResult.ok({
      'voter': vote.voterId,
      'amendment': vote.amendmentId,
      'support': vote.support,
    });
  }

  KernelResult _syscallJudiciaryTry(Map<String, dynamic> params) {
    final sandboxId = params['sandboxId'] as String?;
    final violationType = params['violationType'] as String?;
    if (sandboxId == null || violationType == null) {
      return KernelResult.fail('sandboxId and violationType required');
    }
    final sanction = _judiciary.imposeSanction(
      sandboxId: sandboxId,
      type: SanctionType.restriction,
      reason: violationType,
      timestamp: _enforcer.clock.tick().physicalTime,
    );
    return KernelResult.ok({
      'sandboxId': sanction.sandboxId,
      'type': sanction.type.name,
      'severity': sanction.reason,
      'active': sanction.isActive,
    });
  }

  KernelResult _syscallLegislatureEnact(Map<String, dynamic> params) {
    final timestamp = _enforcer.clock.tick().physicalTime;
    final result = _legislature.enact(timestamp);
    return KernelResult.ok({
      'proposalId': result.proposalId,
      'stage': result.stage.name,
      'enacted': result.stage == LegislativeStage.enacted,
    });
  }

  KernelResult _syscallReputationScore(Map<String, dynamic> params) {
    final entityId = params['entityId'] as String?;
    if (entityId == null) return KernelResult.fail('entityId required');
    final score = _reputationEconomy.scoreFor(entityId);
    final federated = _federatedReputation.federatedScoreFor(entityId);
    return KernelResult.ok({
      'entityId': entityId,
      'localScore': score.score.toStringAsFixed(2),
      'federatedScore': federated.toStringAsFixed(2),
      'trustLevel': score.effectiveTrustLevel.name,
    });
  }

  KernelResult _syscallFederationJoin(Map<String, dynamic> params) {
    final federationId = params['federationId'] as String?;
    if (federationId == null) return KernelResult.fail('federationId required');
    // ignore: unused_local_variable
    final msg = _transport.sendFederationAccept(
      federationId,
      federationId,
      _enforcer.clock.tick().physicalTime,
    );
    return KernelResult.ok({'federationId': federationId, 'accepted': true});
  }

  KernelResult _syscallPassportIssue(Map<String, dynamic> params) {
    final entityId = params['entityId'] as String?;
    if (entityId == null) return KernelResult.fail('entityId required');
    final score = _reputationEconomy.scoreFor(entityId);
    final passport = _federatedReputation.issuePassport(score);
    return KernelResult.ok({
      'entityId': passport.entityId,
      'score': passport.reputationScore.toStringAsFixed(2),
      'trustLevel': passport.trustLevel.name,
      'expiresAt': passport.expiresAt,
    });
  }

  KernelResult _syscallPassportVerify(Map<String, dynamic> params) {
    final entityId = params['entityId'] as String?;
    if (entityId == null) return KernelResult.fail('entityId required');
    final passport = _federatedReputation.passports[entityId];
    if (passport == null) return KernelResult.fail('no passport found');
    final valid = _federatedReputation.verifyPassport(passport);
    return KernelResult.ok({'entityId': entityId, 'valid': valid});
  }

  KernelResult _syscallByzantineReport(Map<String, dynamic> params) {
    if (_network == null) return KernelResult.fail('network not enabled');
    final accusedId = params['accusedId'] as String?;
    if (accusedId == null) return KernelResult.fail('accusedId required');
    _network.byzantine.reportInconsistentMessage(
      accusedId,
      'kernel_report',
      _enforcer.clock.tick().physicalTime,
    );
    return KernelResult.ok({
      'accusedId': accusedId,
      'reported': true,
      'verdict': _network.byzantine.verdictFor(accusedId).name,
    });
  }

  KernelResult _syscallHeartbeat(Map<String, dynamic> params) {
    final targetId = params['targetId'] as String?;
    if (targetId == null) return KernelResult.fail('targetId required');
    if (_network == null) return KernelResult.fail('network not enabled');
    _network.sendHeartbeat(
      targetId,
      _consensus.localManifest.epoch,
      _enforcer.clock.tick().physicalTime,
    );
    return KernelResult.ok({
      'target': targetId,
      'epoch': _consensus.localManifest.epoch,
    });
  }

  void _recordCall(KernelCall call) {
    _callLog.add(call);
    _callCounts[call] = (_callCounts[call] ?? 0) + 1;
    _kernelSeq++;
  }

  TrustLevel _parseTrustLevel(String? name) {
    if (name == null) return TrustLevel.verified;
    return TrustLevel.values.firstWhere(
      (t) => t.name == name,
      orElse: () => TrustLevel.verified,
    );
  }
}
