import '../stability/security.dart';
import 'runtime_law.dart';
import 'sandbox_runtime.dart';
import 'constitutional_trace.dart';
import 'constitutional_civilization.dart';
import 'constitutional_sovereign.dart';
import 'constitutional_civilization_layer.dart';
import 'civilization_network.dart';

export 'constitutional_trace.dart' show EscalationLevel;
export 'constitutional_civilization.dart' show PolicyLoophole, ConstitutionalAmendment, ReputationScore, TrustDecayPolicy, Sanction, Appeal, SanctionType, AppealStatus;
export 'constitutional_sovereign.dart' show ConstitutionalConsensus, LawManifest, LawFork, LawForkResolution, ConsensusVote, ConsensusResult, TrustPassport, FederatedReputation, AutonomousLegislature, LegislativeProposal, LegislativeStage;
export 'constitutional_civilization_layer.dart' show CivilizationTransport, DiplomacyMessage, DiplomacyMessageType, DiplomacyChannel, CivilizationIdentity, TrustGraph, FederationMembership, ExecutionCredits, FederationTreasury, ResourceEconomy;
export 'civilization_network.dart' show CivilizationNetwork, WireMessage, WireMessageType, GossipProtocol, ConstitutionalReplication, ByzantineDetector, ByzantineVerdict, ByzantineAccusation, NetworkNode, NodeStatus, ReplicationEntry, ReplicationResult;

class ViolationEscalationPolicy {
  final int warningThreshold;
  final int restrictedThreshold;
  final int terminationThreshold;
  final Map<SandboxViolationType, int> violationWeights;

  const ViolationEscalationPolicy({
    this.warningThreshold = 3,
    this.restrictedThreshold = 7,
    this.terminationThreshold = 10,
    this.violationWeights = const {
      SandboxViolationType.bypassAttempt: 3,
      SandboxViolationType.trustInsufficient: 2,
      SandboxViolationType.budgetExceeded: 1,
      SandboxViolationType.taskLimitExceeded: 1,
      SandboxViolationType.streamLimitExceeded: 1,
      SandboxViolationType.capabilityDenied: 1,
      SandboxViolationType.policyDenied: 1,
      SandboxViolationType.executionTimeExceeded: 2,
      SandboxViolationType.memoryExceeded: 2,
    },
  });

  int weightFor(SandboxViolationType type) => violationWeights[type] ?? 1;
}

class EscalationState {
  final String sandboxId;
  final EscalationLevel level;
  final int weightedScore;
  final int totalViolations;
  final int lastEscalationAt;
  final String? restrictionReason;

  const EscalationState({
    required this.sandboxId,
    this.level = EscalationLevel.warning,
    this.weightedScore = 0,
    this.totalViolations = 0,
    this.lastEscalationAt = 0,
    this.restrictionReason,
  });

  EscalationState copyWith({
    EscalationLevel? level,
    int? weightedScore,
    int? totalViolations,
    int? lastEscalationAt,
    String? restrictionReason,
  }) =>
      EscalationState(
        sandboxId: sandboxId,
        level: level ?? this.level,
        weightedScore: weightedScore ?? this.weightedScore,
        totalViolations: totalViolations ?? this.totalViolations,
        lastEscalationAt: lastEscalationAt ?? this.lastEscalationAt,
        restrictionReason: restrictionReason ?? this.restrictionReason,
      );
}

class BypassPattern {
  final String patternId;
  final String description;
  final RuntimeLawId violatedLaw;
  final SandboxViolationType violationType;
  final bool critical;

  const BypassPattern({
    required this.patternId,
    required this.description,
    required this.violatedLaw,
    required this.violationType,
    this.critical = false,
  });
}

class BypassDetectionResult {
  final bool bypassDetected;
  final BypassPattern? pattern;
  final String? evidence;

  const BypassDetectionResult({
    required this.bypassDetected,
    this.pattern,
    this.evidence,
  });

