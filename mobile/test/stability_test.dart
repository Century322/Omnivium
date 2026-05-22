import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/stability/versioning.dart';
import 'package:omnivium/core/runtime/stability/security.dart';
import 'package:omnivium/core/runtime/stability/runtime_spec.dart';

void main() {
  group('Semantic Versioning', () {
    test('parse version string', () {
      final v = SemanticVersion.parse('1.2.3');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
    });

    test('parse version with pre-release', () {
      final v = SemanticVersion.parse('0.8.0-alpha');
      expect(v.major, 0);
      expect(v.minor, 8);
      expect(v.patch, 0);
      expect(v.preRelease, 'alpha');
      expect(v.isPreRelease, isTrue);
    });

    test('parse version with build metadata', () {
      final v = SemanticVersion.parse('1.0.0+build.123');
      expect(v.major, 1);
      expect(v.buildMetadata, 'build.123');
    });

    test('version comparison', () {
      final v1 = SemanticVersion(major: 1, minor: 0, patch: 0);
      final v2 = SemanticVersion(major: 1, minor: 1, patch: 0);
      final v3 = SemanticVersion(major: 2, minor: 0, patch: 0);

      expect(v1 < v2, isTrue);
      expect(v2 < v3, isTrue);
      expect(v3 > v1, isTrue);
      expect(v1 <= v1, isTrue);
    });

    test('major version compatibility', () {
      final v1 = SemanticVersion(major: 1, minor: 0, patch: 0);
      final v2 = SemanticVersion(major: 1, minor: 5, patch: 0);
      final v3 = SemanticVersion(major: 2, minor: 0, patch: 0);

      expect(v1.isCompatibleWith(v2), isTrue);
      expect(v1.isCompatibleWith(v3), isFalse);
    });

    test('backward compatibility for stable versions', () {
      final v10 = SemanticVersion(major: 1, minor: 0, patch: 0);
      final v15 = SemanticVersion(major: 1, minor: 5, patch: 0);
      final v20 = SemanticVersion(major: 2, minor: 0, patch: 0);

      expect(v15.isBackwardCompatibleWith(v10), isTrue);
      expect(v10.isBackwardCompatibleWith(v15), isFalse);
      expect(v20.isBackwardCompatibleWith(v10), isFalse);
    });

    test('zero major version is not backward compatible', () {
      final v01 = SemanticVersion(major: 0, minor: 1, patch: 0);
      final v02 = SemanticVersion(major: 0, minor: 2, patch: 0);

      expect(v01.isBackwardCompatibleWith(v02), isFalse);
    });

    test('version toString', () {
      expect(SemanticVersion(major: 1, minor: 2, patch: 3).toString(), '1.2.3');
      expect(
        SemanticVersion(major: 0, minor: 8, patch: 0, preRelease: 'alpha').toString(),
        '0.8.0-alpha',
      );
    });

    test('version equality', () {
      final v1 = SemanticVersion(major: 1, minor: 2, patch: 3);
      final v2 = SemanticVersion(major: 1, minor: 2, patch: 3);
      expect(v1 == v2, isTrue);
    });
  });

  group('Deprecation Lifecycle', () {
    test('deprecation notice creation', () {
      final notice = DeprecationNotice(
        id: 'DEP-001',
        feature: 'old.capability',
        deprecatedIn: SemanticVersion(major: 0, minor: 7, patch: 0),
        removedIn: SemanticVersion(major: 1, minor: 0, patch: 0),
        replacement: 'new.capability',
      );

      expect(notice.level, DeprecationLevel.deprecated);
      expect(notice.feature, 'old.capability');
    });

    test('isDeprecatedIn checks version', () {
      final notice = DeprecationNotice(
        id: 'DEP-001',
        feature: 'old.cap',
        deprecatedIn: SemanticVersion(major: 0, minor: 7, patch: 0),
        replacement: 'new.cap',
      );

      expect(notice.isDeprecatedIn(SemanticVersion(major: 0, minor: 8, patch: 0)), isTrue);
      expect(notice.isDeprecatedIn(SemanticVersion(major: 0, minor: 6, patch: 0)), isFalse);
    });

    test('isRemovedIn checks version', () {
      final notice = DeprecationNotice(
        id: 'DEP-001',
        feature: 'old.cap',
        deprecatedIn: SemanticVersion(major: 0, minor: 7, patch: 0),
        removedIn: SemanticVersion(major: 1, minor: 0, patch: 0),
        replacement: 'new.cap',
      );

      expect(notice.isRemovedIn(SemanticVersion(major: 1, minor: 0, patch: 0)), isTrue);
      expect(notice.isRemovedIn(SemanticVersion(major: 0, minor: 9, patch: 0)), isFalse);
    });
  });

  group('Runtime Version Registry', () {
    test('current version is defined', () {
      final registry = RuntimeVersionRegistry.current();
      expect(registry.runtimeVersion.major, 0);
      expect(registry.protocolVersion.major, 1);
    });

    test('register and query capability version', () {
      final registry = RuntimeVersionRegistry.current();
      registry.registerCapability(CapabilityVersion(
        capabilityId: 'storage.read',
        version: SemanticVersion(major: 1, minor: 0, patch: 0),
      ));

      final cap = registry.capabilityVersion('storage.read');
      expect(cap, isNotNull);
      expect(cap!.version.major, 1);
    });

    test('add and query deprecations', () {
      final registry = RuntimeVersionRegistry.current();
      registry.addDeprecation(const DeprecationNotice(
        id: 'DEP-001',
        feature: 'old.cap',
        deprecatedIn: SemanticVersion(major: 0, minor: 7, patch: 0),
        replacement: 'new.cap',
      ));

      expect(registry.deprecations.length, 1);
      expect(registry.activeDeprecations().length, 1);
    });

    test('check compatibility between registries', () {
      final regA = RuntimeVersionRegistry(
        runtimeVersion: const SemanticVersion(major: 0, minor: 8, patch: 0),
        protocolVersion: const ProtocolVersion(major: 1, minor: 0),
      );

      final regB = RuntimeVersionRegistry(
        runtimeVersion: const SemanticVersion(major: 0, minor: 8, patch: 0),
        protocolVersion: const ProtocolVersion(major: 1, minor: 0),
      );

      final result = regA.checkCompatibility(regB);
      expect(result.isCompatible, isTrue);
      expect(result.issues, isEmpty);
    });

    test('incompatible major versions detected', () {
      final regA = RuntimeVersionRegistry(
        runtimeVersion: const SemanticVersion(major: 1, minor: 0, patch: 0),
        protocolVersion: const ProtocolVersion(major: 1, minor: 0),
      );

      final regB = RuntimeVersionRegistry(
        runtimeVersion: const SemanticVersion(major: 2, minor: 0, patch: 0),
        protocolVersion: const ProtocolVersion(major: 1, minor: 0),
      );

      final result = regA.checkCompatibility(regB);
      expect(result.isCompatible, isFalse);
      expect(result.breakingIssues, isNotEmpty);
    });

    test('protocol version mismatch detected', () {
      final regA = RuntimeVersionRegistry(
        runtimeVersion: const SemanticVersion(major: 0, minor: 8, patch: 0),
        protocolVersion: const ProtocolVersion(major: 1, minor: 0),
      );

      final regB = RuntimeVersionRegistry(
        runtimeVersion: const SemanticVersion(major: 0, minor: 8, patch: 0),
        protocolVersion: const ProtocolVersion(major: 2, minor: 0),
      );

      final result = regA.checkCompatibility(regB);
      expect(result.isCompatible, isFalse);
    });

    test('missing capability is a warning not breaking', () {
      final regA = RuntimeVersionRegistry(
        runtimeVersion: const SemanticVersion(major: 0, minor: 8, patch: 0),
        protocolVersion: const ProtocolVersion(major: 1, minor: 0),
      );
      regA.registerCapability(CapabilityVersion(
        capabilityId: 'storage.read',
        version: SemanticVersion(major: 1, minor: 0, patch: 0),
      ));

      final regB = RuntimeVersionRegistry(
        runtimeVersion: const SemanticVersion(major: 0, minor: 8, patch: 0),
        protocolVersion: const ProtocolVersion(major: 1, minor: 0),
      );

      final result = regA.checkCompatibility(regB);
      expect(result.isCompatible, isTrue);
      expect(result.warnings, isNotEmpty);
    });

    test('migration steps between versions', () {
      final registry = RuntimeVersionRegistry.current();
      registry.addMigration(const MigrationStep(
        fromVersion: '0.7.0',
        toVersion: '0.8.0',
        description: 'Add governance layer',
        actions: ['Initialize PolicyEngine', 'Initialize ResourceController'],
      ));

      final steps = registry.migrationsBetween(
        SemanticVersion(major: 0, minor: 7, patch: 0),
        SemanticVersion(major: 0, minor: 8, patch: 0),
      );

      expect(steps.length, 1);
    });
  });

  group('Security Manager', () {
    test('plugin trust level management', () {
      final manager = SecurityManager();
      manager.setPluginTrustLevel('system-plugin', TrustLevel.system);
      manager.setPluginTrustLevel('untrusted-plugin', TrustLevel.untrusted);

      expect(manager.pluginTrustLevel('system-plugin'), TrustLevel.system);
      expect(manager.pluginTrustLevel('untrusted-plugin'), TrustLevel.untrusted);
      expect(manager.pluginTrustLevel('unknown'), TrustLevel.untrusted);
    });

    test('plugin allowed based on trust level', () {
      final manager = SecurityManager(policy: const SecurityPolicy(
        minimumPluginTrustLevel: TrustLevel.verified,
      ));

      manager.setPluginTrustLevel('verified-plugin', TrustLevel.verified);
      manager.setPluginTrustLevel('untrusted-plugin', TrustLevel.untrusted);

      expect(manager.isPluginAllowed('verified-plugin'), isTrue);
      expect(manager.isPluginAllowed('untrusted-plugin'), isFalse);
    });

    test('blocked plugins are always denied', () {
      final manager = SecurityManager();
      manager.setPluginTrustLevel('bad-plugin', TrustLevel.blocked);

      expect(manager.isPluginAllowed('bad-plugin'), isFalse);
    });

    test('capability authorization', () {
      final manager = SecurityManager();
      manager.registerCapabilityAuth(const CapabilityAuth(
        capabilityId: 'storage.delete',
        requiredTrustLevel: TrustLevel.system,
        allowedCallerPatterns: {'system.*'},
      ));

      expect(
        manager.isCapabilityInvocationAllowed('storage.delete', 'system.main', TrustLevel.system),
        isTrue,
      );
      expect(
        manager.isCapabilityInvocationAllowed('storage.delete', 'agent.main', TrustLevel.verified),
        isFalse,
      );
    });

    test('capability auth with wildcard pattern', () {
      final manager = SecurityManager();
      manager.registerCapabilityAuth(const CapabilityAuth(
        capabilityId: 'storage.read',
        requiredTrustLevel: TrustLevel.verified,
        allowedCallerPatterns: {'*'},
      ));

      expect(
        manager.isCapabilityInvocationAllowed('storage.read', 'any.caller', TrustLevel.verified),
        isTrue,
      );
    });

    test('capability auth with prefix pattern', () {
      final manager = SecurityManager();
      manager.registerCapabilityAuth(const CapabilityAuth(
        capabilityId: 'storage.read',
        requiredTrustLevel: TrustLevel.verified,
        allowedCallerPatterns: {'agent.*'},
      ));

      expect(
        manager.isCapabilityInvocationAllowed('storage.read', 'agent.main', TrustLevel.verified),
        isTrue,
      );
      expect(
        manager.isCapabilityInvocationAllowed('storage.read', 'plugin.main', TrustLevel.verified),
        isFalse,
      );
    });

    test('auth rate limiting', () {
      final manager = SecurityManager(policy: const SecurityPolicy(
        maxAuthRetries: 3,
        authLockoutDuration: Duration(milliseconds: 100),
      ));

      expect(manager.checkAuthRateLimit('user-1'), isTrue);
      manager.recordAuthFailure('user-1');
      manager.recordAuthFailure('user-1');
      manager.recordAuthFailure('user-1');

      expect(manager.checkAuthRateLimit('user-1'), isFalse);
    });

    test('auth success resets retries', () {
      final manager = SecurityManager(policy: const SecurityPolicy(maxAuthRetries: 3));

      manager.recordAuthFailure('user-1');
      manager.recordAuthFailure('user-1');
      manager.recordAuthSuccess('user-1');

      expect(manager.checkAuthRateLimit('user-1'), isTrue);
    });

    test('audit logging', () {
      final manager = SecurityManager();

      manager.audit('capability.invoke', 'agent.main', context: {'cap': 'storage.read'});
      manager.audit('policy.deny', 'agent.main', context: {'rule': 'deny-agent-delete'}, success: false);

      final log = manager.auditLog();
      expect(log.length, 2);
      expect(log[0].success, isTrue);
      expect(log[1].success, isFalse);
    });

    test('audit log with limit', () {
      final manager = SecurityManager();

      for (var i = 0; i < 10; i++) {
        manager.audit('action', 'actor');
      }

      final limited = manager.auditLog(limit: 3);
      expect(limited.length, 3);
    });

    test('remote node trust check', () {
      final manager = SecurityManager(policy: const SecurityPolicy(
        minimumRemoteNodeTrustLevel: TrustLevel.verified,
      ));

      expect(manager.isRemoteNodeAllowed('node-A', TrustLevel.verified), isTrue);
      expect(manager.isRemoteNodeAllowed('node-B', TrustLevel.untrusted), isFalse);
      expect(manager.isRemoteNodeAllowed('node-C', TrustLevel.blocked), isFalse);
    });
  });

  group('Secret Store', () {
    test('store and retrieve secret', () {
      final store = SecretStore();
      store.store('api-key', 'secret-value',
          scope: 'storage', expiresAt: DateTime.now().millisecondsSinceEpoch + 60000);

      final value = store.retrieve('api-key', requesterId: 'plugin-A', trustLevel: TrustLevel.verified);
      expect(value, 'secret-value');
    });

    test('retrieve non-existent secret returns null', () {
      final store = SecretStore();
      final value = store.retrieve('nonexistent', requesterId: 'plugin-A', trustLevel: TrustLevel.verified);
      expect(value, isNull);
    });

    test('revoke secret', () {
      final store = SecretStore();
      store.store('api-key', 'secret-value',
          scope: 'storage', expiresAt: DateTime.now().millisecondsSinceEpoch + 60000);

      store.revoke('api-key');
      expect(store.exists('api-key'), isFalse);
    });

    test('expired secret returns null', () {
      final store = SecretStore();
      store.store('api-key', 'secret-value',
          scope: 'storage', expiresAt: DateTime.now().millisecondsSinceEpoch - 1);

      final value = store.retrieve('api-key', requesterId: 'plugin-A', trustLevel: TrustLevel.verified);
      expect(value, isNull);
    });
  });

  group('Trust Boundary', () {
    test('capability restriction', () {
      const boundary = TrustBoundary(
        boundaryId: 'sandbox',
        allowedCapabilities: {'storage.read', 'storage.write'},
      );

      expect(boundary.isCapabilityAllowed('storage.read'), isTrue);
      expect(boundary.isCapabilityAllowed('storage.delete'), isFalse);
      expect(boundary.isCapabilityAllowed('agent.chat'), isFalse);
    });

    test('wildcard capability allows all', () {
      const boundary = TrustBoundary(
        boundaryId: 'open',
        allowedCapabilities: {'*'},
      );

      expect(boundary.isCapabilityAllowed('anything'), isTrue);
    });

    test('empty allowed capabilities allows all', () {
      const boundary = TrustBoundary(boundaryId: 'default');

      expect(boundary.isCapabilityAllowed('storage.read'), isTrue);
    });

    test('node restriction', () {
      const boundary = TrustBoundary(
        boundaryId: 'restricted',
        allowedNodes: {'node-A', 'node-B'},
      );

      expect(boundary.isNodeAllowed('node-A'), isTrue);
      expect(boundary.isNodeAllowed('node-C'), isFalse);
    });

    test('merge boundaries takes intersection', () {
      const a = TrustBoundary(
        boundaryId: 'a',
        allowedCapabilities: {'storage.read', 'storage.write'},
        allowNetworkAccess: true,
      );

      const b = TrustBoundary(
        boundaryId: 'b',
        allowedCapabilities: {'storage.read', 'agent.chat'},
        allowNetworkAccess: false,
      );

      final merged = a.merge(b);
      expect(merged.isCapabilityAllowed('storage.read'), isTrue);
      expect(merged.isCapabilityAllowed('storage.write'), isFalse);
      expect(merged.allowNetworkAccess, isFalse);
    });
  });

  group('Runtime Spec / RFC', () {
    test('all 8 RFCs are registered', () {
      final registry = RuntimeSpecRegistry();
      expect(registry.rfcs.length, 8);
    });

    test('7 RFCs are frozen', () {
      final registry = RuntimeSpecRegistry();
      expect(registry.frozenRfcs.length, 7);
    });

    test('RFC-001 defines lifecycle semantics', () {
      final registry = RuntimeSpecRegistry();
      final rfc = registry.getRfc('RFC-001');
      expect(rfc, isNotNull);
      expect(rfc!.title, contains('Lifecycle'));
      expect(rfc.category, RfcCategory.core);
      expect(rfc.status, RfcStatus.frozen);
    });

    test('RFC-003 defines wire protocol', () {
      final registry = RuntimeSpecRegistry();
      final rfc = registry.getRfc('RFC-003');
      expect(rfc, isNotNull);
      expect(rfc!.category, RfcCategory.protocol);
    });

    test('RFC-005 defines distributed invariants', () {
      final registry = RuntimeSpecRegistry();
      final rfc = registry.getRfc('RFC-005');
      expect(rfc, isNotNull);
      expect(rfc!.category, RfcCategory.distributed);
    });

    test('RFC-007 defines security model', () {
      final registry = RuntimeSpecRegistry();
      final rfc = registry.getRfc('RFC-007');
      expect(rfc, isNotNull);
      expect(rfc!.category, RfcCategory.security);
    });

    test('each RFC has unique ID', () {
      final registry = RuntimeSpecRegistry();
      final ids = registry.rfcs.map((r) => r.id).toSet();
      expect(ids.length, 8);
    });

    test('each RFC has non-empty specification', () {
      final registry = RuntimeSpecRegistry();
      for (final rfc in registry.rfcs) {
        expect(rfc.specification, isNotEmpty);
        expect(rfc.motivation, isNotEmpty);
        expect(rfc.summary, isNotEmpty);
      }
    });

    test('new RFC can be registered', () {
      final registry = RuntimeSpecRegistry();
      registry.register(const RuntimeRfc(
        id: 'RFC-009',
        title: 'Future Extension',
        status: RfcStatus.proposed,
        category: RfcCategory.core,
        author: 'runtime-team',
        createdAt: 0,
        summary: 'Future extension placeholder',
        motivation: 'Placeholder for future RFC',
        specification: 'TBD',
      ));

      expect(registry.rfcs.length, 9);
      expect(registry.getRfc('RFC-009')!.status, RfcStatus.proposed);
    });
  });
}
