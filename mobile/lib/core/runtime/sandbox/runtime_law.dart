import '../distributed/hybrid_logical_clock.dart';
import '../stability/security.dart';

enum RuntimeLawId {
  noBypassCapabilityRouter,
  noBypassScheduler,
  noGlobalStateSharing,
  noSideChannels,
  noUntracedOperations,
  noBudgetBypass,
  noDirectThreadCreation,
  allOpsMustBeJournaled,
  allOpsMustBeTraced,
  trustLevelMustBeRespected,
}

class RuntimeLaw {
  final RuntimeLawId id;
  final String description;
  final String enforcement;

  const RuntimeLaw({
    required this.id,
    required this.description,
    required this.enforcement,
  });
}

class RuntimeConstitution {
  static final List<RuntimeLaw> laws = [
    RuntimeLaw(
      id: RuntimeLawId.noBypassCapabilityRouter,
      description: 'All capability invocations must go through CapabilityRouter. '
          'No direct plugin-to-plugin calls.',
      enforcement: 'CapabilityAccessResult.denied for any invocation not routed through CapabilityRouter.',
    ),
    RuntimeLaw(
      id: RuntimeLawId.noBypassScheduler,
      description: 'All task scheduling must go through Scheduler. '
          'No direct thread or async spawn outside Budget control.',
      enforcement: 'SandboxViolation.taskLimitExceeded for any task not registered with Scheduler.',
    ),
    RuntimeLaw(
      id: RuntimeLawId.noGlobalStateSharing,
      description: 'No sharing of mutable global state between sandboxes. '
          'All state communication must go through Event Bus or Capability invocation.',
      enforcement: 'SandboxViolation.bypassAttempt for any detected global state access.',
    ),
    RuntimeLaw(
      id: RuntimeLawId.noSideChannels,
      description: 'No side-channel communication between execution units. '
          'All communication must be through Runtime Wire Protocol.',
      enforcement: 'SandboxViolation.bypassAttempt for any detected side channel.',
    ),
    RuntimeLaw(
      id: RuntimeLawId.noUntracedOperations,
      description: 'All operations must be traced. No operation may execute without a trace span.',
      enforcement: 'Audit entry created for any untraced operation detection.',
    ),
    RuntimeLaw(
      id: RuntimeLawId.noBudgetBypass,
      description: 'All resource consumption must be accounted for in Budget. '
          'No resource may be consumed without Budget approval.',
      enforcement: 'SandboxViolation.budgetExceeded for any unaccounted resource consumption.',
    ),
    RuntimeLaw(
      id: RuntimeLawId.noDirectThreadCreation,
      description: 'No direct thread or isolate creation. All concurrency must go through Scheduler.',
      enforcement: 'SandboxViolation.bypassAttempt for any direct thread creation.',
    ),
    RuntimeLaw(
      id: RuntimeLawId.allOpsMustBeJournaled,
      description: 'All state mutations must be recorded in Event Journal. '
          'No state change may occur without a journal entry.',
      enforcement: 'Audit entry for any unjournaled state change.',
    ),
    RuntimeLaw(
      id: RuntimeLawId.allOpsMustBeTraced,
      description: 'All distributed operations must propagate trace context. '
          'No remote call may be made without trace propagation headers.',
      enforcement: 'Audit entry for any untraced remote call.',
    ),
    RuntimeLaw(
      id: RuntimeLawId.trustLevelMustBeRespected,
      description: 'Trust level hierarchy must be respected. '
          'No lower-trust entity may access higher-trust resources.',
      enforcement: 'SandboxViolation.trustInsufficient for any trust level violation.',
    ),
  ];

  static bool addAmendment(RuntimeLaw law) {
    if (laws.any((l) => l.id == law.id)) return false;
    laws.add(law);
    return true;
  }

  static bool removeAmendment(RuntimeLawId id) {
    final before = laws.length;
    laws.removeWhere((l) => l.id == id);
    return laws.length < before;
  }
}

class LawEnforcementResult {
  final RuntimeLawId lawId;
  final bool compliant;
  final String? violation;
  final String sandboxId;

  const LawEnforcementResult({
    required this.lawId,
    required this.compliant,
    this.violation,
    required this.sandboxId,
  });
}

class RuntimeLawEnforcer {
  final HybridLogicalClock _clock;
  final SecurityManager _securityManager;
  final List<LawEnforcementResult> _enforcementLog = [];

  RuntimeLawEnforcer({
    required HybridLogicalClock clock,
    required SecurityManager securityManager,
  })  : _clock = clock,
        _securityManager = securityManager;

  List<LawEnforcementResult> get enforcementLog => List.unmodifiable(_enforcementLog);
  HybridLogicalClock get clock => _clock;