  factory BypassDetectionResult.clean() => const BypassDetectionResult(bypassDetected: false);
  factory BypassDetectionResult.detected(BypassPattern pattern, String evidence) =>
      BypassDetectionResult(bypassDetected: true, pattern: pattern, evidence: evidence);
}

class BypassDetector {
  static const List<BypassPattern> knownPatterns = [
    BypassPattern(
      patternId: 'direct-capability-call',
      description: 'Capability invoked without CapabilityRouter',
      violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
      violationType: SandboxViolationType.bypassAttempt,
      critical: true,
    ),
    BypassPattern(
      patternId: 'direct-thread-spawn',
      description: 'Thread/isolate created without Scheduler',
      violatedLaw: RuntimeLawId.noBypassScheduler,
      violationType: SandboxViolationType.bypassAttempt,
      critical: true,
    ),
    BypassPattern(
      patternId: 'global-state-access',
      description: 'Mutable global state accessed across sandbox boundary',
      violatedLaw: RuntimeLawId.noGlobalStateSharing,
      violationType: SandboxViolationType.bypassAttempt,
    ),
    BypassPattern(
      patternId: 'side-channel-socket',
      description: 'Hidden socket communication detected',
      violatedLaw: RuntimeLawId.noSideChannels,
      violationType: SandboxViolationType.bypassAttempt,
    ),
    BypassPattern(
      patternId: 'side-channel-file',
      description: 'Temp file used for inter-sandbox communication',
      violatedLaw: RuntimeLawId.noSideChannels,
      violationType: SandboxViolationType.bypassAttempt,
    ),
    BypassPattern(
      patternId: 'side-channel-cache',
      description: 'Shared cache used for inter-sandbox communication',
      violatedLaw: RuntimeLawId.noSideChannels,
      violationType: SandboxViolationType.bypassAttempt,
    ),
    BypassPattern(
      patternId: 'side-channel-singleton',
      description: 'In-memory singleton used for state sharing',
      violatedLaw: RuntimeLawId.noSideChannels,
      violationType: SandboxViolationType.bypassAttempt,
    ),
    BypassPattern(
      patternId: 'side-channel-static',
      description: 'Static variable used for state sharing',
      violatedLaw: RuntimeLawId.noSideChannels,
      violationType: SandboxViolationType.bypassAttempt,
    ),
    BypassPattern(
      patternId: 'side-channel-rpc',
      description: 'Hidden RPC communication detected',
      violatedLaw: RuntimeLawId.noSideChannels,
      violationType: SandboxViolationType.bypassAttempt,
    ),
    BypassPattern(
      patternId: 'untraced-operation',
      description: 'Operation executed without trace span',
      violatedLaw: RuntimeLawId.allOpsMustBeTraced,
      violationType: SandboxViolationType.bypassAttempt,
    ),
    BypassPattern(
      patternId: 'budget-bypass',
      description: 'Resource consumed without Budget approval',
      violatedLaw: RuntimeLawId.noBudgetBypass,
      violationType: SandboxViolationType.budgetExceeded,
    ),
    BypassPattern(
      patternId: 'trust-escalation',
      description: 'Lower-trust entity attempted higher-trust access',
      violatedLaw: RuntimeLawId.trustLevelMustBeRespected,
      violationType: SandboxViolationType.trustInsufficient,
      critical: true,
    ),
  ];

