import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/sandbox_runtime.dart';
import 'package:omnivium/core/runtime/sandbox/runtime_law.dart';
import 'package:omnivium/core/runtime/governance/resource_controller.dart';
import 'package:omnivium/core/runtime/governance/policy_engine.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/stability/security.dart';
import 'package:omnivium/core/runtime/stability/runtime_spec.dart';

void main() {
  group('Sandbox Isolate', () {
    late HybridLogicalClock clock;
    late PolicyEngine policyEngine;
    late SecurityManager securityManager;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'test');
      policyEngine = PolicyEngine.defaultPolicy();
      securityManager = SecurityManager();
    });

    SandboxIsolate createSandbox({
      TrustLevel trustLevel = TrustLevel.verified,
      Set<String> allowedCapabilities = const {},
      Set<String> deniedCapabilities = const {},
    }) {
      return SandboxIsolate(
        identity: SandboxIdentity(
          sandboxId: 'sb-test',
          type: SandboxType.plugin,
          pluginId: 'test-plugin',
          trustLevel: trustLevel,
          createdBy: 'test',
          createdAt: clock.tick().physicalTime,
        ),
        resources: SandboxResources(
          budget: const ResourceBudget(maxTokens: 1000, maxStreams: 5, maxTasks: 10),
          usage: ResourceUsage(),
          allowedCapabilities: allowedCapabilities,
          deniedCapabilities: deniedCapabilities,
          trustBoundary: const TrustBoundary(boundaryId: 'test'),
          maxExecutionTime: const Duration(seconds: 60),
        ),
        clock: HybridLogicalClock(nodeId: 'sb-test'),
        policyEngine: policyEngine,
        securityManager: securityManager,
      );
    }

    test('lifecycle: created → running → suspended → terminated', () {
      final sandbox = createSandbox();

      expect(sandbox.state, SandboxState.created);

      sandbox.start();
      expect(sandbox.state, SandboxState.running);

      sandbox.suspend();
      expect(sandbox.state, SandboxState.suspended);

      sandbox.resume();
      expect(sandbox.state, SandboxState.running);

      sandbox.terminate('test_done');
      expect(sandbox.state, SandboxState.terminated);
      expect(sandbox.terminationReason, 'test_done');
    });

    test('cannot start from running state', () {
      final sandbox = createSandbox();
      sandbox.start();

      expect(() => sandbox.start(), throwsStateError);
    });

    test('capability access check with allowed capabilities', () {
      final sandbox = createSandbox(
        trustLevel: TrustLevel.verified,
        allowedCapabilities: {'storage.read', 'storage.write'},
      );
      sandbox.start();

      final result = sandbox.checkCapabilityAccess('storage.read');
      expect(result.allowed, isTrue);
    });

    test('capability access denied for denied capabilities', () {
      final sandbox = createSandbox(
        deniedCapabilities: {'storage.delete'},
      );
      sandbox.start();

      final result = sandbox.checkCapabilityAccess('storage.delete');
      expect(result.allowed, isFalse);
    });

    test('capability access denied when sandbox not running', () {
      final sandbox = createSandbox();

      final result = sandbox.checkCapabilityAccess('storage.read');
      expect(result.allowed, isFalse);
    });

    test('policy engine denies agent.* from storage.delete', () {
      final agentPolicy = PolicyEngine.defaultPolicy();
      final identity = SandboxIdentity(
        sandboxId: 'sb-agent',
        type: SandboxType.agent,
        pluginId: 'agent.main',
        trustLevel: TrustLevel.verified,
        createdBy: 'test',
        createdAt: clock.tick().physicalTime,
      );

      final agentSandbox = SandboxIsolate(
        identity: identity,
        resources: SandboxResources(
          budget: const ResourceBudget(maxTokens: 1000, maxStreams: 5, maxTasks: 10),
          usage: ResourceUsage(),
          allowedCapabilities: {'*'},
          trustBoundary: const TrustBoundary(boundaryId: 'agent'),
        ),
        clock: HybridLogicalClock(nodeId: 'sb-agent'),
        policyEngine: agentPolicy,
        securityManager: securityManager,
      );
      agentSandbox.start();

      final result = agentSandbox.checkCapabilityAccess('storage.delete');
      expect(result.allowed, isFalse);
    });

    test('trust level insufficient blocks capability', () {
      securityManager.registerCapabilityAuth(const CapabilityAuth(
        capabilityId: 'admin.wipe',
        requiredTrustLevel: TrustLevel.system,
      ));

      final sandbox = createSandbox(trustLevel: TrustLevel.untrusted);
      sandbox.start();

      final result = sandbox.checkCapabilityAccess('admin.wipe');
      expect(result.allowed, isFalse);
    });

    test('violations are recorded', () {
      final sandbox = createSandbox(deniedCapabilities: {'storage.delete'});
      sandbox.start();

      sandbox.checkCapabilityAccess('storage.delete');

      expect(sandbox.violations.length, 1);
      expect(sandbox.violations.first.type, SandboxViolationType.capabilityDenied);
    });

    test('token budget check', () {
      final sandbox = createSandbox();
      sandbox.start();

      expect(sandbox.tryAcquireTokens(500), isTrue);
      expect(sandbox.tryAcquireTokens(500), isTrue);
      expect(sandbox.tryAcquireTokens(1), isFalse);
    });

    test('task limit check', () {
      final sandbox = createSandbox();
      sandbox.start();

      for (var i = 0; i < 10; i++) {
        expect(sandbox.tryAcquireTask(), isTrue);
      }
      expect(sandbox.tryAcquireTask(), isFalse);
    });

    test('stream limit check', () {
      final sandbox = createSandbox();
      sandbox.start();

      for (var i = 0; i < 5; i++) {
        expect(sandbox.tryAcquireStream(), isTrue);
      }
      expect(sandbox.tryAcquireStream(), isFalse);
    });

    test('resource operations fail when not running', () {
      final sandbox = createSandbox();

      expect(sandbox.tryAcquireTokens(1), isFalse);
      expect(sandbox.tryAcquireTask(), isFalse);
      expect(sandbox.tryAcquireStream(), isFalse);
    });

    test('execution time check', () {
      final sandbox = SandboxIsolate(
        identity: SandboxIdentity(
          sandboxId: 'sb-timeout',
          type: SandboxType.plugin,
          pluginId: 'test-plugin',
          trustLevel: TrustLevel.verified,
          createdBy: 'test',
          createdAt: clock.tick().physicalTime,
        ),
        resources: SandboxResources(
          budget: const ResourceBudget(maxTokens: 1000, maxStreams: 5, maxTasks: 10),
          usage: ResourceUsage(),
          trustBoundary: const TrustBoundary(boundaryId: 'test'),
          maxExecutionTime: const Duration(milliseconds: 50),
        ),
        clock: HybridLogicalClock(nodeId: 'sb-timeout'),
        policyEngine: policyEngine,
        securityManager: securityManager,
      );

      sandbox.start();
      expect(sandbox.checkExecutionTime(), isTrue);

      Future.delayed(const Duration(milliseconds: 100), () {
        expect(sandbox.checkExecutionTime(), isFalse);
        expect(sandbox.state, SandboxState.terminated);
      });
    });
  });

  group('Execution Governor', () {
    test('create and manage sandboxes', () {
      final clock = HybridLogicalClock(nodeId: 'gov');
      final securityManager = SecurityManager();
      final governor = ExecutionGovernor(securityManager: securityManager, clock: clock);

      final sandbox = governor.create(
        type: SandboxType.plugin,
        pluginId: 'test-plugin',
        trustLevel: TrustLevel.verified,
        resources: SandboxResources(
          budget: const ResourceBudget(maxTokens: 1000, maxStreams: 5, maxTasks: 10),
          usage: ResourceUsage(),
          trustBoundary: const TrustBoundary(boundaryId: 'default'),
        ),
      );

      expect(governor.totalSandboxCount, 1);
      expect(governor.activeSandboxCount, 0);

      sandbox.start();
      expect(governor.activeSandboxCount, 1);
    });

    test('terminate sandbox', () {
      final clock = HybridLogicalClock(nodeId: 'gov');
      final securityManager = SecurityManager();
      final governor = ExecutionGovernor(securityManager: securityManager, clock: clock);

      final sandbox = governor.create(
        type: SandboxType.plugin,
        pluginId: 'test-plugin',
        trustLevel: TrustLevel.verified,
        resources: SandboxResources(
          budget: const ResourceBudget(maxTokens: 1000, maxStreams: 5, maxTasks: 10),
          usage: ResourceUsage(),
          trustBoundary: const TrustBoundary(boundaryId: 'default'),
        ),
      );

      sandbox.start();
      governor.terminate(sandbox.identity.sandboxId, 'test_done');

      expect(sandbox.state, SandboxState.terminated);
    });

    test('cleanup terminated sandboxes', () {
      final clock = HybridLogicalClock(nodeId: 'gov');
      final securityManager = SecurityManager();
      final governor = ExecutionGovernor(securityManager: securityManager, clock: clock);

      final sandbox = governor.create(
        type: SandboxType.plugin,
        pluginId: 'test-plugin',
        trustLevel: TrustLevel.verified,
        resources: SandboxResources(
          budget: const ResourceBudget(maxTokens: 1000, maxStreams: 5, maxTasks: 10),
          usage: ResourceUsage(),
          trustBoundary: const TrustBoundary(boundaryId: 'default'),
        ),
      );

      sandbox.start();
      governor.terminate(sandbox.identity.sandboxId, 'done');

      governor.cleanupTerminated();
      expect(governor.totalSandboxCount, 0);
    });

    test('collect violations from all sandboxes', () {
      final clock = HybridLogicalClock(nodeId: 'gov');
      final securityManager = SecurityManager();
      final governor = ExecutionGovernor(securityManager: securityManager, clock: clock);

      final sandbox = governor.create(
        type: SandboxType.plugin,
        pluginId: 'test-plugin',
        trustLevel: TrustLevel.verified,
        resources: SandboxResources(
          budget: const ResourceBudget(maxTokens: 1000, maxStreams: 5, maxTasks: 10),
          usage: ResourceUsage(),
          deniedCapabilities: {'storage.delete'},
          trustBoundary: const TrustBoundary(boundaryId: 'default'),
        ),
      );

      sandbox.start();
      sandbox.checkCapabilityAccess('storage.delete');

      final violations = governor.allViolations();
      expect(violations, isNotEmpty);
    });

    test('different sandbox types', () {
      final clock = HybridLogicalClock(nodeId: 'gov');
      final securityManager = SecurityManager();
      final governor = ExecutionGovernor(securityManager: securityManager, clock: clock);

      governor.create(
        type: SandboxType.plugin,
        pluginId: 'p1',
        trustLevel: TrustLevel.verified,
        resources: SandboxResources(
          budget: const ResourceBudget(maxTokens: 1000, maxStreams: 5, maxTasks: 10),
          usage: ResourceUsage(),
          trustBoundary: const TrustBoundary(boundaryId: 'default'),
        ),
      );

      governor.create(
        type: SandboxType.agent,
        pluginId: 'a1',
        trustLevel: TrustLevel.signed,
        resources: SandboxResources(
          budget: const ResourceBudget(maxTokens: 5000, maxStreams: 10, maxTasks: 20),
          usage: ResourceUsage(),
          trustBoundary: const TrustBoundary(boundaryId: 'agent'),
        ),
      );

      governor.create(
        type: SandboxType.miniApp,
        pluginId: 'm1',
        trustLevel: TrustLevel.untrusted,
        resources: SandboxResources(
          budget: const ResourceBudget(maxTokens: 500, maxStreams: 2, maxTasks: 5),
          usage: ResourceUsage(),
          trustBoundary: const TrustBoundary(
            boundaryId: 'miniapp',
            allowedCapabilities: {'storage.read', 'ui.render'},
            allowNetworkAccess: false,
          ),
        ),
      );

      expect(governor.totalSandboxCount, 3);
    });
  });

  group('Runtime Law', () {
    test('10 runtime laws are defined', () {
      expect(RuntimeConstitution.laws.length, 10);
    });

    test('each law has unique id', () {
      final ids = RuntimeConstitution.laws.map((l) => l.id).toSet();
      expect(ids.length, 10);
    });

    test('each law has description and enforcement', () {
      for (final law in RuntimeConstitution.laws) {
        expect(law.description, isNotEmpty);
        expect(law.enforcement, isNotEmpty);
      }
    });
  });

  group('Runtime Law Enforcer', () {
    late HybridLogicalClock clock;
    late SecurityManager securityManager;
    late RuntimeLawEnforcer enforcer;

    setUp(() {
      clock = HybridLogicalClock(nodeId: 'enforcer');
      securityManager = SecurityManager();
      enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
    });

    test('enforce capability routing - compliant', () {
      final result = enforcer.enforceCapabilityRouting('sb-1', 'storage.read', true);
      expect(result.compliant, isTrue);
    });

    test('enforce capability routing - violation', () {
      final result = enforcer.enforceCapabilityRouting('sb-1', 'storage.read', false);
      expect(result.compliant, isFalse);
      expect(result.lawId, RuntimeLawId.noBypassCapabilityRouter);
    });

    test('enforce scheduler usage - violation', () {
      final result = enforcer.enforceSchedulerUsage('sb-1', false);
      expect(result.compliant, isFalse);
      expect(result.lawId, RuntimeLawId.noBypassScheduler);
    });

    test('enforce no global state - violation', () {
      final result = enforcer.enforceNoGlobalState('sb-1', true);
      expect(result.compliant, isFalse);
      expect(result.lawId, RuntimeLawId.noGlobalStateSharing);
    });

    test('enforce no side channels - violation', () {
      final result = enforcer.enforceNoSideChannels('sb-1', true);
      expect(result.compliant, isFalse);
    });

    test('enforce tracing - violation', () {
      final result = enforcer.enforceTracing('sb-1', false);
      expect(result.compliant, isFalse);
    });

    test('enforce budget - violation', () {
      final result = enforcer.enforceBudget('sb-1', false);
      expect(result.compliant, isFalse);
    });

    test('enforce trust level - compliant', () {
      final result = enforcer.enforceTrustLevel('sb-1', TrustLevel.verified, TrustLevel.system);
      expect(result.compliant, isTrue);
    });

    test('enforce trust level - violation', () {
      final result = enforcer.enforceTrustLevel('sb-1', TrustLevel.system, TrustLevel.untrusted);
      expect(result.compliant, isFalse);
    });

    test('violations are logged by security manager', () {
      enforcer.enforceCapabilityRouting('sb-1', 'storage.read', false);

      final auditLog = securityManager.auditLog();
      expect(auditLog.any((e) => e.action == 'law.violation'), isTrue);
    });

    test('query violations per sandbox', () {
      enforcer.enforceCapabilityRouting('sb-1', 'cap', false);
      enforcer.enforceSchedulerUsage('sb-1', false);
      enforcer.enforceCapabilityRouting('sb-2', 'cap', true);

      final sb1Violations = enforcer.violationsFor('sb-1');
      expect(sb1Violations.length, 2);

      final sb2Violations = enforcer.violationsFor('sb-2');
      expect(sb2Violations.length, 0);
    });

    test('total violation count', () {
      enforcer.enforceCapabilityRouting('sb-1', 'cap', false);
      enforcer.enforceSchedulerUsage('sb-1', false);
      enforcer.enforceNoGlobalState('sb-1', true);

      expect(enforcer.totalViolations(), 3);
    });
  });

  group('RFC-008 Sandbox Runtime Spec', () {
    test('RFC-008 is registered as proposed', () {
      final registry = RuntimeSpecRegistry();
      final rfc = registry.getRfc('RFC-008');

      expect(rfc, isNotNull);
      expect(rfc!.title, 'Sandbox Runtime');
      expect(rfc.status, RfcStatus.proposed);
      expect(rfc.category, RfcCategory.core);
    });

    test('RFC-008 has specification', () {
      final registry = RuntimeSpecRegistry();
      final rfc = registry.getRfc('RFC-008');

      expect(rfc!.specification, isNotEmpty);
      expect(rfc.motivation, isNotEmpty);
      expect(rfc.breakingChanges, isNotNull);
      expect(rfc.migrationGuide, isNotNull);
    });

    test('total RFCs now 8', () {
      final registry = RuntimeSpecRegistry();
      expect(registry.rfcs.length, 8);
    });
  });

  group('Sandbox Resources', () {
    test('capability allowed with wildcard', () {
      final resources = SandboxResources(
        budget: const ResourceBudget(),
        usage: ResourceUsage(),
        allowedCapabilities: {'*'},
        trustBoundary: const TrustBoundary(boundaryId: 'test'),
      );

      expect(resources.isCapabilityAllowed('anything'), isTrue);
    });

    test('capability denied by denied list', () {
      final resources = SandboxResources(
        budget: const ResourceBudget(),
        usage: ResourceUsage(),
        allowedCapabilities: {'*'},
        deniedCapabilities: {'storage.delete'},
        trustBoundary: const TrustBoundary(boundaryId: 'test'),
      );

      expect(resources.isCapabilityAllowed('storage.read'), isTrue);
      expect(resources.isCapabilityAllowed('storage.delete'), isFalse);
    });

    test('capability denied by trust boundary', () {
      final resources = SandboxResources(
        budget: const ResourceBudget(),
        usage: ResourceUsage(),
        trustBoundary: const TrustBoundary(
          boundaryId: 'restricted',
          allowedCapabilities: {'storage.read'},
        ),
      );

      expect(resources.isCapabilityAllowed('storage.read'), isTrue);
      expect(resources.isCapabilityAllowed('storage.write'), isFalse);
    });

    test('hasBudgetRemaining', () {
      final resources = SandboxResources(
        budget: const ResourceBudget(maxTokens: 100, maxStreams: 2, maxTasks: 5),
        usage: ResourceUsage(),
        trustBoundary: const TrustBoundary(boundaryId: 'test'),
      );

      expect(resources.hasBudgetRemaining(), isTrue);
    });
  });

  group('Sandbox Identity', () {
    test('runtime identity format', () {
      final identity = SandboxIdentity(
        sandboxId: 'sb-42',
        type: SandboxType.agent,
        pluginId: 'agent.main',
        trustLevel: TrustLevel.signed,
        createdBy: 'system',
        createdAt: 1000,
      );

      expect(identity.runtimeIdentity, 'sandbox:sb-42:agent.main');
    });
  });
}
