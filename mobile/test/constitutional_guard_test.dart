import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/sandbox_runtime.dart';
import 'package:omnivium/core/runtime/sandbox/runtime_law.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_guard.dart';
import 'package:omnivium/core/runtime/governance/resource_controller.dart';
import 'package:omnivium/core/runtime/governance/policy_engine.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/stability/security.dart';

void main() {
  group('ConstitutionalGuard — Capability Invocation', () {
    late HybridLogicalClock clock;
    late SecurityManager securityManager;
    late RuntimeLawEnforcer enforcer;
    late ConstitutionalGuard guard;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'guard-test');
      securityManager = SecurityManager();
      enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );
      guard = ConstitutionalGuard(enforcer: enforcer);
    });

    test('legitimate capability invocation passes all checks', () {
      final result = guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );

      expect(result.allowed, isTrue);
    });

    test('bypassing CapabilityRouter is blocked by constitutional guard', () {
      final result = guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: false,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.noBypassCapabilityRouter);
      expect(result.reason, contains('CapabilityRouter'));
    });

    test('trust level violation is blocked by constitutional guard', () {
      final result = guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'runtime.admin',
        callerId: 'untrusted.plugin',
        callerTrust: TrustLevel.untrusted,
        requiredTrust: TrustLevel.system,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.trustLevelMustBeRespected);
    });

    test('untraced operation is blocked by constitutional guard', () {
      final result = guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: false,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.allOpsMustBeTraced);
    });

    test('terminated sandbox cannot invoke capabilities', () {
      guard.updateEscalation('sb-1', SandboxViolationType.bypassAttempt);
      guard.updateEscalation('sb-1', SandboxViolationType.bypassAttempt);
      guard.updateEscalation('sb-1', SandboxViolationType.bypassAttempt);
      guard.updateEscalation('sb-1', SandboxViolationType.bypassAttempt);

      final result = guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.reason, contains('terminated'));
    });
  });

  group('ConstitutionalGuard — Task Creation', () {
    late ConstitutionalGuard guard;

    setUp(() {
      final clock = HybridLogicalClock(nodeId: 'guard-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );
      guard = ConstitutionalGuard(enforcer: enforcer);
    });

    test('legitimate task creation passes all checks', () {
      final result = guard.checkTaskCreation(
        sandboxId: 'sb-1',
        wasScheduledThroughScheduler: true,
        budgetApproved: true,
        hasTraceSpan: true,
      );

      expect(result.allowed, isTrue);
    });

    test('bypassing Scheduler is blocked', () {
      final result = guard.checkTaskCreation(
        sandboxId: 'sb-1',
        wasScheduledThroughScheduler: false,
        budgetApproved: true,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.noBypassScheduler);
    });

    test('budget bypass is blocked', () {
      final result = guard.checkTaskCreation(
        sandboxId: 'sb-1',
        wasScheduledThroughScheduler: true,
        budgetApproved: false,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.noBudgetBypass);
    });

    test('untraced task creation is blocked', () {
      final result = guard.checkTaskCreation(
        sandboxId: 'sb-1',
        wasScheduledThroughScheduler: true,
        budgetApproved: true,
        hasTraceSpan: false,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.allOpsMustBeTraced);
    });
  });

  group('ConstitutionalGuard — State Access', () {
    late ConstitutionalGuard guard;

    setUp(() {
      final clock = HybridLogicalClock(nodeId: 'guard-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );
      guard = ConstitutionalGuard(enforcer: enforcer);
    });

    test('legitimate state access passes', () {
      final result = guard.checkStateAccess(
        sandboxId: 'sb-1',
        accessedGlobalState: false,
        usedSideChannel: false,
        hasTraceSpan: true,
      );

      expect(result.allowed, isTrue);
    });

    test('global state access is blocked', () {
      final result = guard.checkStateAccess(
        sandboxId: 'sb-1',
        accessedGlobalState: true,
        usedSideChannel: false,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.noGlobalStateSharing);
    });

    test('side channel is blocked', () {
      final result = guard.checkStateAccess(
        sandboxId: 'sb-1',
        accessedGlobalState: false,
        usedSideChannel: true,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.noSideChannels);
    });
  });

  group('BypassDetector', () {
    late BypassDetector detector;

    setUp(() {
      detector = BypassDetector();
    });

    test('clean operation returns no bypass', () {
      final result = detector.detect(
        routedThroughRouter: true,
        scheduledThroughScheduler: true,
        accessedGlobalState: false,
        usedSideChannel: false,
        hasTraceSpan: true,
        budgetApproved: true,
        requiredTrust: TrustLevel.verified,
        actualTrust: TrustLevel.verified,
      );

      expect(result.bypassDetected, isFalse);
    });

    test('detects CapabilityRouter bypass', () {
      final result = detector.detect(
        routedThroughRouter: false,
        scheduledThroughScheduler: true,
        accessedGlobalState: false,
        usedSideChannel: false,
        hasTraceSpan: true,
        budgetApproved: true,
        requiredTrust: TrustLevel.verified,
        actualTrust: TrustLevel.verified,
      );

      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'direct-capability-call');
      expect(result.pattern!.critical, isTrue);
    });

    test('detects Scheduler bypass', () {
      final result = detector.detect(
        routedThroughRouter: true,
        scheduledThroughScheduler: false,
        accessedGlobalState: false,
        usedSideChannel: false,
        hasTraceSpan: true,
        budgetApproved: true,
        requiredTrust: TrustLevel.verified,
        actualTrust: TrustLevel.verified,
      );

      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'direct-thread-spawn');
      expect(result.pattern!.critical, isTrue);
    });

    test('detects global state access', () {
      final result = detector.detect(
        routedThroughRouter: true,
        scheduledThroughScheduler: true,
        accessedGlobalState: true,
        usedSideChannel: false,
        hasTraceSpan: true,
        budgetApproved: true,
        requiredTrust: TrustLevel.verified,
        actualTrust: TrustLevel.verified,
      );

      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.violatedLaw, RuntimeLawId.noGlobalStateSharing);
    });

    test('detects side channel', () {
      final result = detector.detect(
        routedThroughRouter: true,
        scheduledThroughScheduler: true,
        accessedGlobalState: false,
        usedSideChannel: true,
        hasTraceSpan: true,
        budgetApproved: true,
        requiredTrust: TrustLevel.verified,
        actualTrust: TrustLevel.verified,
      );

      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.violatedLaw, RuntimeLawId.noSideChannels);
    });

    test('detects untraced operation', () {
      final result = detector.detect(
        routedThroughRouter: true,
        scheduledThroughScheduler: true,
        accessedGlobalState: false,
        usedSideChannel: false,
        hasTraceSpan: false,
        budgetApproved: true,
        requiredTrust: TrustLevel.verified,
        actualTrust: TrustLevel.verified,
      );

      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'untraced-operation');
    });

    test('detects budget bypass', () {
      final result = detector.detect(
        routedThroughRouter: true,
        scheduledThroughScheduler: true,
        accessedGlobalState: false,
        usedSideChannel: false,
        hasTraceSpan: true,
        budgetApproved: false,
        requiredTrust: TrustLevel.verified,
        actualTrust: TrustLevel.verified,
      );

      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'budget-bypass');
    });

    test('detects trust escalation', () {
      final result = detector.detect(
        routedThroughRouter: true,
        scheduledThroughScheduler: true,
        accessedGlobalState: false,
        usedSideChannel: false,
        hasTraceSpan: true,
        budgetApproved: true,
        requiredTrust: TrustLevel.system,
        actualTrust: TrustLevel.untrusted,
      );

      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'trust-escalation');
      expect(result.pattern!.critical, isTrue);
    });

    test('side channel type detection — socket', () {
      final result = detector.detectSideChannelType('socket');
      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'side-channel-socket');
    });

    test('side channel type detection — file', () {
      final result = detector.detectSideChannelType('file');
      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'side-channel-file');
    });

    test('side channel type detection — cache', () {
      final result = detector.detectSideChannelType('cache');
      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'side-channel-cache');
    });

    test('side channel type detection — singleton', () {
      final result = detector.detectSideChannelType('singleton');
      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'side-channel-singleton');
    });

    test('side channel type detection — static', () {
      final result = detector.detectSideChannelType('static');
      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'side-channel-static');
    });

    test('side channel type detection — rpc', () {
      final result = detector.detectSideChannelType('rpc');
      expect(result.bypassDetected, isTrue);
      expect(result.pattern!.patternId, 'side-channel-rpc');
    });

    test('unknown side channel type returns clean', () {
      final result = detector.detectSideChannelType('unknown');
      expect(result.bypassDetected, isFalse);
    });

    test('all 12 known bypass patterns are defined', () {
      expect(BypassDetector.knownPatterns.length, 12);
    });
  });

  group('ViolationEscalation', () {
    late ConstitutionalGuard guard;

    setUp(() {
      final clock = HybridLogicalClock(nodeId: 'escalation-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );
      guard = ConstitutionalGuard(
        enforcer: enforcer,
        escalationPolicy: const ViolationEscalationPolicy(
          warningThreshold: 3,
          restrictedThreshold: 7,
          terminationThreshold: 10,
        ),
      );
    });

    test('initial state is warning level with zero score', () {
      final state = guard.escalationFor('sb-1');
      expect(state.level, EscalationLevel.warning);
      expect(state.weightedScore, 0);
    });

    test('low-weight violations accumulate slowly', () {
      guard.updateEscalation('sb-1', SandboxViolationType.budgetExceeded);
      guard.updateEscalation('sb-1', SandboxViolationType.budgetExceeded);

      final state = guard.escalationFor('sb-1');
      expect(state.weightedScore, 2);
      expect(state.totalViolations, 2);
      expect(state.level, EscalationLevel.warning);
    });

    test('bypass attempt has weight 3 — escalates faster', () {
      guard.updateEscalation('sb-1', SandboxViolationType.bypassAttempt);

      final state = guard.escalationFor('sb-1');
      expect(state.weightedScore, 3);
      expect(state.totalViolations, 1);
    });

    test('escalation reaches restricted level', () {
      for (var i = 0; i < 7; i++) {
        guard.updateEscalation('sb-1', SandboxViolationType.budgetExceeded);
      }

      final state = guard.escalationFor('sb-1');
      expect(state.level, EscalationLevel.restricted);
      expect(guard.isRestricted('sb-1'), isTrue);
    });

    test('escalation reaches terminated level', () {
      for (var i = 0; i < 4; i++) {
        guard.updateEscalation('sb-1', SandboxViolationType.bypassAttempt);
      }

      final state = guard.escalationFor('sb-1');
      expect(state.weightedScore, 12);
      expect(state.level, EscalationLevel.terminated);
      expect(guard.shouldTerminate('sb-1'), isTrue);
    });

    test('critical violations escalate faster than regular ones', () {
      guard.updateEscalation('sb-regular', SandboxViolationType.budgetExceeded);
      guard.updateEscalation('sb-critical', SandboxViolationType.bypassAttempt);

      final regularState = guard.escalationFor('sb-regular');
      final criticalState = guard.escalationFor('sb-critical');

      expect(
        criticalState.weightedScore,
        greaterThan(regularState.weightedScore),
      );
    });

    test('escalation is tracked per sandbox independently', () {
      guard.updateEscalation('sb-1', SandboxViolationType.bypassAttempt);
      guard.updateEscalation('sb-2', SandboxViolationType.budgetExceeded);

      expect(guard.escalationFor('sb-1').weightedScore, 3);
      expect(guard.escalationFor('sb-2').weightedScore, 1);
    });

    test('reset escalation clears state', () {
      guard.updateEscalation('sb-1', SandboxViolationType.bypassAttempt);
      guard.updateEscalation('sb-1', SandboxViolationType.bypassAttempt);

      guard.resetEscalation('sb-1');

      final state = guard.escalationFor('sb-1');
      expect(state.weightedScore, 0);
      expect(state.level, EscalationLevel.warning);
    });
  });

  group('ConstitutionalGuard + SandboxIsolate Integration', () {
    late HybridLogicalClock clock;
    late SecurityManager securityManager;
    late PolicyEngine policyEngine;
    late ConstitutionalGuard guard;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'integration-test');
      securityManager = SecurityManager();
      policyEngine = PolicyEngine.defaultPolicy();
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );
      guard = ConstitutionalGuard(
        enforcer: enforcer,
        escalationPolicy: const ViolationEscalationPolicy(
          warningThreshold: 3,
          restrictedThreshold: 7,
          terminationThreshold: 10,
        ),
      );
    });

    SandboxIsolate createGuardedSandbox({
      String sandboxId = 'sb-guarded',
      TrustLevel trustLevel = TrustLevel.verified,
      Set<String> allowedCapabilities = const {'*'},
      Set<String> deniedCapabilities = const {},
    }) {
      return SandboxIsolate(
        identity: SandboxIdentity(
          sandboxId: sandboxId,
          type: SandboxType.agent,
          pluginId: 'plugin.guarded',
          trustLevel: trustLevel,
          createdBy: 'test',
          createdAt: clock.tick().physicalTime,
        ),
        resources: SandboxResources(
          budget: const ResourceBudget(
            maxTokens: 1000,
            maxStreams: 5,
            maxTasks: 10,
          ),
          usage: ResourceUsage(),
          allowedCapabilities: allowedCapabilities,
          deniedCapabilities: deniedCapabilities,
          trustBoundary: const TrustBoundary(boundaryId: 'guarded'),
        ),
        clock: HybridLogicalClock(nodeId: sandboxId),
        policyEngine: policyEngine,
        securityManager: securityManager,
        constitutionalGuard: guard,
      );
    }

    test('guarded sandbox — legitimate capability access works', () {
      final sandbox = createGuardedSandbox();
      sandbox.start();

      final result = sandbox.checkCapabilityAccess('storage.read');
      expect(result.allowed, isTrue);
    });

    test('guarded sandbox — bypassing CapabilityRouter is blocked', () {
      final sandbox = createGuardedSandbox();
      sandbox.start();

      final result = sandbox.checkCapabilityAccess(
        'storage.read',
        wasRoutedThroughRouter: false,
      );

      expect(result.allowed, isFalse);
      expect(
        sandbox.violations.any(
          (v) => v.type == SandboxViolationType.bypassAttempt,
        ),
        isTrue,
      );
    });

    test('guarded sandbox — untraced capability access is blocked', () {
      final sandbox = createGuardedSandbox();
      sandbox.start();

      final result = sandbox.checkCapabilityAccess(
        'storage.read',
        hasTraceSpan: false,
      );

      expect(result.allowed, isFalse);
    });

    test(
      'guarded sandbox — bypassing Scheduler for task creation is blocked',
      () {
        final sandbox = createGuardedSandbox();
        sandbox.start();

        final result = sandbox.tryAcquireTask(
          wasScheduledThroughScheduler: false,
        );
        expect(result, isFalse);
        expect(
          sandbox.violations.any(
            (v) => v.type == SandboxViolationType.bypassAttempt,
          ),
          isTrue,
        );
      },
    );

    test('guarded sandbox — repeated violations trigger escalation', () {
      final sandbox = createGuardedSandbox();
      sandbox.start();

      for (var i = 0; i < 4; i++) {
        sandbox.tryAcquireTask(wasScheduledThroughScheduler: false);
      }

      expect(guard.shouldTerminate(sandbox.identity.sandboxId), isTrue);
    });

    test('guarded sandbox — escalation terminates sandbox automatically', () {
      final sandbox = createGuardedSandbox();
      sandbox.start();

      for (var i = 0; i < 4; i++) {
        sandbox.tryAcquireTask(wasScheduledThroughScheduler: false);
      }

      final result = sandbox.checkCapabilityAccess('storage.read');
      expect(result.allowed, isFalse);
      expect(sandbox.isTerminated, isTrue);
    });

    test('unguarded sandbox still works without ConstitutionalGuard', () {
      final sandbox = SandboxIsolate(
        identity: SandboxIdentity(
          sandboxId: 'sb-unguarded',
          type: SandboxType.plugin,
          pluginId: 'plugin.unguarded',
          trustLevel: TrustLevel.verified,
          createdBy: 'test',
          createdAt: clock.tick().physicalTime,
        ),
        resources: SandboxResources(
          budget: const ResourceBudget(
            maxTokens: 1000,
            maxStreams: 5,
            maxTasks: 10,
          ),
          usage: ResourceUsage(),
          trustBoundary: const TrustBoundary(boundaryId: 'default'),
        ),
        clock: HybridLogicalClock(nodeId: 'sb-unguarded'),
        policyEngine: policyEngine,
        securityManager: securityManager,
      );

      sandbox.start();
      expect(sandbox.checkCapabilityAccess('storage.read').allowed, isTrue);
      expect(sandbox.tryAcquireTask(), isTrue);
      expect(sandbox.tryAcquireTokens(100), isTrue);
    });
  });

  group('ConstitutionalGuard — Guard Log', () {
    late ConstitutionalGuard guard;

    setUp(() {
      final clock = HybridLogicalClock(nodeId: 'log-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );
      guard = ConstitutionalGuard(enforcer: enforcer);
    });

    test('guard logs capability approvals', () {
      guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );

      expect(
        guard.guardLog.any((e) => e.action == 'capability.approved'),
        isTrue,
      );
    });

    test('guard logs capability blocks', () {
      guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: false,
        hasTraceSpan: true,
      );

      expect(
        guard.guardLog.any((e) => e.action == 'capability.blocked'),
        isTrue,
      );
    });

    test('guard logs escalation events', () {
      guard.updateEscalation('sb-1', SandboxViolationType.bypassAttempt);

      expect(
        guard.guardLog.any((e) => e.action.startsWith('escalation.')),
        isTrue,
      );
    });
  });

  group('ConstitutionalGuard — Constitution Cannot Be Bypassed', () {
    late ConstitutionalGuard guard;

    setUp(() {
      final clock = HybridLogicalClock(nodeId: 'bypass-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );
      guard = ConstitutionalGuard(enforcer: enforcer);
    });

    test('Law 1: cannot bypass CapabilityRouter — guard blocks it', () {
      final result = guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'any.cap',
        callerId: 'any.caller',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: false,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.noBypassCapabilityRouter);
    });

    test('Law 2: cannot bypass Scheduler — guard blocks it', () {
      final result = guard.checkTaskCreation(
        sandboxId: 'sb-1',
        wasScheduledThroughScheduler: false,
        budgetApproved: true,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.noBypassScheduler);
    });

    test('Law 3: cannot share global state — guard blocks it', () {
      final result = guard.checkStateAccess(
        sandboxId: 'sb-1',
        accessedGlobalState: true,
        usedSideChannel: false,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.noGlobalStateSharing);
    });

    test('Law 4: cannot use side channels — guard blocks it', () {
      final result = guard.checkStateAccess(
        sandboxId: 'sb-1',
        accessedGlobalState: false,
        usedSideChannel: true,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.noSideChannels);
    });

    test('Law 5+9: cannot skip tracing — guard blocks it', () {
      final capResult = guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'any.cap',
        callerId: 'any.caller',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: false,
      );
      expect(capResult.allowed, isFalse);
      expect(capResult.violatedLaw, RuntimeLawId.allOpsMustBeTraced);

      final taskResult = guard.checkTaskCreation(
        sandboxId: 'sb-1',
        wasScheduledThroughScheduler: true,
        budgetApproved: true,
        hasTraceSpan: false,
      );
      expect(taskResult.allowed, isFalse);
      expect(taskResult.violatedLaw, RuntimeLawId.allOpsMustBeTraced);
    });

    test('Law 6: cannot bypass budget — guard blocks it', () {
      final result = guard.checkTaskCreation(
        sandboxId: 'sb-1',
        wasScheduledThroughScheduler: true,
        budgetApproved: false,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.noBudgetBypass);
    });

    test('Law 10: trust level must be respected — guard blocks it', () {
      final result = guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'system.admin',
        callerId: 'untrusted.plugin',
        callerTrust: TrustLevel.untrusted,
        requiredTrust: TrustLevel.system,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );

      expect(result.allowed, isFalse);
      expect(result.violatedLaw, RuntimeLawId.trustLevelMustBeRespected);
    });

    test('all laws are structurally enforced — no opt-out', () {
      final violations = <RuntimeLawId>{};

      var result = guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'c',
        callerId: 'p',
        callerTrust: TrustLevel.untrusted,
        requiredTrust: TrustLevel.system,
        wasRoutedThroughRouter: false,
        hasTraceSpan: true,
      );
      if (!result.allowed && result.violatedLaw != null) {
        violations.add(result.violatedLaw!);
      }

      result = guard.checkCapabilityInvocation(
        sandboxId: 'sb-2',
        capabilityId: 'c',
        callerId: 'p',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: false,
      );
      if (!result.allowed && result.violatedLaw != null) {
        violations.add(result.violatedLaw!);
      }

      var taskResult = guard.checkTaskCreation(
        sandboxId: 'sb-3',
        wasScheduledThroughScheduler: false,
        budgetApproved: true,
        hasTraceSpan: true,
      );
      if (!taskResult.allowed && taskResult.violatedLaw != null) {
        violations.add(taskResult.violatedLaw!);
      }

      taskResult = guard.checkTaskCreation(
        sandboxId: 'sb-4',
        wasScheduledThroughScheduler: true,
        budgetApproved: false,
        hasTraceSpan: true,
      );
      if (!taskResult.allowed && taskResult.violatedLaw != null) {
        violations.add(taskResult.violatedLaw!);
      }

      var stateResult = guard.checkStateAccess(
        sandboxId: 'sb-5',
        accessedGlobalState: true,
        usedSideChannel: false,
        hasTraceSpan: true,
      );
      if (!stateResult.allowed && stateResult.violatedLaw != null) {
        violations.add(stateResult.violatedLaw!);
      }

      stateResult = guard.checkStateAccess(
        sandboxId: 'sb-6',
        accessedGlobalState: false,
        usedSideChannel: true,
        hasTraceSpan: true,
      );
      if (!stateResult.allowed && stateResult.violatedLaw != null) {
        violations.add(stateResult.violatedLaw!);
      }

      result = guard.checkCapabilityInvocation(
        sandboxId: 'sb-7',
        capabilityId: 'c',
        callerId: 'p',
        callerTrust: TrustLevel.untrusted,
        requiredTrust: TrustLevel.system,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );
      if (!result.allowed && result.violatedLaw != null) {
        violations.add(result.violatedLaw!);
      }

      expect(violations.length, 7);
      expect(
        violations.contains(RuntimeLawId.noBypassCapabilityRouter),
        isTrue,
      );
      expect(violations.contains(RuntimeLawId.allOpsMustBeTraced), isTrue);
      expect(violations.contains(RuntimeLawId.noBypassScheduler), isTrue);
      expect(violations.contains(RuntimeLawId.noBudgetBypass), isTrue);
      expect(violations.contains(RuntimeLawId.noGlobalStateSharing), isTrue);
      expect(violations.contains(RuntimeLawId.noSideChannels), isTrue);
      expect(
        violations.contains(RuntimeLawId.trustLevelMustBeRespected),
        isTrue,
      );
    });
  });
}