  BypassDetectionResult detect({
    required bool routedThroughRouter,
    required bool scheduledThroughScheduler,
    required bool accessedGlobalState,
    required bool usedSideChannel,
    required bool hasTraceSpan,
    required bool budgetApproved,
    required TrustLevel requiredTrust,
    required TrustLevel actualTrust,
  }) {
    if (!routedThroughRouter) {
      return BypassDetectionResult.detected(
        knownPatterns[0],
        'Capability call bypassed CapabilityRouter',
      );
    }

    if (!scheduledThroughScheduler) {
      return BypassDetectionResult.detected(
        knownPatterns[1],
        'Task created without Scheduler',
      );
    }

    if (accessedGlobalState) {
      return BypassDetectionResult.detected(
        knownPatterns[2],
        'Global state access detected',
      );
    }

    if (usedSideChannel) {
      return BypassDetectionResult.detected(
        knownPatterns[3],
        'Side channel communication detected',
      );
    }

    if (!hasTraceSpan) {
      return BypassDetectionResult.detected(
        knownPatterns[9],
        'Operation executed without trace span',
      );
    }

    if (!budgetApproved) {
      return BypassDetectionResult.detected(
        knownPatterns[10],
        'Resource consumed without Budget approval',
      );
    }

    if (actualTrust.index > requiredTrust.index) {
      return BypassDetectionResult.detected(
        knownPatterns[11],
        'Trust level ${actualTrust.name} insufficient for ${requiredTrust.name}',
      );
    }

    return BypassDetectionResult.clean();
  }

  BypassDetectionResult detectSideChannelType(String channelType) {
    final patternMap = {
      'socket': 3,
      'file': 4,
      'cache': 5,
      'singleton': 6,
      'static': 7,
      'rpc': 8,
    };

    final index = patternMap[channelType];
    if (index != null) {
      return BypassDetectionResult.detected(
        knownPatterns[index],
        'Side channel type: $channelType',
      );
    }

    return BypassDetectionResult.clean();
  }
}

class ConstitutionalGuard {
  final RuntimeLawEnforcer _enforcer;
  final BypassDetector _bypassDetector;
  final ViolationEscalationPolicy _escalationPolicy;
  final Map<String, EscalationState> _escalationStates = {};
  final List<ConstitutionalGuardEvent> _guardLog = [];
  final ConstitutionalTraceGraph _traceGraph;
  final ImmutableAuditLedger _ledger;
  final ConstitutionalEvolutionEngine _evolutionEngine;
  final ReputationEconomy _reputationEconomy;
  final RuntimeJudiciary _judiciary;
  final ConstitutionalConsensus? _consensus;
  final FederatedReputation? _federatedReputation;
  final AutonomousLegislature? _legislatureInit;
  AutonomousLegislature? _legislature;
  final CivilizationTransport? _transport;
  final CivilizationIdentity? _identity;
  final ResourceEconomy? _economy;
  final CivilizationNetwork? _network;

  ConstitutionalGuard._internal({
    required RuntimeLawEnforcer enforcer,
    required BypassDetector bypassDetector,
    required ViolationEscalationPolicy escalationPolicy,
    required ConstitutionalTraceGraph traceGraph,
    required ImmutableAuditLedger ledger,
    required ConstitutionalEvolutionEngine evolutionEngine,
    required ReputationEconomy reputationEconomy,
    required RuntimeJudiciary judiciary,
    required ConstitutionalConsensus? consensus,
    required FederatedReputation? federatedReputation,
    required AutonomousLegislature? legislature,
    required CivilizationTransport? transport,
    required CivilizationIdentity? identity,
    required ResourceEconomy? economy,
    required CivilizationNetwork? network,
  })  : _enforcer = enforcer,
        _bypassDetector = bypassDetector,
        _escalationPolicy = escalationPolicy,
        _traceGraph = traceGraph,
        _ledger = ledger,
        _evolutionEngine = evolutionEngine,
        _reputationEconomy = reputationEconomy,
        _judiciary = judiciary,
        _consensus = consensus,
        _federatedReputation = federatedReputation,
        _legislatureInit = legislature,
        _legislature = legislature,
        _transport = transport,
        _identity = identity,
        _economy = economy,
        _network = network;

