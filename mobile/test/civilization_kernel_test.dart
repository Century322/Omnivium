import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/civilization_kernel.dart';
import 'package:omnivium/core/runtime/sandbox/runtime_law.dart';
import 'package:omnivium/core/runtime/sandbox/sovereign_identity.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/stability/security.dart';

void main() {
  late CivilizationKernel kernel;

  setUp(() {
    final clock = HybridLogicalClock(nodeId: 'kernel-test');
    final securityManager = SecurityManager();
    final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
    kernel = CivilizationKernel(nodeId: 'node-A', enforcer: enforcer);
  });

  group('CivilizationKernel — Kernel Construction', () {
    test('kernel has all subsystems', () {
      expect(kernel.traceGraph, isNotNull);
      expect(kernel.ledger, isNotNull);
      expect(kernel.evolutionEngine, isNotNull);
      expect(kernel.reputationEconomy, isNotNull);
      expect(kernel.judiciary, isNotNull);
      expect(kernel.consensus, isNotNull);
      expect(kernel.federatedReputation, isNotNull);
      expect(kernel.legislature, isNotNull);
      expect(kernel.transport, isNotNull);
      expect(kernel.economy, isNotNull);
      expect(kernel.identity, isNotNull);
    });

    test('kernel identity is sovereign', () {
      expect(kernel.identity.did, startsWith('did:omnivium:'));
      expect(kernel.identity.nodeId, 'node-A');
      expect(SovereignIdentity.verify(kernel.identity), isTrue);
    });

    test('kernel without network has null network getter', () {
      expect(kernel.network, isNull);
    });

    test('kernel with network has network getter', () {
      final clock = HybridLogicalClock(nodeId: 'test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      final k = CivilizationKernel(nodeId: 'node-A', enforcer: enforcer, enableNetwork: true);
      expect(k.network, isNotNull);
    });
  });

  group('CivilizationKernel — syscall: lawEnforce', () {
    test('compliant invocation returns success', () {
      final result = kernel.syscall(KernelCall.lawEnforce, {
        'sandboxId': 'sandbox-1',
        'capabilityId': 'storage.read',
        'callerTrust': 'verified',
        'requiredTrust': 'verified',
        'routed': true,
        'traced': true,
      });
      expect(result.success, isTrue);
      expect(result.data['compliant'], isTrue);
    });

    test('bypass attempt returns violation', () {
      final result = kernel.syscall(KernelCall.lawEnforce, {
        'sandboxId': 'sandbox-1',
        'capabilityId': 'storage.read',
        'routed': false,
        'traced': true,
      });
      expect(result.success, isTrue);
      expect(result.data['compliant'], isFalse);
      expect(result.data['law'], 'noBypassCapabilityRouter');
    });

    test('insufficient trust returns violation', () {
      final result = kernel.syscall(KernelCall.lawEnforce, {
        'sandboxId': 'sandbox-1',
        'capabilityId': 'runtime.shutdown',
        'callerTrust': 'untrusted',
        'requiredTrust': 'system',
        'routed': true,
        'traced': true,
      });
      expect(result.data['compliant'], isFalse);
    });

    test('missing params returns failure', () {
      final result = kernel.syscall(KernelCall.lawEnforce, {});
      expect(result.success, isFalse);
    });
  });

  group('CivilizationKernel — syscall: trustQuery', () {
    test('query returns score for entity', () {
      kernel.syscall(KernelCall.lawEnforce, {
        'sandboxId': 'sandbox-1',
        'capabilityId': 'cap-1',
        'routed': true,
        'traced': true,
      });
      final result = kernel.syscall(KernelCall.trustQuery, {'entityId': 'sandbox-1'});
      expect(result.success, isTrue);
      expect(result.data.containsKey('score'), isTrue);
      expect(result.data.containsKey('trustLevel'), isTrue);
    });

    test('missing entityId returns failure', () {
      final result = kernel.syscall(KernelCall.trustQuery, {});
      expect(result.success, isFalse);
    });
  });

  group('CivilizationKernel — syscall: governanceAdjudicate', () {
    test('adjudicate returns sanction', () {
      final result = kernel.syscall(KernelCall.governanceAdjudicate, {
        'sandboxId': 'sandbox-1',
        'violationType': 'bypassAttempt',
      });
      expect(result.success, isTrue);
      expect(result.data.containsKey('sanctionType'), isTrue);
    });

    test('missing params returns failure', () {
      final result = kernel.syscall(KernelCall.governanceAdjudicate, {});
      expect(result.success, isFalse);
    });
  });

  group('CivilizationKernel — syscall: diplomacySync', () {
    test('sync sends constitution to target', () {
      final result = kernel.syscall(KernelCall.diplomacySync, {'targetId': 'node-B'});
      expect(result.success, isTrue);
      expect(result.data['target'], 'node-B');
    });

    test('missing targetId returns failure', () {
      final result = kernel.syscall(KernelCall.diplomacySync, {});
      expect(result.success, isFalse);
    });
  });

  group('CivilizationKernel — syscall: evolutionPropose', () {
    test('propose creates legislative proposal', () {
      final result = kernel.syscall(KernelCall.evolutionPropose, {
        'description': 'Strengthen scheduler law',
        'targetLaw': 'noBypassScheduler',
        'proposedChange': 'Add enforcement',
        'rationale': 'Too many bypasses',
      });
      expect(result.success, isTrue);
      expect(result.data['stage'], 'proposed');
      expect(result.data.containsKey('proposalId'), isTrue);
    });

    test('missing params returns failure', () {
      final result = kernel.syscall(KernelCall.evolutionPropose, {});
      expect(result.success, isFalse);
    });
  });

  group('CivilizationKernel — syscall: economicsTransact', () {
    test('earn adds credits', () {
      final result = kernel.syscall(KernelCall.economicsTransact, {
        'entityId': 'plugin-1',
        'action': 'earn',
        'amount': 50.0,
      });
      expect(result.success, isTrue);
      expect(result.data['action'], 'earn');
    });

    test('spend deducts credits', () {
      kernel.syscall(KernelCall.economicsTransact, {
        'entityId': 'plugin-1',
        'action': 'earn',
        'amount': 100.0,
      });
      final result = kernel.syscall(KernelCall.economicsTransact, {
        'entityId': 'plugin-1',
        'action': 'spend',
        'amount': 30.0,
      });
      expect(result.success, isTrue);
    });

    test('spend more than balance fails', () {
      final result = kernel.syscall(KernelCall.economicsTransact, {
        'entityId': 'plugin-2',
        'action': 'spend',
        'amount': 999.0,
      });
      expect(result.success, isFalse);
      expect(result.error, contains('insufficient'));
    });

    test('penalty imposes fine', () {
      final result = kernel.syscall(KernelCall.economicsTransact, {
        'entityId': 'plugin-1',
        'action': 'penalty',
        'amount': 10.0,
      });
      expect(result.success, isTrue);
      expect(result.data['action'], 'penalty');
    });

    test('missing params returns failure', () {
      final result = kernel.syscall(KernelCall.economicsTransact, {});
      expect(result.success, isFalse);
    });
  });

  group('CivilizationKernel — syscall: sovereigntyIdentify', () {
    test('returns identity information', () {
      final result = kernel.syscall(KernelCall.sovereigntyIdentify, {});
      expect(result.success, isTrue);
      expect(result.data['did'], startsWith('did:omnivium:'));
      expect(result.data['nodeId'], 'node-A');
      expect(result.data['verified'], isTrue);
      expect(result.data.containsKey('publicKey'), isTrue);
    });
  });

  group('CivilizationKernel — syscall: consensusVote', () {
    test('cast vote on amendment', () {
      final result = kernel.syscall(KernelCall.consensusVote, {
        'amendmentId': 'amend-1',
        'support': true,
        'reason': 'Good law',
      });
      expect(result.success, isTrue);
      expect(result.data['support'], isTrue);
    });

    test('missing amendmentId returns failure', () {
      final result = kernel.syscall(KernelCall.consensusVote, {});
      expect(result.success, isFalse);
    });
  });

  group('CivilizationKernel — syscall: judiciaryTry', () {
    test('try case returns sanction', () {
      final result = kernel.syscall(KernelCall.judiciaryTry, {
        'sandboxId': 'sandbox-1',
        'violationType': 'budgetExceeded',
      });
      expect(result.success, isTrue);
      expect(result.data.containsKey('type'), isTrue);
    });
  });

  group('CivilizationKernel — syscall: reputationScore', () {
    test('returns local and federated scores', () {
      kernel.syscall(KernelCall.lawEnforce, {
        'sandboxId': 'sandbox-1',
        'capabilityId': 'cap-1',
        'routed': true,
        'traced': true,
      });
      final result = kernel.syscall(KernelCall.reputationScore, {'entityId': 'sandbox-1'});
      expect(result.success, isTrue);
      expect(result.data.containsKey('localScore'), isTrue);
      expect(result.data.containsKey('federatedScore'), isTrue);
      expect(result.data.containsKey('trustLevel'), isTrue);
    });
  });

  group('CivilizationKernel — syscall: federationJoin', () {
    test('join federation returns accepted', () {
      final result = kernel.syscall(KernelCall.federationJoin, {'federationId': 'fed-1'});
      expect(result.success, isTrue);
      expect(result.data['federationId'], 'fed-1');
      expect(result.data['accepted'], isTrue);
    });
  });

  group('CivilizationKernel — syscall: passportIssue', () {
    test('issue passport for entity', () {
      kernel.syscall(KernelCall.lawEnforce, {
        'sandboxId': 'sandbox-1',
        'capabilityId': 'cap-1',
        'routed': true,
        'traced': true,
      });
      final result = kernel.syscall(KernelCall.passportIssue, {'entityId': 'sandbox-1'});
      expect(result.success, isTrue);
      expect(result.data.containsKey('score'), isTrue);
    });
  });

  group('CivilizationKernel — syscall: byzantineReport', () {
    test('report without network returns failure', () {
      final result = kernel.syscall(KernelCall.byzantineReport, {'accusedId': 'node-C'});
      expect(result.success, isFalse);
    });

    test('report with network returns success', () {
      final clock = HybridLogicalClock(nodeId: 'test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      final k = CivilizationKernel(nodeId: 'node-A', enforcer: enforcer, enableNetwork: true);
      final result = k.syscall(KernelCall.byzantineReport, {'accusedId': 'node-C'});
      expect(result.success, isTrue);
      expect(result.data['reported'], isTrue);
    });
  });

  group('CivilizationKernel — syscall: heartbeat', () {
    test('heartbeat without network returns failure', () {
      final result = kernel.syscall(KernelCall.heartbeat, {'targetId': 'node-B'});
      expect(result.success, isFalse);
    });

    test('heartbeat with network returns success', () {
      final clock = HybridLogicalClock(nodeId: 'test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      final k = CivilizationKernel(nodeId: 'node-A', enforcer: enforcer, enableNetwork: true);
      final result = k.syscall(KernelCall.heartbeat, {'targetId': 'node-B'});
      expect(result.success, isTrue);
    });
  });

  group('CivilizationKernel — Call Logging', () {
    test('callLog records all syscalls', () {
      kernel.syscall(KernelCall.sovereigntyIdentify, {});
      kernel.syscall(KernelCall.trustQuery, {'entityId': 'test'});
      expect(kernel.callLog.length, 2);
      expect(kernel.callLog[0], KernelCall.sovereigntyIdentify);
      expect(kernel.callLog[1], KernelCall.trustQuery);
    });

    test('callCounts tracks frequency', () {
      kernel.syscall(KernelCall.sovereigntyIdentify, {});
      kernel.syscall(KernelCall.sovereigntyIdentify, {});
      kernel.syscall(KernelCall.trustQuery, {'entityId': 'test'});
      expect(kernel.callCounts[KernelCall.sovereigntyIdentify], 2);
      expect(kernel.callCounts[KernelCall.trustQuery], 1);
    });
  });

  group('CivilizationKernel — Ledger Integration', () {
    test('every syscall is recorded in ledger', () {
      kernel.syscall(KernelCall.sovereigntyIdentify, {});
      kernel.syscall(KernelCall.trustQuery, {'entityId': 'test'});
      expect(kernel.ledger.verifyIntegrity(), isTrue);
    });
  });

  group('CivilizationKernel — Full Pipeline', () {
    test('law violation → adjudication → penalty pipeline', () {
      kernel.syscall(KernelCall.lawEnforce, {
        'sandboxId': 'sandbox-1',
        'capabilityId': 'storage.read',
        'routed': false,
        'traced': true,
      });

      kernel.syscall(KernelCall.governanceAdjudicate, {
        'sandboxId': 'sandbox-1',
        'violationType': 'bypassAttempt',
      });

      kernel.syscall(KernelCall.economicsTransact, {
        'entityId': 'sandbox-1',
        'action': 'penalty',
        'amount': 25.0,
      });

      final trust = kernel.syscall(KernelCall.trustQuery, {'entityId': 'sandbox-1'});
      expect(trust.success, isTrue);
      expect(kernel.ledger.verifyIntegrity(), isTrue);
    });

    test('compliance → reputation → passport pipeline', () {
      for (var i = 0; i < 5; i++) {
        kernel.syscall(KernelCall.lawEnforce, {
          'sandboxId': 'sandbox-2',
          'capabilityId': 'cap-$i',
          'routed': true,
          'traced': true,
        });
      }

      final score = kernel.syscall(KernelCall.reputationScore, {'entityId': 'sandbox-2'});
      expect(score.success, isTrue);

      final passport = kernel.syscall(KernelCall.passportIssue, {'entityId': 'sandbox-2'});
      expect(passport.success, isTrue);
    });

    test('kernel syscall covers all 16 calls', () {
      expect(KernelCall.values.length, 16);
    });
  });
}
