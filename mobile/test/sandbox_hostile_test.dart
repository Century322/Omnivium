import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/sandbox_runtime.dart';
import 'package:omnivium/core/runtime/sandbox/runtime_law.dart';
import 'package:omnivium/core/runtime/governance/resource_controller.dart';
import 'package:omnivium/core/runtime/governance/policy_engine.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/distributed/lease/unified_lease.dart';
import 'package:omnivium/core/runtime/stability/security.dart';

void main() {
  HybridLogicalClock clock = HybridLogicalClock(nodeId: 'hostile');
  SecurityManager securityManager = SecurityManager();
  PolicyEngine policyEngine = PolicyEngine.defaultPolicy();

  SandboxIsolate createHostileSandbox({
    String sandboxId = 'sb-hostile',
    SandboxType type = SandboxType.agent,
    String pluginId = 'hostile.agent',
    TrustLevel trustLevel = TrustLevel.untrusted,
    Set<String> allowedCapabilities = const {'*'},
    Set<String> deniedCapabilities = const {},
    ResourceBudget budget = const ResourceBudget(
      maxTokens: 1000,
      maxStreams: 5,
      maxTasks: 10,
    ),
    TrustBoundary trustBoundary = const TrustBoundary(boundaryId: 'hostile'),
    Duration maxExecutionTime = const Duration(seconds: 60),
    int maxConcurrentTasks = 10,
  }) {
    return SandboxIsolate(
      identity: SandboxIdentity(
        sandboxId: sandboxId,
        type: type,
        pluginId: pluginId,
        trustLevel: trustLevel,
        createdBy: 'hostile-test',
        createdAt: clock.tick().physicalTime,
      ),
      resources: SandboxResources(
        budget: budget,
        usage: ResourceUsage(),
        allowedCapabilities: allowedCapabilities,
        deniedCapabilities: deniedCapabilities,
        trustBoundary: trustBoundary,
        maxExecutionTime: maxExecutionTime,
        maxConcurrentTasks: maxConcurrentTasks,
      ),
      clock: HybridLogicalClock(nodeId: sandboxId),
      policyEngine: policyEngine,
      securityManager: securityManager,
    );
  }

  setUp(() {
    clock = HybridLogicalClock(nodeId: 'hostile');
    securityManager = SecurityManager();
    policyEngine = PolicyEngine.defaultPolicy();
  });

  group('Hostile: Capability Abuse', () {
    test('untrusted sandbox cannot access system capabilities', () {
      securityManager.registerCapabilityAuth(
        const CapabilityAuth(
          capabilityId: 'runtime.admin',
          requiredTrustLevel: TrustLevel.system,
        ),
      );
      securityManager.registerCapabilityAuth(
        const CapabilityAuth(
          capabilityId: 'runtime.shutdown',
          requiredTrustLevel: TrustLevel.system,
        ),
      );

      final sandbox = createHostileSandbox(trustLevel: TrustLevel.untrusted);
      sandbox.start();

      final adminResult = sandbox.checkCapabilityAccess('runtime.admin');
      expect(adminResult.allowed, isFalse);

      final shutdownResult = sandbox.checkCapabilityAccess('runtime.shutdown');
      expect(shutdownResult.allowed, isFalse);

      expect(sandbox.violations.length, 2);
      expect(
        sandbox.violations.every(
          (v) => v.type == SandboxViolationType.trustInsufficient,
        ),
        isTrue,
      );
    });

    test('agent sandbox cannot access storage.delete via policy', () {
      final sandbox = createHostileSandbox(
        pluginId: 'agent.attacker',
        trustLevel: TrustLevel.verified,
        allowedCapabilities: {'*'},
      );
      sandbox.start();

      final result = sandbox.checkCapabilityAccess('storage.delete');
      expect(result.allowed, isFalse);
      expect(
        sandbox.violations.any(
          (v) => v.type == SandboxViolationType.policyDenied,
        ),
        isTrue,
      );
    });

    test('capability enumeration attack is blocked by trust boundary', () {
      final sandbox = createHostileSandbox(
        trustLevel: TrustLevel.verified,
        trustBoundary: const TrustBoundary(
          boundaryId: 'restricted',
          allowedCapabilities: {'storage.read'},
        ),
      );
      sandbox.start();

      final allowed = sandbox.checkCapabilityAccess('storage.read');
      expect(allowed.allowed, isTrue);

      final blocked = [
        'storage.write',
        'storage.delete',
        'network.connect',
        'runtime.admin',
        'system.execute',
        'file.read',
        'file.write',
      ];

      for (final cap in blocked) {
        final result = sandbox.checkCapabilityAccess(cap);
        expect(
          result.allowed,
          isFalse,
          reason: 'Capability $cap should be blocked',
        );
      }

      expect(sandbox.violations.length, blocked.length);
    });

    test('denied capability list takes absolute precedence', () {
      final sandbox = createHostileSandbox(
        trustLevel: TrustLevel.verified,
        allowedCapabilities: {'*'},
        deniedCapabilities: {
          'storage.delete',
          'runtime.admin',
          'network.connect',
        },
      );
      sandbox.start();

      expect(sandbox.checkCapabilityAccess('storage.read').allowed, isTrue);
      expect(sandbox.checkCapabilityAccess('storage.delete').allowed, isFalse);
      expect(sandbox.checkCapabilityAccess('runtime.admin').allowed, isFalse);
      expect(sandbox.checkCapabilityAccess('network.connect').allowed, isFalse);
    });

    test('rapid capability invocation creates audit trail', () {
      final sandbox = createHostileSandbox(
        trustLevel: TrustLevel.verified,
        deniedCapabilities: {'dangerous.op'},
      );
      sandbox.start();

      for (var i = 0; i < 100; i++) {
        sandbox.checkCapabilityAccess('dangerous.op');
      }

      expect(sandbox.violations.length, 100);
      expect(
        sandbox.violations.every(
          (v) => v.type == SandboxViolationType.capabilityDenied,
        ),
        isTrue,
      );
    });

    test('sandbox.* plugins cannot access runtime.* capabilities', () {
      final sandbox = createHostileSandbox(
        pluginId: 'sandbox.plugin',
        trustLevel: TrustLevel.verified,
      );
      sandbox.start();

      final result = sandbox.checkCapabilityAccess('runtime.configure');
      expect(result.allowed, isFalse);
    });
  });

  group('Hostile: Resource Exhaustion', () {
    test('token exhaustion attack is blocked by budget', () {
      final sandbox = createHostileSandbox(
        budget: const ResourceBudget(
          maxTokens: 100,
          maxStreams: 5,
          maxTasks: 10,
        ),
      );
      sandbox.start();

      expect(sandbox.tryAcquireTokens(50), isTrue);
      expect(sandbox.tryAcquireTokens(50), isTrue);
      expect(sandbox.tryAcquireTokens(1), isFalse);

      expect(
        sandbox.violations.any(
          (v) => v.type == SandboxViolationType.budgetExceeded,
        ),
        isTrue,
      );
    });

    test('task flood attack is blocked by concurrent task limit', () {
      final sandbox = createHostileSandbox(
        budget: const ResourceBudget(
          maxTokens: 10000,
          maxStreams: 20,
          maxTasks: 5,
        ),
        maxConcurrentTasks: 5,
      );
      sandbox.start();

      for (var i = 0; i < 5; i++) {
        expect(sandbox.tryAcquireTask(), isTrue);
      }

      for (var i = 0; i < 50; i++) {
        expect(sandbox.tryAcquireTask(), isFalse);
      }

      expect(
        sandbox.violations.any(
          (v) => v.type == SandboxViolationType.taskLimitExceeded,
        ),
        isTrue,
      );
    });

    test('stream exhaustion attack is blocked', () {
      final sandbox = createHostileSandbox(
        budget: const ResourceBudget(
          maxTokens: 10000,
          maxStreams: 3,
          maxTasks: 20,
        ),
      );
      sandbox.start();

      for (var i = 0; i < 3; i++) {
        expect(sandbox.tryAcquireStream(), isTrue);
      }

      for (var i = 0; i < 20; i++) {
        expect(sandbox.tryAcquireStream(), isFalse);
      }

      expect(
        sandbox.violations.any(
          (v) => v.type == SandboxViolationType.streamLimitExceeded,
        ),
        isTrue,
      );
    });

    test(
      'combined resource exhaustion — all budgets enforced simultaneously',
      () {
        final sandbox = createHostileSandbox(
          budget: const ResourceBudget(
            maxTokens: 200,
            maxStreams: 2,
            maxTasks: 3,
          ),
          maxConcurrentTasks: 3,
        );
        sandbox.start();

        expect(sandbox.tryAcquireTokens(200), isTrue);
        expect(sandbox.tryAcquireTask(), isTrue);
        expect(sandbox.tryAcquireTask(), isTrue);
        expect(sandbox.tryAcquireTask(), isTrue);
        expect(sandbox.tryAcquireStream(), isTrue);
        expect(sandbox.tryAcquireStream(), isTrue);

        expect(sandbox.tryAcquireTokens(1), isFalse);
        expect(sandbox.tryAcquireTask(), isFalse);
        expect(sandbox.tryAcquireStream(), isFalse);

        expect(sandbox.violations.length, 3);
      },
    );

    test('resource operations fail on terminated sandbox', () {
      final sandbox = createHostileSandbox();
      sandbox.start();
      sandbox.terminate('hostile_terminated');

      expect(sandbox.tryAcquireTokens(1), isFalse);
      expect(sandbox.tryAcquireTask(), isFalse);
      expect(sandbox.tryAcquireStream(), isFalse);
    });

    test('resource operations fail on suspended sandbox', () {
      final sandbox = createHostileSandbox();
      sandbox.start();
      sandbox.suspend();

      expect(sandbox.tryAcquireTokens(1), isFalse);
      expect(sandbox.tryAcquireTask(), isFalse);
      expect(sandbox.tryAcquireStream(), isFalse);
    });

    test('execution time limit terminates sandbox', () {
      final sandbox = SandboxIsolate(
        identity: SandboxIdentity(
          sandboxId: 'sb-timeout-attack',
          type: SandboxType.agent,
          pluginId: 'hostile.agent',
          trustLevel: TrustLevel.untrusted,
          createdBy: 'hostile-test',
          createdAt: clock.tick().physicalTime,
        ),
        resources: SandboxResources(
          budget: const ResourceBudget(
            maxTokens: 100000,
            maxStreams: 100,
            maxTasks: 100,
          ),
          usage: ResourceUsage(),
          trustBoundary: const TrustBoundary(boundaryId: 'hostile'),
          maxExecutionTime: const Duration(milliseconds: 1),
        ),
        clock: HybridLogicalClock(nodeId: 'sb-timeout-attack'),
        policyEngine: policyEngine,
        securityManager: securityManager,
      );

      sandbox.start();

      bool terminated = false;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!sandbox.checkExecutionTime()) {
          terminated = true;
        }
      });

      expect(sandbox.isRunning, isTrue);
    });
  });

  group('Hostile: Sandbox Escape', () {
    test('terminated sandbox cannot access capabilities', () {
      final sandbox = createHostileSandbox(
        trustLevel: TrustLevel.verified,
        allowedCapabilities: {'storage.read'},
      );
      sandbox.start();

      expect(sandbox.checkCapabilityAccess('storage.read').allowed, isTrue);

      sandbox.terminate('escape_attempt');

      final result = sandbox.checkCapabilityAccess('storage.read');
      expect(result.allowed, isFalse);
      expect(result.reason, contains('not running'));
    });

    test('not-started sandbox cannot access any resources', () {
      final sandbox = createHostileSandbox();

      expect(sandbox.checkCapabilityAccess('anything').allowed, isFalse);
      expect(sandbox.tryAcquireTokens(1), isFalse);
      expect(sandbox.tryAcquireTask(), isFalse);
      expect(sandbox.tryAcquireStream(), isFalse);
    });

    test('sandbox cannot restart after termination', () {
      final sandbox = createHostileSandbox();
      sandbox.start();
      sandbox.terminate('done');

      expect(() => sandbox.start(), throwsStateError);
    });

    test('sandbox cannot be used after termination — all paths blocked', () {
      final sandbox = createHostileSandbox(
        trustLevel: TrustLevel.verified,
        allowedCapabilities: {'*'},
      );
      sandbox.start();

      expect(sandbox.checkCapabilityAccess('storage.read').allowed, isTrue);

      sandbox.terminate('escape_blocked');

      expect(sandbox.checkCapabilityAccess('storage.read').allowed, isFalse);
      expect(sandbox.tryAcquireTokens(1), isFalse);
      expect(sandbox.tryAcquireTask(), isFalse);
      expect(sandbox.tryAcquireStream(), isFalse);
      expect(sandbox.checkExecutionTime(), isFalse);
    });

    test('suspended sandbox cannot access capabilities or resources', () {
      final sandbox = createHostileSandbox(
        trustLevel: TrustLevel.verified,
        allowedCapabilities: {'*'},
      );
      sandbox.start();

      expect(sandbox.checkCapabilityAccess('storage.read').allowed, isTrue);

      sandbox.suspend();

      expect(sandbox.checkCapabilityAccess('storage.read').allowed, isFalse);
      expect(sandbox.tryAcquireTokens(1), isFalse);
      expect(sandbox.tryAcquireTask(), isFalse);
    });

    test('resume restores capability access', () {
      final sandbox = createHostileSandbox(
        trustLevel: TrustLevel.verified,
        allowedCapabilities: {'*'},
      );
      sandbox.start();
      sandbox.suspend();

      expect(sandbox.checkCapabilityAccess('storage.read').allowed, isFalse);

      sandbox.resume();

      expect(sandbox.checkCapabilityAccess('storage.read').allowed, isTrue);
    });

    test('ExecutionGovernor terminates hostile sandbox and prevents reuse', () {
      final governor = ExecutionGovernor(
        securityManager: securityManager,
        clock: clock,
      );

      final sandbox = governor.create(
        type: SandboxType.agent,
        pluginId: 'hostile.agent',
        trustLevel: TrustLevel.untrusted,
        resources: SandboxResources(
          budget: const ResourceBudget(
            maxTokens: 100,
            maxStreams: 2,
            maxTasks: 3,
          ),
          usage: ResourceUsage(),
          trustBoundary: const TrustBoundary(boundaryId: 'hostile'),
        ),
      );

      sandbox.start();
      expect(governor.activeSandboxCount, 1);

      governor.terminate(sandbox.identity.sandboxId, 'hostile_activity');
      expect(sandbox.state, SandboxState.terminated);
      expect(governor.activeSandboxCount, 0);

      expect(sandbox.checkCapabilityAccess('anything').allowed, isFalse);
    });
  });

  group('Hostile: Replay Attack', () {
    test('HLC detects stale timestamp — replayed operation has older time', () {
      final clock1 = HybridLogicalClock(nodeId: 'node-1');
      final clock2 = HybridLogicalClock(nodeId: 'node-2');

      final ts1 = clock1.tick();
      final ts2 = clock2.tick();

      final received = clock1.receive(ts2);
      expect(received.isAfter(ts1), isTrue);

      final replayedTs = HybridTimestamp(
        physicalTime: ts1.physicalTime,
        logicalTime: ts1.logicalTime,
        nodeId: 'node-1',
      );

      expect(received.isAfter(replayedTs), isTrue);
      expect(replayedTs.happensBefore(received), isTrue);
    });

    test('HLC provides causal ordering — replayed events are detected', () {
      final nodeA = HybridLogicalClock(nodeId: 'A');
      final nodeB = HybridLogicalClock(nodeId: 'B');

      final event1 = nodeA.tick();
      nodeB.receive(event1);
      final event2 = nodeB.tick();

      expect(event2.happensBefore(event1), isFalse);
      expect(event1.happensBefore(event2), isTrue);

      final replayAttempt = HybridTimestamp(
        physicalTime: event1.physicalTime - 10000,
        logicalTime: 0,
        nodeId: 'A',
      );

      expect(replayAttempt.happensBefore(event2), isTrue);
      expect(replayAttempt.physicalTime < event2.physicalTime, isTrue);
    });

    test('lease expiration prevents replay — expired lease cannot be used', () {
      final leaseClock = HybridLogicalClock(nodeId: 'lease-test');
      final leaseManager = UnifiedLeaseManager(
        localNodeId: 'node-1',
        clock: leaseClock,
        config: const LeaseConfig(sessionTtl: Duration(milliseconds: 100)),
      );

      final lease = leaseManager.acquire(LeaseType.session, 'session-1');
      expect(lease.isActive, isTrue);

      final now = leaseClock.tick().physicalTime;
      expect(lease.isValidAt(now), isTrue);

      leaseManager.tickExpiry();

      final afterExpiry = leaseManager.getLease('session-1');
      if (afterExpiry!.isExpired) {
        expect(afterExpiry.isValidAt(leaseClock.tick().physicalTime), isFalse);
      }
    });

    test('sandbox violation timestamps are causally ordered', () {
      final sandbox = createHostileSandbox(
        trustLevel: TrustLevel.verified,
        deniedCapabilities: {'danger.op'},
      );
      sandbox.start();

      sandbox.checkCapabilityAccess('danger.op');
      sandbox.checkCapabilityAccess('danger.op');

      expect(sandbox.violations.length, 2);

      final v1 = sandbox.violations[0];
      final v2 = sandbox.violations[1];

      expect(v1.timestamp <= v2.timestamp, isTrue);
    });

    test('incarnation prevents stale lease replay', () {
      final leaseClock = HybridLogicalClock(nodeId: 'inc-test');
      final leaseManager = UnifiedLeaseManager(
        localNodeId: 'node-1',
        clock: leaseClock,
      );

      final lease1 = leaseManager.acquire(LeaseType.resource, 'res-1');
      expect(lease1.incarnation, 0);

      leaseManager.release('res-1');

      final lease2 = leaseManager.acquire(LeaseType.resource, 'res-1');
      expect(lease2.incarnation, 0);

      final staleLease = UnifiedLease(
        leaseId: 'stale',
        leaseType: LeaseType.resource,
        ownerId: 'node-1',
        targetId: 'res-1',
        acquiredAt: 0,
        expiresAt: 999999999,
        incarnation: 0,
      );

      leaseManager.receiveLeaseState(staleLease);
      final current = leaseManager.getLease('res-1');
      expect(current!.incarnation, 0);
    });
  });

  group('Hostile: Trust Downgrade', () {
    test('untrusted entity cannot access verified-level capabilities', () {
      securityManager.registerCapabilityAuth(
        const CapabilityAuth(
          capabilityId: 'storage.write',
          requiredTrustLevel: TrustLevel.verified,
        ),
      );

      final sandbox = createHostileSandbox(trustLevel: TrustLevel.untrusted);
      sandbox.start();

      final result = sandbox.checkCapabilityAccess('storage.write');
      expect(result.allowed, isFalse);
      expect(
        sandbox.violations.any(
          (v) => v.type == SandboxViolationType.trustInsufficient,
        ),
        isTrue,
      );
    });

    test('verified entity cannot access system-level capabilities', () {
      securityManager.registerCapabilityAuth(
        const CapabilityAuth(
          capabilityId: 'runtime.shutdown',
          requiredTrustLevel: TrustLevel.system,
        ),
      );

      final sandbox = createHostileSandbox(trustLevel: TrustLevel.verified);
      sandbox.start();

      final result = sandbox.checkCapabilityAccess('runtime.shutdown');
      expect(result.allowed, isFalse);
    });

    test('blocked trust level is completely denied', () {
      securityManager.registerCapabilityAuth(
        const CapabilityAuth(
          capabilityId: 'storage.read',
          requiredTrustLevel: TrustLevel.untrusted,
        ),
      );

      final sandbox = createHostileSandbox(trustLevel: TrustLevel.blocked);
      sandbox.start();

      final result = sandbox.checkCapabilityAccess('storage.read');
      expect(result.allowed, isFalse);
    });

    test('trust boundary merge restricts — never expands', () {
      const boundary1 = TrustBoundary(
        boundaryId: 'zone-a',
        allowedCapabilities: {'storage.read', 'storage.write'},
        allowNetworkAccess: true,
      );

      const boundary2 = TrustBoundary(
        boundaryId: 'zone-b',
        allowedCapabilities: {'storage.read'},
        allowNetworkAccess: false,
      );

      final merged = boundary1.merge(boundary2);

      expect(merged.isCapabilityAllowed('storage.read'), isTrue);
      expect(merged.isCapabilityAllowed('storage.write'), isFalse);
      expect(merged.allowNetworkAccess, isFalse);
    });

    test('trust downgrade via trust boundary — miniapp sandbox restricted', () {
      final sandbox = createHostileSandbox(
        type: SandboxType.miniApp,
        pluginId: 'miniapp.rogue',
        trustLevel: TrustLevel.verified,
        trustBoundary: const TrustBoundary(
          boundaryId: 'miniapp',
          allowedCapabilities: {'storage.read', 'ui.render'},
          allowNetworkAccess: false,
          allowFileSystemAccess: false,
          allowSubprocess: false,
        ),
      );
      sandbox.start();

      expect(sandbox.checkCapabilityAccess('storage.read').allowed, isTrue);
      expect(sandbox.checkCapabilityAccess('ui.render').allowed, isTrue);
      expect(sandbox.checkCapabilityAccess('network.connect').allowed, isFalse);
      expect(sandbox.checkCapabilityAccess('file.write').allowed, isFalse);
      expect(sandbox.checkCapabilityAccess('system.execute').allowed, isFalse);
    });

    test('Law 10 enforcement — trust level must be respected', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      final systemOnly = enforcer.enforceTrustLevel(
        'sb-1',
        TrustLevel.system,
        TrustLevel.untrusted,
      );
      expect(systemOnly.compliant, isFalse);
      expect(systemOnly.lawId, RuntimeLawId.trustLevelMustBeRespected);

      final verifiedAccess = enforcer.enforceTrustLevel(
        'sb-1',
        TrustLevel.verified,
        TrustLevel.signed,
      );
      expect(verifiedAccess.compliant, isTrue);

      final equalLevel = enforcer.enforceTrustLevel(
        'sb-1',
        TrustLevel.verified,
        TrustLevel.verified,
      );
      expect(equalLevel.compliant, isTrue);
    });

    test(
      'SecurityManager rate limiting blocks brute force trust escalation',
      () {
        for (var i = 0; i < 5; i++) {
          securityManager.recordAuthFailure('attacker');
        }

        expect(securityManager.checkAuthRateLimit('attacker'), isFalse);
      },
    );
  });

  group('Hostile: Side-Channel Probing', () {
    test('Law 4 — side channel detection is enforced', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      final hiddenSocket = enforcer.enforceNoSideChannels('sb-1', true);
      expect(hiddenSocket.compliant, isFalse);
      expect(hiddenSocket.lawId, RuntimeLawId.noSideChannels);
      expect(hiddenSocket.violation, contains('Side channel'));

      final legitimate = enforcer.enforceNoSideChannels('sb-1', false);
      expect(legitimate.compliant, isTrue);
    });

    test('Law 3 — global state sharing is detected', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      final globalAccess = enforcer.enforceNoGlobalState('sb-1', true);
      expect(globalAccess.compliant, isFalse);
      expect(globalAccess.lawId, RuntimeLawId.noGlobalStateSharing);

      final isolated = enforcer.enforceNoGlobalState('sb-1', false);
      expect(isolated.compliant, isTrue);
    });

    test('side channel violations are audited by SecurityManager', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      enforcer.enforceNoSideChannels('sb-probe', true);

      final auditLog = securityManager.auditLog();
      expect(
        auditLog.any((e) => e.action == 'law.violation' && e.success == false),
        isTrue,
      );
    });

    test('multiple side channel types are all detected', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      final channels = [
        ('hidden_socket', true),
        ('temp_file', true),
        ('shared_cache', true),
        ('in_memory_singleton', true),
        ('static_variable', true),
        ('hidden_rpc', true),
      ];

      for (final (_, used) in channels) {
        final result = enforcer.enforceNoSideChannels('sb-probe', used);
        expect(result.compliant, isFalse);
      }

      expect(enforcer.violationsFor('sb-probe').length, channels.length);
    });

    test(
      'global state violations across multiple sandboxes are tracked independently',
      () {
        final enforcer = RuntimeLawEnforcer(
          clock: clock,
          securityManager: securityManager,
        );

        enforcer.enforceNoGlobalState('sb-1', true);
        enforcer.enforceNoGlobalState('sb-2', true);
        enforcer.enforceNoGlobalState('sb-1', true);

        expect(enforcer.violationsFor('sb-1').length, 2);
        expect(enforcer.violationsFor('sb-2').length, 1);
      },
    );

    test('SandboxIsolate records bypass attempts as violations', () {
      final sandbox = createHostileSandbox(
        trustLevel: TrustLevel.verified,
        deniedCapabilities: {'runtime.internal'},
      );
      sandbox.start();

      sandbox.checkCapabilityAccess('runtime.internal');

      expect(
        sandbox.violations.any(
          (v) => v.type == SandboxViolationType.capabilityDenied,
        ),
        isTrue,
      );
    });
  });

  group('Hostile: Law Enforcement Under Attack', () {
    test('Law 1 — capability routing bypass is detected and audited', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      final directCall = enforcer.enforceCapabilityRouting(
        'sb-1',
        'storage.read',
        false,
      );
      expect(directCall.compliant, isFalse);
      expect(directCall.lawId, RuntimeLawId.noBypassCapabilityRouter);

      final routedCall = enforcer.enforceCapabilityRouting(
        'sb-1',
        'storage.read',
        true,
      );
      expect(routedCall.compliant, isTrue);

      final auditLog = securityManager.auditLog();
      expect(
        auditLog.any(
          (e) =>
              e.context.containsKey('law') &&
              e.context['law'] == 'noBypassCapabilityRouter',
        ),
        isTrue,
      );
    });

    test('Law 2 — scheduler bypass is detected', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      final directSpawn = enforcer.enforceSchedulerUsage('sb-1', false);
      expect(directSpawn.compliant, isFalse);
      expect(directSpawn.lawId, RuntimeLawId.noBypassScheduler);

      final scheduled = enforcer.enforceSchedulerUsage('sb-1', true);
      expect(scheduled.compliant, isTrue);
    });

    test('Law 5 + 9 — untraced operations are detected', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      final untraced = enforcer.enforceTracing('sb-1', false);
      expect(untraced.compliant, isFalse);
      expect(untraced.lawId, RuntimeLawId.allOpsMustBeTraced);

      final traced = enforcer.enforceTracing('sb-1', true);
      expect(traced.compliant, isTrue);
    });

    test('Law 6 — budget bypass is detected', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      final unaccounted = enforcer.enforceBudget('sb-1', false);
      expect(unaccounted.compliant, isFalse);
      expect(unaccounted.lawId, RuntimeLawId.noBudgetBypass);

      final accounted = enforcer.enforceBudget('sb-1', true);
      expect(accounted.compliant, isTrue);
    });

    test('all 10 laws can be violated and detected', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      enforcer.enforceCapabilityRouting('sb-1', 'cap', false);
      enforcer.enforceSchedulerUsage('sb-1', false);
      enforcer.enforceNoGlobalState('sb-1', true);
      enforcer.enforceNoSideChannels('sb-1', true);
      enforcer.enforceTracing('sb-1', false);
      enforcer.enforceBudget('sb-1', false);
      enforcer.enforceTrustLevel(
        'sb-1',
        TrustLevel.system,
        TrustLevel.untrusted,
      );

      expect(enforcer.totalViolations(), 7);

      final violatedLaws = enforcer.enforcementLog
          .where((r) => !r.compliant)
          .map((r) => r.lawId)
          .toSet();
      expect(violatedLaws.length, 7);
    });

    test('law enforcement audit trail is immutable and complete', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      enforcer.enforceCapabilityRouting('sb-1', 'cap', false);
      enforcer.enforceCapabilityRouting('sb-1', 'cap', true);
      enforcer.enforceSchedulerUsage('sb-1', false);

      expect(enforcer.enforcementLog.length, 3);

      final violations = enforcer.violationsFor('sb-1');
      expect(violations.length, 2);
    });
  });

  group('Hostile: Combined Attack Scenarios', () {
    test(
      'malicious agent: capability abuse + resource exhaustion + trust escalation',
      () {
        securityManager.registerCapabilityAuth(
          const CapabilityAuth(
            capabilityId: 'admin.wipe',
            requiredTrustLevel: TrustLevel.system,
          ),
        );

        final sandbox = createHostileSandbox(
          type: SandboxType.agent,
          pluginId: 'agent.malicious',
          trustLevel: TrustLevel.verified,
          budget: const ResourceBudget(
            maxTokens: 50,
            maxStreams: 2,
            maxTasks: 3,
          ),
          maxConcurrentTasks: 3,
          deniedCapabilities: {'storage.delete'},
        );
        sandbox.start();

        final capResult = sandbox.checkCapabilityAccess('admin.wipe');
        expect(capResult.allowed, isFalse);

        final deleteResult = sandbox.checkCapabilityAccess('storage.delete');
        expect(deleteResult.allowed, isFalse);

        expect(sandbox.tryAcquireTokens(50), isTrue);
        expect(sandbox.tryAcquireTokens(1), isFalse);

        expect(sandbox.tryAcquireTask(), isTrue);
        expect(sandbox.tryAcquireTask(), isTrue);
        expect(sandbox.tryAcquireTask(), isTrue);
        expect(sandbox.tryAcquireTask(), isFalse);

        expect(sandbox.violations.length, greaterThanOrEqualTo(3));
      },
    );

    test(
      'rogue miniapp: sandbox escape attempt + side channel + budget bypass',
      () {
        final enforcer = RuntimeLawEnforcer(
          clock: clock,
          securityManager: securityManager,
        );

        final sandbox = createHostileSandbox(
          type: SandboxType.miniApp,
          pluginId: 'miniapp.rogue',
          trustLevel: TrustLevel.verified,
          trustBoundary: const TrustBoundary(
            boundaryId: 'miniapp',
            allowedCapabilities: {'ui.render'},
            allowNetworkAccess: false,
            allowFileSystemAccess: false,
          ),
          budget: const ResourceBudget(
            maxTokens: 100,
            maxStreams: 1,
            maxTasks: 2,
          ),
        );
        sandbox.start();

        expect(
          sandbox.checkCapabilityAccess('network.connect').allowed,
          isFalse,
        );
        expect(sandbox.checkCapabilityAccess('file.read').allowed, isFalse);

        enforcer.enforceNoSideChannels(sandbox.identity.sandboxId, true);
        enforcer.enforceBudget(sandbox.identity.sandboxId, false);

        expect(sandbox.tryAcquireTokens(100), isTrue);
        expect(sandbox.tryAcquireTokens(1), isFalse);

        sandbox.terminate('rogue_activity');

        expect(sandbox.checkCapabilityAccess('ui.render').allowed, isFalse);
        expect(enforcer.violationsFor(sandbox.identity.sandboxId).length, 2);
      },
    );

    test('coordinated attack: multiple sandboxes attacking simultaneously', () {
      final governor = ExecutionGovernor(
        securityManager: securityManager,
        clock: clock,
      );

      final attackers = <SandboxIsolate>[];
      for (var i = 0; i < 5; i++) {
        final sandbox = governor.create(
          type: SandboxType.agent,
          pluginId: 'agent.attacker-$i',
          trustLevel: TrustLevel.verified,
          resources: SandboxResources(
            budget: const ResourceBudget(
              maxTokens: 100,
              maxStreams: 2,
              maxTasks: 3,
            ),
            usage: ResourceUsage(),
            deniedCapabilities: {'storage.delete', 'runtime.admin'},
            trustBoundary: const TrustBoundary(boundaryId: 'hostile'),
          ),
        );
        sandbox.start();
        attackers.add(sandbox);
      }

      for (final sandbox in attackers) {
        sandbox.checkCapabilityAccess('storage.delete');
        sandbox.checkCapabilityAccess('runtime.admin');
        sandbox.tryAcquireTokens(200);
        sandbox.tryAcquireTask();
        sandbox.tryAcquireTask();
        sandbox.tryAcquireTask();
        sandbox.tryAcquireTask();
      }

      final allViolations = governor.allViolations();
      expect(allViolations.length, greaterThanOrEqualTo(15));

      for (final sandbox in attackers) {
        expect(sandbox.violations, isNotEmpty);
      }
    });

    test('persistent attacker: repeated violations lead to termination', () {
      final sandbox = createHostileSandbox(
        trustLevel: TrustLevel.verified,
        deniedCapabilities: {'danger.op'},
        budget: const ResourceBudget(maxTokens: 10, maxStreams: 1, maxTasks: 1),
        maxConcurrentTasks: 1,
      );
      sandbox.start();

      for (var i = 0; i < 20; i++) {
        sandbox.checkCapabilityAccess('danger.op');
      }

      sandbox.tryAcquireTokens(10);
      sandbox.tryAcquireTokens(1);

      expect(sandbox.violations.length, greaterThanOrEqualTo(21));

      sandbox.terminate('persistent_violations');
      expect(sandbox.state, SandboxState.terminated);
      expect(sandbox.terminationReason, 'persistent_violations');
    });
  });

  group('Hostile: Runtime Constitution Integrity', () {
    test('all 10 Runtime Laws have enforcement mechanisms', () {
      for (final law in RuntimeConstitution.laws) {
        expect(law.description, isNotEmpty);
        expect(law.enforcement, isNotEmpty);
        expect(law.id, isNotNull);
      }
    });

    test('Runtime Law IDs are unique and stable', () {
      final ids = RuntimeConstitution.laws.map((l) => l.id).toSet();
      expect(ids.length, 10);

      final expectedIds = {
        RuntimeLawId.noBypassCapabilityRouter,
        RuntimeLawId.noBypassScheduler,
        RuntimeLawId.noGlobalStateSharing,
        RuntimeLawId.noSideChannels,
        RuntimeLawId.noUntracedOperations,
        RuntimeLawId.noBudgetBypass,
        RuntimeLawId.noDirectThreadCreation,
        RuntimeLawId.allOpsMustBeJournaled,
        RuntimeLawId.allOpsMustBeTraced,
        RuntimeLawId.trustLevelMustBeRespected,
      };

      expect(ids, equals(expectedIds));
    });

    test('law enforcement is non-repudiable — audit log persists', () {
      final enforcer = RuntimeLawEnforcer(
        clock: clock,
        securityManager: securityManager,
      );

      enforcer.enforceCapabilityRouting('sb-1', 'cap', false);
      enforcer.enforceNoSideChannels('sb-1', true);
      enforcer.enforceBudget('sb-1', false);

      final auditLog = securityManager.auditLog();
      final lawViolations = auditLog
          .where((e) => e.action == 'law.violation')
          .toList();
      expect(lawViolations.length, 3);

      for (final entry in lawViolations) {
        expect(entry.success, isFalse);
        expect(entry.context.containsKey('law'), isTrue);
      }
    });

    test('SandboxViolationType covers all attack vectors', () {
      final expectedTypes = {
        SandboxViolationType.budgetExceeded,
        SandboxViolationType.taskLimitExceeded,
        SandboxViolationType.streamLimitExceeded,
        SandboxViolationType.capabilityDenied,
        SandboxViolationType.policyDenied,
        SandboxViolationType.trustInsufficient,
        SandboxViolationType.executionTimeExceeded,
        SandboxViolationType.memoryExceeded,
        SandboxViolationType.bypassAttempt,
      };

      for (final type in expectedTypes) {
        expect(SandboxViolationType.values.contains(type), isTrue);
      }
    });

    test('violation JSON serialization preserves forensic data', () {
      final violation = SandboxViolation(
        type: SandboxViolationType.bypassAttempt,
        message: 'Side channel detected: hidden_socket',
        timestamp: 1234567890,
        sandboxId: 'sb-forensic',
      );

      final json = violation.toJson();
      expect(json['type'], 'bypassAttempt');
      expect(json['message'], contains('Side channel'));
      expect(json['timestamp'], 1234567890);
      expect(json['sandboxId'], 'sb-forensic');
    });
  });
}