  factory ConstitutionalGuard({
    required RuntimeLawEnforcer enforcer,
    ViolationEscalationPolicy escalationPolicy = const ViolationEscalationPolicy(),
    TrustDecayPolicy trustDecayPolicy = const TrustDecayPolicy(),
    String? nodeId,
    bool enableNetwork = false,
  }) {
    final sharedTraceGraph = ConstitutionalTraceGraph();
    final sharedLedger = ImmutableAuditLedger();
    final sharedReputationEconomy = ReputationEconomy(sharedTraceGraph, policy: trustDecayPolicy);
    final sharedJudiciary = RuntimeJudiciary(sharedTraceGraph, sharedLedger);
    return ConstitutionalGuard._internal(
      enforcer: enforcer,
      bypassDetector: BypassDetector(),
      escalationPolicy: escalationPolicy,
      traceGraph: sharedTraceGraph,
      ledger: sharedLedger,
      evolutionEngine: ConstitutionalEvolutionEngine(sharedTraceGraph),
      reputationEconomy: sharedReputationEconomy,
      judiciary: sharedJudiciary,
      consensus: nodeId != null ? ConstitutionalConsensus(localNodeId: nodeId, traceGraph: sharedTraceGraph) : null,
      federatedReputation: nodeId != null ? FederatedReputation(localRuntimeId: nodeId, traceGraph: sharedTraceGraph) : null,
      legislature: null,
      transport: nodeId != null ? CivilizationTransport(localNodeId: nodeId, traceGraph: sharedTraceGraph) : null,
      identity: nodeId != null ? CivilizationIdentity.generate(nodeId) : null,
      economy: nodeId != null ? ResourceEconomy(federationId: nodeId, ledger: sharedLedger) : null,
      network: (nodeId != null && enableNetwork) ? CivilizationNetwork(localNodeId: nodeId, traceGraph: sharedTraceGraph) : null,
    );
  }

  ConstitutionalGuard.withSharedState({
    required RuntimeLawEnforcer enforcer,
    required ConstitutionalTraceGraph traceGraph,
    required ImmutableAuditLedger ledger,
    ViolationEscalationPolicy escalationPolicy = const ViolationEscalationPolicy(),
    TrustDecayPolicy trustDecayPolicy = const TrustDecayPolicy(),
    String? nodeId,
    bool enableNetwork = false,
  })  : _enforcer = enforcer,
        _bypassDetector = BypassDetector(),
        _escalationPolicy = escalationPolicy,
        _traceGraph = traceGraph,
        _ledger = ledger,
        _evolutionEngine = ConstitutionalEvolutionEngine(traceGraph),
        _reputationEconomy = ReputationEconomy(traceGraph, policy: trustDecayPolicy),
        _judiciary = RuntimeJudiciary(traceGraph, ledger),
        _consensus = nodeId != null ? ConstitutionalConsensus(localNodeId: nodeId, traceGraph: traceGraph) : null,
        _federatedReputation = nodeId != null ? FederatedReputation(localRuntimeId: nodeId, traceGraph: traceGraph) : null,
        _legislatureInit = null,
        _legislature = null,
        _transport = nodeId != null ? CivilizationTransport(localNodeId: nodeId, traceGraph: traceGraph) : null,
        _identity = nodeId != null ? CivilizationIdentity.generate(nodeId) : null,
        _economy = nodeId != null ? ResourceEconomy(federationId: nodeId, ledger: ledger) : null,
        _network = (nodeId != null && enableNetwork) ? CivilizationNetwork(localNodeId: nodeId, traceGraph: traceGraph) : null;

