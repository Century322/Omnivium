import '../governance/resource_controller.dart';
import '../governance/policy_engine.dart';
import '../distributed/hybrid_logical_clock.dart';
import '../stability/security.dart';
import 'constitutional_guard.dart';

enum SandboxState { created, running, suspended, terminated }

enum SandboxType { plugin, agent, miniApp, tool, mcpServer, workflow }

class SandboxResources {
  final ResourceBudget budget;
  final ResourceUsage usage;
  final Set<String> allowedCapabilities;
  final Set<String> deniedCapabilities;
  final TrustBoundary trustBoundary;
  final Duration maxExecutionTime;
  final int maxMemoryBytes;
  final int maxConcurrentTasks;

  const SandboxResources({
    required this.budget,
    required this.usage,
    this.allowedCapabilities = const {},
    this.deniedCapabilities = const {},
    required this.trustBoundary,
    this.maxExecutionTime = const Duration(seconds: 60),
    this.maxMemoryBytes = 256 * 1024 * 1024,
    this.maxConcurrentTasks = 10,
  });

  SandboxResources copyWith({
    ResourceBudget? budget,
    ResourceUsage? usage,
    Set<String>? allowedCapabilities,
    Set<String>? deniedCapabilities,
    TrustBoundary? trustBoundary,
    Duration? maxExecutionTime,
    int? maxMemoryBytes,
    int? maxConcurrentTasks,
  }) => SandboxResources(
    budget: budget ?? this.budget,
    usage: usage ?? this.usage,
    allowedCapabilities: allowedCapabilities ?? this.allowedCapabilities,
    deniedCapabilities: deniedCapabilities ?? this.deniedCapabilities,
    trustBoundary: trustBoundary ?? this.trustBoundary,
    maxExecutionTime: maxExecutionTime ?? this.maxExecutionTime,
    maxMemoryBytes: maxMemoryBytes ?? this.maxMemoryBytes,
    maxConcurrentTasks: maxConcurrentTasks ?? this.maxConcurrentTasks,
  );

  bool isCapabilityAllowed(String capabilityId) {
    if (deniedCapabilities.contains(capabilityId)) return false;
    if (!trustBoundary.isCapabilityAllowed(capabilityId)) return false;
    if (allowedCapabilities.isEmpty) return true;
    return allowedCapabilities.contains(capabilityId) ||
        allowedCapabilities.contains('*');
  }

  bool hasBudgetRemaining() =>
      usage.tokensUsed < budget.maxTokens &&
      usage.activeStreams < budget.maxStreams &&
      usage.activeTasks < budget.maxTasks;
}

class SandboxIdentity {
  final String sandboxId;
  final SandboxType type;
  final String pluginId;
  final TrustLevel trustLevel;
  final String createdBy;
  final int createdAt;

  const SandboxIdentity({
    required this.sandboxId,
    required this.type,
    required this.pluginId,
    required this.trustLevel,
    required this.createdBy,
    required this.createdAt,
  });

  String get runtimeIdentity => 'sandbox:$sandboxId:$pluginId';
}

class SandboxIsolate {
  final SandboxIdentity identity;
  final SandboxResources resources;
  final HybridLogicalClock clock;
  final PolicyEngine policyEngine;
  final SecurityManager securityManager;
  final ConstitutionalGuard? constitutionalGuard;

  SandboxState _state = SandboxState.created;
  int _startedAt = 0;
  int _terminatedAt = 0;
  String? _terminationReason;
  final List<SandboxViolation> _violations = [];
  final List<String> _auditTrail = [];

  SandboxIsolate({
    required this.identity,
    required this.resources,
    required this.clock,
    required this.policyEngine,
    required this.securityManager,
    this.constitutionalGuard,
  });

  SandboxState get state => _state;
  int get startedAt => _startedAt;
  int get terminatedAt => _terminatedAt;
  String? get terminationReason => _terminationReason;
  List<SandboxViolation> get violations => List.unmodifiable(_violations);
  bool get isRunning => _state == SandboxState.running;
  bool get isTerminated => _state == SandboxState.terminated;

