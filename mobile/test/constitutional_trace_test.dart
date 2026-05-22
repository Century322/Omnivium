import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/runtime_law.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_guard.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_trace.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/stability/security.dart';

void main() {
  group('ConstitutionalTraceGraph — Runtime Jurisprudence', () {
    late ConstitutionalTraceGraph graph;

    setUp(() {
      graph = ConstitutionalTraceGraph();
    });

    test('records compliant and non-compliant decisions', () {
      graph.record(
        sandboxId: 'sb-1',
        operationType: 'capability',
        violatedLaw: null,
        compliant: true,
        escalationBefore: EscalationLevel.warning,
        escalationAfter: EscalationLevel.warning,
        timestamp: 1000,
      );

      graph.record(
        sandboxId: 'sb-1',
        operationType: 'capability',
        violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
        compliant: false,
        capabilityId: 'storage.read',
        callerId: 'plugin.rogue',
        callerTrust: TrustLevel.untrusted,
        escalationBefore: EscalationLevel.warning,
        escalationAfter: EscalationLevel.warning,
        timestamp: 1001,
      );

      expect(graph.totalDecisions, 2);
    });

    test('computes violation counts per law', () {
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 1);
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 2);
      graph.record(sandboxId: 'sb-1', operationType: 'task', violatedLaw: RuntimeLawId.noBypassScheduler, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 3);
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: null, compliant: true, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 4);

      final stats = graph.computeStatistics();

      expect(stats.totalDecisions, 4);
      expect(stats.totalViolations, 3);
      expect(stats.totalCompliant, 1);
      expect(stats.complianceRate, closeTo(0.25, 0.01));
      expect(stats.violationCounts[RuntimeLawId.noBypassCapabilityRouter], 2);
      expect(stats.violationCounts[RuntimeLawId.noBypassScheduler], 1);
    });

    test('identifies most violated laws', () {
      for (var i = 0; i < 5; i++) {
        graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: i);
      }
      for (var i = 0; i < 3; i++) {
        graph.record(sandboxId: 'sb-1', operationType: 'task', violatedLaw: RuntimeLawId.noBudgetBypass, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: i + 10);
      }
      graph.record(sandboxId: 'sb-1', operationType: 'state', violatedLaw: RuntimeLawId.noSideChannels, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 20);

      final mostViolated = graph.computeStatistics().mostViolatedLaws(limit: 3);

      expect(mostViolated[0], RuntimeLawId.noBypassCapabilityRouter);
      expect(mostViolated[1], RuntimeLawId.noBudgetBypass);
      expect(mostViolated[2], RuntimeLawId.noSideChannels);
    });

    test('identifies most dangerous sandboxes', () {
      for (var i = 0; i < 10; i++) {
        graph.record(sandboxId: 'sb-dangerous', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: i);
      }
      for (var i = 0; i < 3; i++) {
        graph.record(sandboxId: 'sb-mild', operationType: 'task', violatedLaw: RuntimeLawId.noBudgetBypass, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: i);
      }

      final dangerous = graph.computeStatistics().mostDangerousSandboxes();

      expect(dangerous[0], 'sb-dangerous');
      expect(dangerous[1], 'sb-mild');
    });

    test('identifies most abused capabilities', () {
      for (var i = 0; i < 7; i++) {
        graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, capabilityId: 'storage.delete', escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: i);
      }
      for (var i = 0; i < 2; i++) {
        graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.trustLevelMustBeRespected, compliant: false, capabilityId: 'runtime.admin', escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: i + 10);
      }

      final abused = graph.computeStatistics().mostAbusedCapabilities();

      expect(abused[0], 'storage.delete');
      expect(abused[1], 'runtime.admin');
    });

    test('tracks escalation path for a sandbox', () {
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: null, compliant: true, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 1);
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.restricted, timestamp: 2);
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, escalationBefore: EscalationLevel.restricted, escalationAfter: EscalationLevel.terminated, timestamp: 3);

      final path = graph.escalationPathFor('sb-1');

      expect(path.decisions.length, 3);
      expect(path.levelTransitions, [EscalationLevel.warning, EscalationLevel.restricted, EscalationLevel.terminated]);
      expect(path.reachedTermination, isTrue);
    });

    test('filters violations by law', () {
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 1);
      graph.record(sandboxId: 'sb-1', operationType: 'task', violatedLaw: RuntimeLawId.noBudgetBypass, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 2);
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 3);

      final routerViolations = graph.violationsForLaw(RuntimeLawId.noBypassCapabilityRouter);
      expect(routerViolations.length, 2);

      final budgetViolations = graph.violationsForLaw(RuntimeLawId.noBudgetBypass);
      expect(budgetViolations.length, 1);
    });

    test('filters decisions by time range', () {
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: null, compliant: true, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 100);
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: null, compliant: true, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 200);
      graph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: null, compliant: true, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 300);

      final range = graph.decisionsInTimeRange(150, 250);
      expect(range.length, 1);
      expect(range[0].timestamp, 200);
    });

    test('JSON serialization preserves forensic data', () {
      final record = graph.record(
        sandboxId: 'sb-forensic',
        operationType: 'capability',
        violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
        compliant: false,
        capabilityId: 'storage.delete',
        callerId: 'plugin.rogue',
        callerTrust: TrustLevel.untrusted,
        escalationBefore: EscalationLevel.warning,
        escalationAfter: EscalationLevel.restricted,
        timestamp: 1234567890,
      );

      final json = record.toJson();
      expect(json['sandbox'], 'sb-forensic');
      expect(json['law'], 'noBypassCapabilityRouter');
      expect(json['compliant'], isFalse);
      expect(json['cap'], 'storage.delete');
      expect(json['caller'], 'plugin.rogue');
      expect(json['trust'], 'untrusted');
      expect(json['escBefore'], 'warning');
      expect(json['escAfter'], 'restricted');
    });
  });

  group('ImmutableAuditLedger — Append-Only Constitutional History', () {
    late ImmutableAuditLedger ledger;

    setUp(() {
      ledger = ImmutableAuditLedger();
    });

    test('starts empty with genesis hash', () {
      expect(ledger.isEmpty, isTrue);
      expect(ledger.length, 0);
      expect(ledger.lastHash, 'genesis');
    });

    test('append creates chained entries', () {
      final entry1 = ledger.append(
        entryType: 'law.violation',
        sandboxId: 'sb-1',
        data: {'law': 'noBypassCapabilityRouter'},
        timestamp: 1000,
      );

      expect(entry1.seq, 0);
      expect(entry1.previousHash, 'genesis');
      expect(entry1.hash, isNotEmpty);

      final entry2 = ledger.append(
        entryType: 'capability.approved',
        sandboxId: 'sb-1',
        data: {'cap': 'storage.read'},
        timestamp: 1001,
      );

      expect(entry2.seq, 1);
      expect(entry2.previousHash, entry1.hash);
      expect(ledger.length, 2);
    });

    test('integrity verification passes for clean ledger', () {
      ledger.append(entryType: 'a', sandboxId: 'sb-1', data: {}, timestamp: 1);
      ledger.append(entryType: 'b', sandboxId: 'sb-2', data: {'x': 1}, timestamp: 2);
      ledger.append(entryType: 'c', sandboxId: 'sb-1', data: {'y': 2}, timestamp: 3);

      expect(ledger.verifyIntegrity(), isTrue);
    });

    test('individual entry verification works', () {
      ledger.append(entryType: 'a', sandboxId: 'sb-1', data: {}, timestamp: 1);
      ledger.append(entryType: 'b', sandboxId: 'sb-2', data: {}, timestamp: 2);

      expect(ledger.verifyEntry(0), isTrue);
      expect(ledger.verifyEntry(1), isTrue);
      expect(ledger.verifyEntry(999), isFalse);
    });

    test('each entry has unique hash', () {
      for (var i = 0; i < 100; i++) {
        ledger.append(entryType: 'op', sandboxId: 'sb-$i', data: {'i': i}, timestamp: i);
      }

      final hashes = ledger.entries.map((e) => e.hash).toSet();
      expect(hashes.length, 100);
    });

    test('filters entries by sandbox', () {
      ledger.append(entryType: 'a', sandboxId: 'sb-1', data: {}, timestamp: 1);
      ledger.append(entryType: 'b', sandboxId: 'sb-2', data: {}, timestamp: 2);
      ledger.append(entryType: 'c', sandboxId: 'sb-1', data: {}, timestamp: 3);

      final sb1Entries = ledger.entriesFor('sb-1');
      expect(sb1Entries.length, 2);
      expect(sb1Entries.every((e) => e.sandboxId == 'sb-1'), isTrue);
    });

    test('filters entries by type', () {
      ledger.append(entryType: 'law.violation', sandboxId: 'sb-1', data: {}, timestamp: 1);
      ledger.append(entryType: 'capability.approved', sandboxId: 'sb-1', data: {}, timestamp: 2);
      ledger.append(entryType: 'law.violation', sandboxId: 'sb-2', data: {}, timestamp: 3);

      final violations = ledger.entriesOfType('law.violation');
      expect(violations.length, 2);
    });

    test('filters entries by sequence range', () {
      for (var i = 0; i < 10; i++) {
        ledger.append(entryType: 'op', sandboxId: 'sb-1', data: {}, timestamp: i);
      }

      final range = ledger.entriesInRange(3, 7);
      expect(range.length, 5);
      expect(range.first.seq, 3);
      expect(range.last.seq, 7);
    });

    test('JSON serialization preserves chain data', () {
      ledger.append(entryType: 'law.violation', sandboxId: 'sb-1', data: {'law': 'test'}, timestamp: 1000);

      final json = ledger.entries.first.toJson();
      expect(json['seq'], 0);
      expect(json['type'], 'law.violation');
      expect(json['sandbox'], 'sb-1');
      expect(json['prevHash'], 'genesis');
      expect(json['hash'], isNotEmpty);
    });
  });

  group('CapabilityProof — Execution Proof Chain', () {
    test('complete proof — all proofs present', () {
      final proof = CapabilityProof.forCapabilityInvocation(
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        budgetApproved: true,
        hasTraceSpan: true,
        trustVerified: true,
        scheduledThroughScheduler: true,
        timestamp: 1000,
        sandboxId: 'sb-1',
      );

      expect(proof.isComplete, isTrue);
      expect(proof.missingProofs(), isEmpty);
    });

    test('incomplete proof — missing proofs identified', () {
      final proof = CapabilityProof.forCapabilityInvocation(
        capabilityId: 'storage.read',
        callerId: 'plugin.rogue',
        callerTrust: TrustLevel.untrusted,
        wasRoutedThroughRouter: false,
        budgetApproved: false,
        hasTraceSpan: false,
        trustVerified: false,
        scheduledThroughScheduler: false,
        timestamp: 1000,
        sandboxId: 'sb-1',
      );

      expect(proof.isComplete, isFalse);
      expect(proof.missingProofs(), ['RouteProof', 'BudgetProof', 'TraceProof', 'TrustProof', 'SchedulerProof']);
    });

    test('partial proof — only route proof missing', () {
      final proof = CapabilityProof.forCapabilityInvocation(
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        wasRoutedThroughRouter: false,
        budgetApproved: true,
        hasTraceSpan: true,
        trustVerified: true,
        scheduledThroughScheduler: true,
        timestamp: 1000,
        sandboxId: 'sb-1',
      );

      expect(proof.isComplete, isFalse);
      expect(proof.missingProofs(), ['RouteProof']);
    });

    test('JSON serialization preserves all proof fields', () {
      final proof = CapabilityProof.forCapabilityInvocation(
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        budgetApproved: true,
        hasTraceSpan: true,
        trustVerified: true,
        scheduledThroughScheduler: true,
        timestamp: 1234567890,
        sandboxId: 'sb-1',
      );

      final json = proof.toJson();
      expect(json['cap'], 'storage.read');
      expect(json['caller'], 'plugin.main');
      expect(json['trust'], 'verified');
      expect(json['route'], isTrue);
      expect(json['budget'], isTrue);
      expect(json['trace'], isTrue);
      expect(json['trustProof'], isTrue);
      expect(json['scheduler'], isTrue);
      expect(json['complete'], isTrue);
    });
  });

  group('ConstitutionalGuard + Trace + Ledger Integration', () {
    late ConstitutionalGuard guard;

    setUp(() {
      final clock = HybridLogicalClock(nodeId: 'trace-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      guard = ConstitutionalGuard(enforcer: enforcer);
    });

    test('guard records trace for every capability check', () {
      guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );

      guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.delete',
        callerId: 'plugin.rogue',
        callerTrust: TrustLevel.untrusted,
        requiredTrust: TrustLevel.system,
        wasRoutedThroughRouter: false,
        hasTraceSpan: true,
      );

      expect(guard.traceGraph.totalDecisions, 2);

      final stats = guard.traceGraph.computeStatistics();
      expect(stats.totalCompliant, 1);
      expect(stats.totalViolations, 1);
    });

    test('guard records ledger for every decision', () {
      guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );

      guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.delete',
        callerId: 'plugin.rogue',
        callerTrust: TrustLevel.untrusted,
        requiredTrust: TrustLevel.system,
        wasRoutedThroughRouter: false,
        hasTraceSpan: true,
      );

      expect(guard.ledger.length, 2);
      expect(guard.ledger.verifyIntegrity(), isTrue);

      final violations = guard.ledger.entriesOfType('law.violation');
      expect(violations.length, 1);

      final approvals = guard.ledger.entriesOfType('capability.approved');
      expect(approvals.length, 1);
    });

    test('guard records trace for task creation', () {
      guard.checkTaskCreation(
        sandboxId: 'sb-1',
        wasScheduledThroughScheduler: true,
        budgetApproved: true,
        hasTraceSpan: true,
      );

      guard.checkTaskCreation(
        sandboxId: 'sb-1',
        wasScheduledThroughScheduler: false,
        budgetApproved: true,
        hasTraceSpan: true,
      );

      expect(guard.traceGraph.totalDecisions, 2);
      expect(guard.ledger.length, 2);
    });

    test('guard records trace for state access', () {
      guard.checkStateAccess(
        sandboxId: 'sb-1',
        accessedGlobalState: false,
        usedSideChannel: false,
        hasTraceSpan: true,
      );

      guard.checkStateAccess(
        sandboxId: 'sb-1',
        accessedGlobalState: true,
        usedSideChannel: false,
        hasTraceSpan: true,
      );

      expect(guard.traceGraph.totalDecisions, 2);
      expect(guard.ledger.length, 2);
    });

    test('full jurisprudence: trace graph + ledger after complex scenario', () {
      guard.checkCapabilityInvocation(
        sandboxId: 'sb-agent',
        capabilityId: 'storage.read',
        callerId: 'agent.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );

      for (var i = 0; i < 4; i++) {
        guard.checkCapabilityInvocation(
          sandboxId: 'sb-agent',
          capabilityId: 'storage.delete',
          callerId: 'agent.rogue',
          callerTrust: TrustLevel.untrusted,
          requiredTrust: TrustLevel.verified,
          wasRoutedThroughRouter: false,
          hasTraceSpan: true,
        );
      }

      final stats = guard.traceGraph.computeStatistics();
      expect(stats.totalDecisions, 5);
      expect(stats.totalCompliant, 1);
      expect(stats.totalViolations, 4);
      expect(stats.complianceRate, closeTo(0.2, 0.01));

      final mostViolated = stats.mostViolatedLaws();
      expect(mostViolated.first, RuntimeLawId.noBypassCapabilityRouter);

      final dangerous = stats.mostDangerousSandboxes();
      expect(dangerous.first, 'sb-agent');

      expect(guard.ledger.verifyIntegrity(), isTrue);

      final path = guard.traceGraph.escalationPathFor('sb-agent');
      expect(path.reachedTermination, isTrue);
    });

    test('ledger integrity survives many operations', () {
      for (var i = 0; i < 50; i++) {
        guard.checkCapabilityInvocation(
          sandboxId: 'sb-$i',
          capabilityId: 'cap-$i',
          callerId: 'plugin-$i',
          callerTrust: TrustLevel.verified,
          requiredTrust: TrustLevel.verified,
          wasRoutedThroughRouter: i % 3 != 0,
          hasTraceSpan: i % 5 != 0,
        );
      }

      expect(guard.ledger.length, 50);
      expect(guard.ledger.verifyIntegrity(), isTrue);
    });
  });
}