  RuntimeLawEnforcer get enforcer => _enforcer;
  BypassDetector get bypassDetector => _bypassDetector;
  ViolationEscalationPolicy get escalationPolicy => _escalationPolicy;
  List<ConstitutionalGuardEvent> get guardLog => List.unmodifiable(_guardLog);
  ConstitutionalTraceGraph get traceGraph => _traceGraph;
  ImmutableAuditLedger get ledger => _ledger;
  ConstitutionalEvolutionEngine get evolutionEngine => _evolutionEngine;
  ReputationEconomy get reputationEconomy => _reputationEconomy;
  RuntimeJudiciary get judiciary => _judiciary;
  ConstitutionalConsensus? get consensus => _consensus;
  FederatedReputation? get federatedReputation => _federatedReputation;
  AutonomousLegislature? get legislature => _legislature;
  CivilizationTransport? get transport => _transport;
  CivilizationIdentity? get identity => _identity;
  ResourceEconomy? get economy => _economy;
  CivilizationNetwork? get network => _network;

  AutonomousLegislature enableLegislature() {
    if (_consensus == null) throw StateError('Cannot enable legislature without nodeId');
    final legislature = AutonomousLegislature(
      consensus: _consensus,
      traceGraph: _traceGraph,
      reputationEconomy: _reputationEconomy,
      judiciary: _judiciary,
    );
    _legislature = legislature;
    return legislature;
  }

  EscalationState escalationFor(String sandboxId) =>
      _escalationStates[sandboxId] ?? EscalationState(sandboxId: sandboxId);

  ConstitutionalCheckResult checkCapabilityInvocation({
    required String sandboxId,
    required String capabilityId,
    required String callerId,
    required TrustLevel callerTrust,
    required TrustLevel requiredTrust,
    required bool wasRoutedThroughRouter,
    required bool hasTraceSpan,
  }) {
    final escalation = escalationFor(sandboxId);
    final escBefore = escalation.level;

    if (escalation.level == EscalationLevel.terminated) {
      _log('capability.blocked', sandboxId, 'Sandbox terminated due to prior violations');
      _recordTrace(sandboxId, 'capability', null, false, capabilityId, callerId, callerTrust, escBefore);
      _appendLedger('capability.blocked', sandboxId, {'reason': 'terminated', 'cap': capabilityId});
      return ConstitutionalCheckResult.denied(
        reason: 'Sandbox terminated due to constitutional violations',
        violatedLaw: null,
      );
    }

    if (escalation.level == EscalationLevel.restricted) {
      _log('capability.restricted', sandboxId, 'Sandbox in restricted mode');
    }

    final routingResult = _enforcer.enforceCapabilityRouting(
      sandboxId, capabilityId, wasRoutedThroughRouter,
    );
    if (!routingResult.compliant) {
      _recordViolation(sandboxId, SandboxViolationType.bypassAttempt);
      _log('capability.blocked', sandboxId, 'CapabilityRouter bypass: $capabilityId');
      _recordTrace(sandboxId, 'capability', RuntimeLawId.noBypassCapabilityRouter, false, capabilityId, callerId, callerTrust, escBefore);
      _appendLedger('law.violation', sandboxId, {'law': 'noBypassCapabilityRouter', 'cap': capabilityId});
      return ConstitutionalCheckResult.denied(
        reason: routingResult.violation!,
        violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
      );
    }

    final trustResult = _enforcer.enforceTrustLevel(
      sandboxId, requiredTrust, callerTrust,
    );
    if (!trustResult.compliant) {
      _recordViolation(sandboxId, SandboxViolationType.trustInsufficient);
      _log('capability.blocked', sandboxId, 'Trust level violation: ${callerTrust.name} -> $requiredTrust');
      _recordTrace(sandboxId, 'capability', RuntimeLawId.trustLevelMustBeRespected, false, capabilityId, callerId, callerTrust, escBefore);
      _appendLedger('law.violation', sandboxId, {'law': 'trustLevelMustBeRespected', 'cap': capabilityId, 'caller': callerId});
      return ConstitutionalCheckResult.denied(
        reason: trustResult.violation!,
        violatedLaw: RuntimeLawId.trustLevelMustBeRespected,
      );
    }

    final traceResult = _enforcer.enforceTracing(sandboxId, hasTraceSpan);
    if (!traceResult.compliant) {
      _recordViolation(sandboxId, SandboxViolationType.bypassAttempt);
      _log('capability.blocked', sandboxId, 'Untraced capability invocation: $capabilityId');
      _recordTrace(sandboxId, 'capability', RuntimeLawId.allOpsMustBeTraced, false, capabilityId, callerId, callerTrust, escBefore);
      _appendLedger('law.violation', sandboxId, {'law': 'allOpsMustBeTraced', 'cap': capabilityId});
      return ConstitutionalCheckResult.denied(
        reason: traceResult.violation!,
        violatedLaw: RuntimeLawId.allOpsMustBeTraced,
      );
    }

    _log('capability.approved', sandboxId, 'Capability $capabilityId approved');
    _recordTrace(sandboxId, 'capability', null, true, capabilityId, callerId, callerTrust, escBefore);
    _appendLedger('capability.approved', sandboxId, {'cap': capabilityId, 'caller': callerId});
    _reputationEconomy.recordCompliance(sandboxId, _enforcer.clock.tick().physicalTime);
    return ConstitutionalCheckResult.allowed();
  }