  void start() {
    if (_state != SandboxState.created) {
      throw StateError(
        'Sandbox can only start from created state, current: $_state',
      );
    }
    _state = SandboxState.running;
    _startedAt = clock.tick().physicalTime;
    _audit('sandbox.start', {'trustLevel': identity.trustLevel.name});
  }

  void suspend() {
    if (_state != SandboxState.running) return;
    _state = SandboxState.suspended;
    _audit('sandbox.suspend', {});
  }

  void resume() {
    if (_state != SandboxState.suspended) return;
    _state = SandboxState.running;
    _audit('sandbox.resume', {});
  }

  void terminate(String reason) {
    if (_state == SandboxState.terminated) return;
    _state = SandboxState.terminated;
    _terminatedAt = clock.tick().physicalTime;
    _terminationReason = reason;
    _audit('sandbox.terminate', {'reason': reason});
  }

  bool tryAcquireTokens(int count, {bool hasTraceSpan = true}) {
    if (!isRunning) return false;

    if (constitutionalGuard != null) {
      final guardResult = constitutionalGuard!.checkTaskCreation(
        sandboxId: identity.sandboxId,
        wasScheduledThroughScheduler: true,
        budgetApproved:
            resources.usage.tokensUsed + count <= resources.budget.maxTokens,
        hasTraceSpan: hasTraceSpan,
      );
      if (!guardResult.allowed) {
        _recordViolation(
          SandboxViolationType.budgetExceeded,
          guardResult.reason ?? 'Constitutional guard denied token acquisition',
        );
        _checkGuardTermination();
        return false;
      }
    }

    if (resources.usage.tokensUsed + count > resources.budget.maxTokens) {
      _recordViolation(
        SandboxViolationType.budgetExceeded,
        'Token budget exceeded',
      );
      return false;
    }
    resources.usage.tokensUsed += count;
    return true;
  }

  bool tryAcquireTask({
    bool wasScheduledThroughScheduler = true,
    bool hasTraceSpan = true,
  }) {
    if (!isRunning) return false;

    if (constitutionalGuard != null) {
      final guardResult = constitutionalGuard!.checkTaskCreation(
        sandboxId: identity.sandboxId,
        wasScheduledThroughScheduler: wasScheduledThroughScheduler,
        budgetApproved:
            resources.usage.activeTasks < resources.maxConcurrentTasks,
        hasTraceSpan: hasTraceSpan,
      );
      if (!guardResult.allowed) {
        _recordViolation(
          SandboxViolationType.bypassAttempt,
          guardResult.reason ?? 'Constitutional guard denied task creation',
        );
        _checkGuardTermination();
        return false;
      }
    }

    if (resources.usage.activeTasks >= resources.maxConcurrentTasks) {
      _recordViolation(
        SandboxViolationType.taskLimitExceeded,
        'Task limit exceeded',
      );
      return false;
    }
    resources.usage.activeTasks++;
    return true;
  }

  bool tryAcquireStream({bool hasTraceSpan = true}) {
    if (!isRunning) return false;

    if (constitutionalGuard != null) {
      final guardResult = constitutionalGuard!.checkTaskCreation(
        sandboxId: identity.sandboxId,
        wasScheduledThroughScheduler: true,
        budgetApproved:
            resources.usage.activeStreams < resources.budget.maxStreams,
        hasTraceSpan: hasTraceSpan,
      );
      if (!guardResult.allowed) {
        _recordViolation(
          SandboxViolationType.streamLimitExceeded,
          guardResult.reason ?? 'Constitutional guard denied stream',
        );
        _checkGuardTermination();
        return false;
      }
    }

    if (resources.usage.activeStreams >= resources.budget.maxStreams) {
      _recordViolation(
        SandboxViolationType.streamLimitExceeded,
        'Stream limit exceeded',
      );
      return false;
    }
    resources.usage.activeStreams++;
    return true;
  }