  LawEnforcementResult enforceCapabilityRouting(
    String sandboxId,
    String capabilityId,
    bool wasRoutedThroughRouter,
  ) {
    final result = LawEnforcementResult(
      lawId: RuntimeLawId.noBypassCapabilityRouter,
      compliant: wasRoutedThroughRouter,
      violation: wasRoutedThroughRouter ? null : 'Capability $capabilityId invoked without CapabilityRouter',
      sandboxId: sandboxId,
    );

    _enforcementLog.add(result);
    if (!result.compliant) {
      _securityManager.audit('law.violation', sandboxId,
          context: {'law': RuntimeLawId.noBypassCapabilityRouter.name, 'capability': capabilityId},
          success: false);
    }
    return result;
  }

  LawEnforcementResult enforceSchedulerUsage(
    String sandboxId,
    bool wasScheduledThroughScheduler,
  ) {
    final result = LawEnforcementResult(
      lawId: RuntimeLawId.noBypassScheduler,
      compliant: wasScheduledThroughScheduler,
      violation: wasScheduledThroughScheduler ? null : 'Task created without Scheduler',
      sandboxId: sandboxId,
    );

    _enforcementLog.add(result);
    if (!result.compliant) {
      _securityManager.audit('law.violation', sandboxId,
          context: {'law': RuntimeLawId.noBypassScheduler.name}, success: false);
    }
    return result;
  }

  LawEnforcementResult enforceNoGlobalState(
    String sandboxId,
    bool accessedGlobalState,
  ) {
    final result = LawEnforcementResult(
      lawId: RuntimeLawId.noGlobalStateSharing,
      compliant: !accessedGlobalState,
      violation: accessedGlobalState ? 'Global state access detected' : null,
      sandboxId: sandboxId,
    );

    _enforcementLog.add(result);
    if (!result.compliant) {
      _securityManager.audit('law.violation', sandboxId,
          context: {'law': RuntimeLawId.noGlobalStateSharing.name}, success: false);
    }
    return result;
  }

  LawEnforcementResult enforceNoSideChannels(
    String sandboxId,
    bool usedSideChannel,
  ) {
    final result = LawEnforcementResult(
      lawId: RuntimeLawId.noSideChannels,
      compliant: !usedSideChannel,
      violation: usedSideChannel ? 'Side channel communication detected' : null,
      sandboxId: sandboxId,
    );

    _enforcementLog.add(result);
    if (!result.compliant) {
      _securityManager.audit('law.violation', sandboxId,
          context: {'law': RuntimeLawId.noSideChannels.name}, success: false);
    }
    return result;
  }

  LawEnforcementResult enforceTracing(
    String sandboxId,
    bool hasTraceSpan,
  ) {
    final result = LawEnforcementResult(
      lawId: RuntimeLawId.allOpsMustBeTraced,
      compliant: hasTraceSpan,
      violation: hasTraceSpan ? null : 'Operation executed without trace span',
      sandboxId: sandboxId,
    );

    _enforcementLog.add(result);
    if (!result.compliant) {
      _securityManager.audit('law.violation', sandboxId,
          context: {'law': RuntimeLawId.allOpsMustBeTraced.name}, success: false);
    }
    return result;
  }

  LawEnforcementResult enforceBudget(
    String sandboxId,
    bool wasBudgetApproved,
  ) {
    final result = LawEnforcementResult(
      lawId: RuntimeLawId.noBudgetBypass,
      compliant: wasBudgetApproved,
      violation: wasBudgetApproved ? null : 'Resource consumed without Budget approval',
      sandboxId: sandboxId,
    );

    _enforcementLog.add(result);
    if (!result.compliant) {
      _securityManager.audit('law.violation', sandboxId,
          context: {'law': RuntimeLawId.noBudgetBypass.name}, success: false);
    }
    return result;
  }

  LawEnforcementResult enforceTrustLevel(
    String sandboxId,
    TrustLevel requiredLevel,
    TrustLevel actualLevel,
  ) {
    final compliant = actualLevel.index <= requiredLevel.index;
    final result = LawEnforcementResult(
      lawId: RuntimeLawId.trustLevelMustBeRespected,
      compliant: compliant,
      violation: compliant ? null : 'Trust level ${actualLevel.name} insufficient for ${requiredLevel.name}',
      sandboxId: sandboxId,
    );

    _enforcementLog.add(result);
    return result;
  }

  List<LawEnforcementResult> violationsFor(String sandboxId) =>
      _enforcementLog.where((r) => !r.compliant && r.sandboxId == sandboxId).toList();

  int totalViolations() => _enforcementLog.where((r) => !r.compliant).length;

  void clearLog() => _enforcementLog.clear();
}