  ConstitutionalCheckResult checkTaskCreation({
    required String sandboxId,
    required bool wasScheduledThroughScheduler,
    required bool budgetApproved,
    required bool hasTraceSpan,
  }) {
    final escalation = escalationFor(sandboxId);
    final escBefore = escalation.level;

    if (escalation.level == EscalationLevel.terminated) {
      _recordTrace(sandboxId, 'task', null, false, null, null, null, escBefore);
      _appendLedger('task.blocked', sandboxId, {'reason': 'terminated'});
      return ConstitutionalCheckResult.denied(
        reason: 'Sandbox terminated',
        violatedLaw: null,
      );
    }

    final schedulerResult = _enforcer.enforceSchedulerUsage(
      sandboxId, wasScheduledThroughScheduler,
    );
    if (!schedulerResult.compliant) {
      _recordViolation(sandboxId, SandboxViolationType.bypassAttempt);
      _recordTrace(sandboxId, 'task', RuntimeLawId.noBypassScheduler, false, null, null, null, escBefore);
      _appendLedger('law.violation', sandboxId, {'law': 'noBypassScheduler'});
      return ConstitutionalCheckResult.denied(
        reason: schedulerResult.violation!,
        violatedLaw: RuntimeLawId.noBypassScheduler,
      );
    }

    final budgetResult = _enforcer.enforceBudget(sandboxId, budgetApproved);
    if (!budgetResult.compliant) {
      _recordViolation(sandboxId, SandboxViolationType.budgetExceeded);
      _recordTrace(sandboxId, 'task', RuntimeLawId.noBudgetBypass, false, null, null, null, escBefore);
      _appendLedger('law.violation', sandboxId, {'law': 'noBudgetBypass'});
      return ConstitutionalCheckResult.denied(
        reason: budgetResult.violation!,
        violatedLaw: RuntimeLawId.noBudgetBypass,
      );
    }

    final traceResult = _enforcer.enforceTracing(sandboxId, hasTraceSpan);
    if (!traceResult.compliant) {
      _recordViolation(sandboxId, SandboxViolationType.bypassAttempt);
      _recordTrace(sandboxId, 'task', RuntimeLawId.allOpsMustBeTraced, false, null, null, null, escBefore);
      _appendLedger('law.violation', sandboxId, {'law': 'allOpsMustBeTraced'});
      return ConstitutionalCheckResult.denied(
        reason: traceResult.violation!,
        violatedLaw: RuntimeLawId.allOpsMustBeTraced,
      );
    }

    _recordTrace(sandboxId, 'task', null, true, null, null, null, escBefore);
    _appendLedger('task.approved', sandboxId, {});
    _reputationEconomy.recordCompliance(sandboxId, _enforcer.clock.tick().physicalTime);
    return ConstitutionalCheckResult.allowed();
  }