  CapabilityAccessResult checkCapabilityAccess(
    String capabilityId, {
    bool wasRoutedThroughRouter = true,
    bool hasTraceSpan = true,
  }) {
    if (!isRunning) {
      return CapabilityAccessResult.denied('Sandbox not running');
    }

    if (constitutionalGuard != null) {
      final guardResult = constitutionalGuard!.checkCapabilityInvocation(
        sandboxId: identity.sandboxId,
        capabilityId: capabilityId,
        callerId: identity.pluginId,
        callerTrust: identity.trustLevel,
        requiredTrust: securityManager.policy.minimumPluginTrustLevel,
        wasRoutedThroughRouter: wasRoutedThroughRouter,
        hasTraceSpan: hasTraceSpan,
      );

      if (!guardResult.allowed) {
        _recordViolation(
          SandboxViolationType.bypassAttempt,
          guardResult.reason ?? 'Constitutional guard denied',
        );
        return CapabilityAccessResult.denied(
          guardResult.reason ?? 'Constitutional guard denied',
        );
      }

      if (constitutionalGuard!.shouldTerminate(identity.sandboxId)) {
        terminate('constitutional_violation_escalation');
        return CapabilityAccessResult.denied(
          'Sandbox terminated by constitutional guard',
        );
      }
    }

    if (!resources.isCapabilityAllowed(capabilityId)) {
      _recordViolation(
        SandboxViolationType.capabilityDenied,
        'Capability denied: $capabilityId',
      );
      return CapabilityAccessResult.denied(
        'Capability not allowed: $capabilityId',
      );
    }

    final policyDecision = policyEngine.evaluate(
      callerId: identity.pluginId,
      targetCapability: capabilityId,
    );

    if (!policyDecision.allowed) {
      _recordViolation(
        SandboxViolationType.policyDenied,
        'Policy denied: ${policyDecision.matchedRuleId}',
      );
      return CapabilityAccessResult.denied(
        'Policy denied: ${policyDecision.matchedRuleId}',
      );
    }

    if (!securityManager.isCapabilityInvocationAllowed(
      capabilityId,
      identity.runtimeIdentity,
      identity.trustLevel,
    )) {
      _recordViolation(
        SandboxViolationType.trustInsufficient,
        'Trust level insufficient for: $capabilityId',
      );
      return CapabilityAccessResult.denied('Trust level insufficient');
    }

    return CapabilityAccessResult.allowed();
  }

  bool checkExecutionTime() {
    if (!isRunning) return false;
    final now = clock.tick().physicalTime;
    final elapsed = now - _startedAt;
    if (elapsed > resources.maxExecutionTime.inMilliseconds) {
      _recordViolation(
        SandboxViolationType.executionTimeExceeded,
        'Execution time exceeded',
      );
      terminate('execution_time_exceeded');
      return false;
    }
    return true;
  }

  void _recordViolation(SandboxViolationType type, String message) {
    _violations.add(
      SandboxViolation(
        type: type,
        message: message,
        timestamp: clock.tick().physicalTime,
        sandboxId: identity.sandboxId,
      ),
    );
  }

  void _audit(String action, Map<String, dynamic> data) {
    _auditTrail.add('$action@${clock.now.physicalTime}: $data');
  }

  void _checkGuardTermination() {
    if (constitutionalGuard != null &&
        constitutionalGuard!.shouldTerminate(identity.sandboxId)) {
      terminate('constitutional_violation_escalation');
    }
  }
}

enum SandboxViolationType {
  budgetExceeded,
  taskLimitExceeded,
  streamLimitExceeded,
  capabilityDenied,
  policyDenied,
  trustInsufficient,
  executionTimeExceeded,
  memoryExceeded,
  bypassAttempt,
}

class SandboxViolation {
  final SandboxViolationType type;
  final String message;
  final int timestamp;
  final String sandboxId;

  const SandboxViolation({
    required this.type,
    required this.message,
    required this.timestamp,
    required this.sandboxId,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'message': message,
    'timestamp': timestamp,
    'sandboxId': sandboxId,
  };
}

class CapabilityAccessResult {
  final bool allowed;
  final String? reason;

  const CapabilityAccessResult._({required this.allowed, this.reason});