  ConstitutionalCheckResult checkStateAccess({
    required String sandboxId,
    required bool accessedGlobalState,
    required bool usedSideChannel,
    required bool hasTraceSpan,
  }) {
    final escalation = escalationFor(sandboxId);
    final escBefore = escalation.level;

    if (escalation.level == EscalationLevel.terminated) {
      _recordTrace(sandboxId, 'state', null, false, null, null, null, escBefore);
      _appendLedger('state.blocked', sandboxId, {'reason': 'terminated'});
      return ConstitutionalCheckResult.denied(
        reason: 'Sandbox terminated',
        violatedLaw: null,
      );
    }

    final globalStateResult = _enforcer.enforceNoGlobalState(sandboxId, accessedGlobalState);
    if (!globalStateResult.compliant) {
      _recordViolation(sandboxId, SandboxViolationType.bypassAttempt);
      _recordTrace(sandboxId, 'state', RuntimeLawId.noGlobalStateSharing, false, null, null, null, escBefore);
      _appendLedger('law.violation', sandboxId, {'law': 'noGlobalStateSharing'});
      return ConstitutionalCheckResult.denied(
        reason: globalStateResult.violation!,
        violatedLaw: RuntimeLawId.noGlobalStateSharing,
      );
    }

    final sideChannelResult = _enforcer.enforceNoSideChannels(sandboxId, usedSideChannel);
    if (!sideChannelResult.compliant) {
      _recordViolation(sandboxId, SandboxViolationType.bypassAttempt);
      _recordTrace(sandboxId, 'state', RuntimeLawId.noSideChannels, false, null, null, null, escBefore);
      _appendLedger('law.violation', sandboxId, {'law': 'noSideChannels'});
      return ConstitutionalCheckResult.denied(
        reason: sideChannelResult.violation!,
        violatedLaw: RuntimeLawId.noSideChannels,
      );
    }

    final traceResult = _enforcer.enforceTracing(sandboxId, hasTraceSpan);
    if (!traceResult.compliant) {
      _recordViolation(sandboxId, SandboxViolationType.bypassAttempt);
      _recordTrace(sandboxId, 'state', RuntimeLawId.allOpsMustBeTraced, false, null, null, null, escBefore);
      _appendLedger('law.violation', sandboxId, {'law': 'allOpsMustBeTraced'});
      return ConstitutionalCheckResult.denied(
        reason: traceResult.violation!,
        violatedLaw: RuntimeLawId.allOpsMustBeTraced,
      );
    }

    _recordTrace(sandboxId, 'state', null, true, null, null, null, escBefore);
    _appendLedger('state.approved', sandboxId, {});
    _reputationEconomy.recordCompliance(sandboxId, _enforcer.clock.tick().physicalTime);
    return ConstitutionalCheckResult.allowed();
  }

  BypassDetectionResult scanForBypass({
    required bool routedThroughRouter,
    required bool scheduledThroughScheduler,
    required bool accessedGlobalState,
    required bool usedSideChannel,
    required bool hasTraceSpan,
    required bool budgetApproved,
    required TrustLevel requiredTrust,
    required TrustLevel actualTrust,
  }) {
    return _bypassDetector.detect(
      routedThroughRouter: routedThroughRouter,
      scheduledThroughScheduler: scheduledThroughScheduler,
      accessedGlobalState: accessedGlobalState,
      usedSideChannel: usedSideChannel,
      hasTraceSpan: hasTraceSpan,
      budgetApproved: budgetApproved,
      requiredTrust: requiredTrust,
      actualTrust: actualTrust,
    );
  }

  EscalationLevel updateEscalation(String sandboxId, SandboxViolationType violationType) {
    final current = escalationFor(sandboxId);
    final weight = _escalationPolicy.weightFor(violationType);
    final newScore = current.weightedScore + weight;
    final newTotal = current.totalViolations + 1;

    EscalationLevel newLevel;
    String? reason;

    if (newScore >= _escalationPolicy.terminationThreshold) {
      newLevel = EscalationLevel.terminated;
      reason = 'Score $newScore reached termination threshold ${_escalationPolicy.terminationThreshold}';
    } else if (newScore >= _escalationPolicy.restrictedThreshold) {
      newLevel = EscalationLevel.restricted;
      reason = 'Score $newScore reached restricted threshold ${_escalationPolicy.restrictedThreshold}';
    } else if (newScore >= _escalationPolicy.warningThreshold) {
      newLevel = EscalationLevel.warning;
      reason = 'Score $newScore reached warning threshold ${_escalationPolicy.warningThreshold}';
    } else {
      newLevel = current.level;
    }

    _escalationStates[sandboxId] = current.copyWith(
      level: newLevel,
      weightedScore: newScore,
      totalViolations: newTotal,
      lastEscalationAt: _enforcer.clock.tick().physicalTime,
      restrictionReason: reason,
    );

    _log('escalation.${newLevel.name}', sandboxId, reason ?? 'Violation recorded (score: $newScore)');

    return newLevel;
  }

  bool shouldTerminate(String sandboxId) =>
      escalationFor(sandboxId).level == EscalationLevel.terminated;

  bool isRestricted(String sandboxId) =>
      escalationFor(sandboxId).level == EscalationLevel.restricted;

  void resetEscalation(String sandboxId) {
    _escalationStates.remove(sandboxId);
  }

  void _recordViolation(String sandboxId, SandboxViolationType type) {
    updateEscalation(sandboxId, type);
    _reputationEconomy.recordViolation(
      sandboxId,
      _enforcer.clock.tick().physicalTime,
      type: type,
    );
  }

  void _recordTrace(
    String sandboxId,
    String operationType,
    RuntimeLawId? violatedLaw,
    bool compliant,
    String? capabilityId,
    String? callerId,
    TrustLevel? callerTrust,
    EscalationLevel escBefore,
  ) {
    final escAfter = escalationFor(sandboxId).level;
    _traceGraph.record(
      sandboxId: sandboxId,
      operationType: operationType,
      violatedLaw: violatedLaw,
      compliant: compliant,
      capabilityId: capabilityId,
      callerId: callerId,
      callerTrust: callerTrust,
      escalationBefore: escBefore,
      escalationAfter: escAfter,
      timestamp: _enforcer.clock.tick().physicalTime,
    );
  }

  void _appendLedger(String entryType, String sandboxId, Map<String, dynamic> data) {
    _ledger.append(
      entryType: entryType,
      sandboxId: sandboxId,
      data: data,
      timestamp: _enforcer.clock.tick().physicalTime,
    );
  }

  void _log(String action, String sandboxId, String detail) {
    _guardLog.add(ConstitutionalGuardEvent(
      action: action,
      sandboxId: sandboxId,
      detail: detail,
      timestamp: _enforcer.clock.tick().physicalTime,
    ));
  }
}

class ConstitutionalCheckResult {
  final bool allowed;
  final String? reason;
  final RuntimeLawId? violatedLaw;

  const ConstitutionalCheckResult._({
    required this.allowed,
    this.reason,
    this.violatedLaw,
  });

  factory ConstitutionalCheckResult.allowed() =>
      const ConstitutionalCheckResult._(allowed: true);
  factory ConstitutionalCheckResult.denied({
    required String reason,
    required RuntimeLawId? violatedLaw,
  }) =>
      ConstitutionalCheckResult._(allowed: false, reason: reason, violatedLaw: violatedLaw);
}

class ConstitutionalGuardEvent {
  final String action;
  final String sandboxId;
  final String detail;
  final int timestamp;

  const ConstitutionalGuardEvent({
    required this.action,
    required this.sandboxId,
    required this.detail,
    required this.timestamp,
  });
}