  factory CapabilityAccessResult.allowed() =>
      const CapabilityAccessResult._(allowed: true);
  factory CapabilityAccessResult.denied(String reason) =>
      CapabilityAccessResult._(allowed: false, reason: reason);
}

class ExecutionGovernor {
  final Map<String, SandboxIsolate> _sandboxes = {};
  final SecurityManager _securityManager;
  final HybridLogicalClock _clock;
  final ConstitutionalGuard? _constitutionalGuard;
  int _sandboxSeq = 0;

  ExecutionGovernor({
    required SecurityManager securityManager,
    required HybridLogicalClock clock,
    ConstitutionalGuard? constitutionalGuard,
  }) : _securityManager = securityManager,
       _clock = clock,
       _constitutionalGuard = constitutionalGuard;

  int get activeSandboxCount =>
      _sandboxes.values.where((s) => s.isRunning).length;
  int get totalSandboxCount => _sandboxes.length;
  List<SandboxIsolate> get runningSandboxes =>
      _sandboxes.values.where((s) => s.isRunning).toList();
  List<SandboxIsolate> get allSandboxes => _sandboxes.values.toList();

  SandboxIsolate? get(String sandboxId) => _sandboxes[sandboxId];

  SandboxIsolate create({
    required SandboxType type,
    required String pluginId,
    required TrustLevel trustLevel,
    required SandboxResources resources,
    String createdBy = 'system',
  }) {
    final sandboxId = 'sandbox_${_sandboxSeq++}';
    final identity = SandboxIdentity(
      sandboxId: sandboxId,
      type: type,
      pluginId: pluginId,
      trustLevel: trustLevel,
      createdBy: createdBy,
      createdAt: _clock.tick().physicalTime,
    );

    final sandbox = SandboxIsolate(
      identity: identity,
      resources: resources,
      clock: HybridLogicalClock(nodeId: sandboxId),
      policyEngine: PolicyEngine.defaultPolicy(),
      securityManager: _securityManager,
      constitutionalGuard: _constitutionalGuard,
    );

    _sandboxes[sandboxId] = sandbox;
    _securityManager.audit(
      'sandbox.create',
      createdBy,
      context: {
        'sandboxId': sandboxId,
        'type': type.name,
        'trustLevel': trustLevel.name,
      },
    );

    return sandbox;
  }

  bool terminate(String sandboxId, String reason) {
    final sandbox = _sandboxes[sandboxId];
    if (sandbox == null) return false;

    sandbox.terminate(reason);
    _securityManager.audit(
      'sandbox.terminate',
      sandbox.identity.createdBy,
      context: {'sandboxId': sandboxId, 'reason': reason},
    );

    return true;
  }

  void enforceRuntimeLaw() {
    for (final sandbox in _sandboxes.values) {
      if (sandbox.isRunning) {
        sandbox.checkExecutionTime();
        if (sandbox.resources.usage.tokensUsed >
            sandbox.resources.budget.maxTokens) {
          sandbox._recordViolation(
            SandboxViolationType.budgetExceeded,
            'Token budget exceeded during law enforcement',
          );
        }
        if (sandbox.resources.usage.activeTasks >
            sandbox.resources.maxConcurrentTasks) {
          sandbox._recordViolation(
            SandboxViolationType.taskLimitExceeded,
            'Task limit exceeded during law enforcement',
          );
        }
        if (sandbox.resources.usage.activeStreams >
            sandbox.resources.budget.maxStreams) {
          sandbox._recordViolation(
            SandboxViolationType.streamLimitExceeded,
            'Stream limit exceeded during law enforcement',
          );
        }
      }
    }
  }

  void cleanupTerminated() {
    final terminated = _sandboxes.entries
        .where((e) => e.value.isTerminated)
        .map((e) => e.key)
        .toList();

    for (final id in terminated) {
      _sandboxes.remove(id);
    }
  }

  List<SandboxViolation> allViolations() {
    return _sandboxes.values.expand((s) => s.violations).toList();
  }

  void clear() => _sandboxes.clear();
}
