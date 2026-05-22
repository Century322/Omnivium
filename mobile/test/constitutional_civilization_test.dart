import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/sandbox_runtime.dart';
import 'package:omnivium/core/runtime/sandbox/runtime_law.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_guard.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_trace.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_civilization.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/stability/security.dart';

void main() {
  group('ConstitutionalEvolutionEngine — Self-Evolving Constitution', () {
    late ConstitutionalTraceGraph traceGraph;
    late ConstitutionalEvolutionEngine engine;

    setUp(() {
      traceGraph = ConstitutionalTraceGraph();
      engine = ConstitutionalEvolutionEngine(traceGraph);
    });

    test('no loopholes when no violations exist', () {
      final loopholes = engine.scanForLoopholes();
      expect(loopholes, isEmpty);
    });

    test('detects high-frequency law violations as loopholes', () {
      for (var i = 0; i < 10; i++) {
        traceGraph.record(
          sandboxId: 'sb-$i',
          operationType: 'capability',
          violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
          compliant: false,
          escalationBefore: EscalationLevel.warning,
          escalationAfter: EscalationLevel.warning,
          timestamp: 1000 + i,
        );
      }

      final loopholes = engine.scanForLoopholes();

      expect(loopholes.length, 1);
      expect(loopholes[0].affectedLaw, RuntimeLawId.noBypassCapabilityRouter);
      expect(loopholes[0].severity, PolicyLoopholeSeverity.high);
      expect(loopholes[0].occurrenceCount, 10);
      expect(loopholes[0].suggestedFix, isNotEmpty);
    });

    test('detects critical severity for very high violation counts', () {
      for (var i = 0; i < 25; i++) {
        traceGraph.record(
          sandboxId: 'sb-$i',
          operationType: 'task',
          violatedLaw: RuntimeLawId.noBypassScheduler,
          compliant: false,
          escalationBefore: EscalationLevel.warning,
          escalationAfter: EscalationLevel.warning,
          timestamp: 1000 + i,
        );
      }

      final loopholes = engine.scanForLoopholes();

      expect(loopholes.any((l) => l.severity == PolicyLoopholeSeverity.critical), isTrue);
    });

    test('detects systemic low compliance', () {
      for (var i = 0; i < 8; i++) {
        traceGraph.record(
          sandboxId: 'sb-$i',
          operationType: 'capability',
          violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
          compliant: false,
          escalationBefore: EscalationLevel.warning,
          escalationAfter: EscalationLevel.warning,
          timestamp: 1000 + i,
        );
      }
      for (var i = 0; i < 3; i++) {
        traceGraph.record(
          sandboxId: 'sb-ok-$i',
          operationType: 'capability',
          violatedLaw: null,
          compliant: true,
          escalationBefore: EscalationLevel.warning,
          escalationAfter: EscalationLevel.warning,
          timestamp: 2000 + i,
        );
      }

      final loopholes = engine.scanForLoopholes();

      expect(loopholes.any((l) => l.loopholeId == 'systemic-low-compliance'), isTrue);
    });

    test('auto-proposes amendments from critical loopholes', () {
      for (var i = 0; i < 20; i++) {
        traceGraph.record(
          sandboxId: 'sb-$i',
          operationType: 'capability',
          violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
          compliant: false,
          escalationBefore: EscalationLevel.warning,
          escalationAfter: EscalationLevel.warning,
          timestamp: 1000 + i,
        );
      }

      engine.scanForLoopholes();
      final proposals = engine.autoProposeFromLoopholes(3000);

      expect(proposals.length, 1);
      expect(proposals[0].targetLaw, RuntimeLawId.noBypassCapabilityRouter);
      expect(proposals[0].status, ConstitutionalAmendmentStatus.proposed);
    });

    test('manual amendment proposal', () {
      final amendment = engine.proposeAmendment(
        description: 'Add side-channel scanning for all sandbox operations',
        targetLaw: RuntimeLawId.noSideChannels,
        rationale: 'Side-channel violations increasing',
        proposedChange: 'Add mandatory side-channel proof at every state access',
        timestamp: 1000,
      );

      expect(amendment.amendmentId, 'amendment-0');
      expect(amendment.status, ConstitutionalAmendmentStatus.proposed);
      expect(engine.amendments.length, 1);
    });

    test('amendment review — approve', () {
      engine.proposeAmendment(
        description: 'Test',
        targetLaw: RuntimeLawId.noSideChannels,
        rationale: 'Test',
        proposedChange: 'Test',
        timestamp: 1000,
      );

      final reviewed = engine.reviewAmendment('amendment-0', approve: true);

      expect(reviewed.status, ConstitutionalAmendmentStatus.enacted);
      expect(reviewed.enactedAt, isNotNull);
    });

    test('amendment review — reject', () {
      engine.proposeAmendment(
        description: 'Test',
        targetLaw: RuntimeLawId.noSideChannels,
        rationale: 'Test',
        proposedChange: 'Test',
        timestamp: 1000,
      );

      final reviewed = engine.reviewAmendment('amendment-0', approve: false);

      expect(reviewed.status, ConstitutionalAmendmentStatus.rejected);
    });

    test('does not re-detect existing loopholes', () {
      for (var i = 0; i < 10; i++) {
        traceGraph.record(
          sandboxId: 'sb-$i',
          operationType: 'capability',
          violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
          compliant: false,
          escalationBefore: EscalationLevel.warning,
          escalationAfter: EscalationLevel.warning,
          timestamp: 1000 + i,
        );
      }

      engine.scanForLoopholes();
      expect(engine.loopholes.length, 1);

      engine.scanForLoopholes();
      expect(engine.loopholes.length, 1);
    });

    test('suggests specific fixes per law', () {
      for (final law in RuntimeLawId.values) {
        final traceGraph = ConstitutionalTraceGraph();
        final engine = ConstitutionalEvolutionEngine(traceGraph);

        for (var i = 0; i < 10; i++) {
          traceGraph.record(
            sandboxId: 'sb-$i',
            operationType: 'capability',
            violatedLaw: law,
            compliant: false,
            escalationBefore: EscalationLevel.warning,
            escalationAfter: EscalationLevel.warning,
            timestamp: 1000 + i,
          );
        }

        final loopholes = engine.scanForLoopholes();
        if (loopholes.isNotEmpty) {
          expect(loopholes[0].suggestedFix, isNotEmpty);
        }
      }
    });
  });

  group('ReputationEconomy — Trust Economy', () {
    late ReputationEconomy economy;

    setUp(() {
      final traceGraph = ConstitutionalTraceGraph();
      economy = ReputationEconomy(traceGraph);
    });

    test('new entity starts with score 100 and verified trust', () {
      final score = economy.scoreFor('new-plugin');

      expect(score.score, 100.0);
      expect(score.effectiveTrustLevel, TrustLevel.verified);
      expect(score.totalInteractions, 0);
      expect(score.complianceRatio, 1.0);
    });

    test('compliance increases score slightly', () {
      economy.recordCompliance('plugin-1', 1000);
      economy.recordCompliance('plugin-1', 1001);
      economy.recordCompliance('plugin-1', 1002);

      final score = economy.scoreFor('plugin-1');
      expect(score.compliantActions, 3);
      expect(score.complianceRatio, 1.0);
      expect(score.totalInteractions, 3);
    });

    test('violation decreases score significantly', () {
      economy.recordViolation('plugin-1', 1000);

      final score = economy.scoreFor('plugin-1');
      expect(score.score, lessThan(100.0));
      expect(score.violations, 1);
    });

    test('bypass attempt has 3x penalty', () {
      economy.recordViolation('plugin-bypass', 1000, type: SandboxViolationType.bypassAttempt);
      economy.recordViolation('plugin-budget', 1000, type: SandboxViolationType.budgetExceeded);

      final bypassScore = economy.scoreFor('plugin-bypass');
      final budgetScore = economy.scoreFor('plugin-budget');

      expect(bypassScore.score, lessThan(budgetScore.score));
    });

    test('trust level degrades with score', () {
      final entity = 'plugin-degrading';

      for (var i = 0; i < 20; i++) {
        economy.recordViolation(entity, 1000 + i);
      }

      final score = economy.scoreFor(entity);
      expect(score.effectiveTrustLevel.index, greaterThan(TrustLevel.verified.index));
    });

    test('blocked trust level for very low score', () {
      final entity = 'plugin-hostile';

      for (var i = 0; i < 50; i++) {
        economy.recordViolation(entity, 1000 + i, type: SandboxViolationType.bypassAttempt);
      }

      final score = economy.scoreFor(entity);
      expect(score.effectiveTrustLevel, TrustLevel.blocked);
    });

    test('trust decay reduces score over time', () {
      economy.recordCompliance('plugin-1', 1000);
      final before = economy.scoreFor('plugin-1').score;

      economy.applyDecay('plugin-1', 2000);
      final after = economy.scoreFor('plugin-1').score;

      expect(after, lessThan(before));
    });

    test('constitutional score reflects overall system health', () {
      economy.recordCompliance('plugin-good-1', 1000);
      economy.recordCompliance('plugin-good-2', 1000);
      economy.recordViolation('plugin-bad', 1000);

      final score = economy.constitutionalScore();
      expect(score, lessThan(100.0));
      expect(score, greaterThan(0.0));
    });

    test('lowest reputation entities identified', () {
      economy.recordCompliance('plugin-good', 1000);
      for (var i = 0; i < 10; i++) {
        economy.recordViolation('plugin-bad', 1000 + i);
      }

      final lowest = economy.lowestReputationEntities();
      expect(lowest.first, 'plugin-bad');
    });

    test('sync from trace graph', () {
      final traceGraph = ConstitutionalTraceGraph();

      traceGraph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: null, compliant: true, callerId: 'plugin-1', escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 1);
      traceGraph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, callerId: 'plugin-2', escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 2);

      final economy = ReputationEconomy(traceGraph);
      economy.syncFromTraceGraph();

      expect(economy.scoreFor('plugin-1').compliantActions, 1);
      expect(economy.scoreFor('plugin-2').violations, 1);
    });

    test('custom trust decay policy', () {
      final traceGraph = ConstitutionalTraceGraph();
      final economy = ReputationEconomy(traceGraph, policy: const TrustDecayPolicy(
        violationPenalty: 20.0,
        complianceReward: 0.5,
        decayRate: 0.1,
      ));

      economy.recordViolation('plugin-1', 1000);
      expect(economy.scoreFor('plugin-1').score, 80.0);
    });
  });

  group('RuntimeJudiciary — Appeal & Sanctions', () {
    late ConstitutionalTraceGraph traceGraph;
    late ImmutableAuditLedger ledger;
    late RuntimeJudiciary judiciary;

    setUp(() {
      traceGraph = ConstitutionalTraceGraph();
      ledger = ImmutableAuditLedger();
      judiciary = RuntimeJudiciary(traceGraph, ledger);
    });

    test('impose sanction records to ledger', () {
      judiciary.imposeSanction(
        sandboxId: 'sb-1',
        type: SanctionType.warning,
        reason: 'First violation',
        violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
        timestamp: 1000,
      );

      expect(judiciary.sanctions.length, 1);
      expect(judiciary.sanctions[0].isActive, isTrue);
      expect(ledger.length, 1);
      expect(ledger.entries[0].entryType, 'sanction.imposed');
    });

    test('lift reversible sanction', () {
      judiciary.imposeSanction(
        sandboxId: 'sb-1',
        type: SanctionType.warning,
        reason: 'First violation',
        timestamp: 1000,
        isReversible: true,
      );

      final lifted = judiciary.liftSanction('sanction-0', 2000);

      expect(lifted, isNotNull);
      expect(lifted!.isLifted, isTrue);
      expect(lifted.isActive, isFalse);
      expect(ledger.length, 2);
    });

    test('irreversible sanction cannot be lifted', () {
      judiciary.imposeSanction(
        sandboxId: 'sb-1',
        type: SanctionType.termination,
        reason: 'Hostile activity',
        timestamp: 1000,
        isReversible: false,
      );

      final lifted = judiciary.liftSanction('sanction-0', 2000);

      expect(lifted, isNull);
      expect(judiciary.sanctions[0].isActive, isTrue);
    });

    test('file and review appeal — overturned', () {
      judiciary.imposeSanction(
        sandboxId: 'sb-1',
        type: SanctionType.suspension,
        reason: 'Suspicious activity',
        timestamp: 1000,
      );

      judiciary.fileAppeal(
        sandboxId: 'sb-1',
        sanctionId: 'sanction-0',
        grounds: 'False positive — legitimate operation',
        evidence: 'Trace proof shows routed through CapabilityRouter',
        timestamp: 2000,
      );

      final reviewed = judiciary.reviewAppeal('appeal-0', overturn: true);

      expect(reviewed.status, AppealStatus.overturned);
      expect(judiciary.sanctions[0].isLifted, isTrue);
      expect(ledger.length, 3);
    });

    test('file and review appeal — upheld', () {
      judiciary.imposeSanction(
        sandboxId: 'sb-1',
        type: SanctionType.suspension,
        reason: 'Bypass attempt',
        timestamp: 1000,
      );

      judiciary.fileAppeal(
        sandboxId: 'sb-1',
        sanctionId: 'sanction-0',
        grounds: 'Unintentional bypass',
        evidence: 'Code review shows accidental direct call',
        timestamp: 2000,
      );

      final reviewed = judiciary.reviewAppeal('appeal-0', overturn: false);

      expect(reviewed.status, AppealStatus.upheld);
      expect(judiciary.sanctions[0].isActive, isTrue);
    });

    test('partial overturn', () {
      judiciary.imposeSanction(
        sandboxId: 'sb-1',
        type: SanctionType.termination,
        reason: 'Multiple violations',
        timestamp: 1000,
        isReversible: true,
      );

      judiciary.fileAppeal(
        sandboxId: 'sb-1',
        sanctionId: 'sanction-0',
        grounds: 'Partial mitigation possible',
        evidence: 'Some violations were false positives',
        timestamp: 2000,
      );

      final reviewed = judiciary.reviewAppeal('appeal-0', overturn: true, partial: true);

      expect(reviewed.status, AppealStatus.partiallyOverturned);
    });

    test('isSanctioned checks active sanctions', () {
      expect(judiciary.isSanctioned('sb-1'), isFalse);

      judiciary.imposeSanction(
        sandboxId: 'sb-1',
        type: SanctionType.warning,
        reason: 'Test',
        timestamp: 1000,
      );

      expect(judiciary.isSanctioned('sb-1'), isTrue);
    });

    test('highestActiveSanction returns most severe', () {
      judiciary.imposeSanction(sandboxId: 'sb-1', type: SanctionType.warning, reason: 'R1', timestamp: 1000);
      judiciary.imposeSanction(sandboxId: 'sb-1', type: SanctionType.termination, reason: 'R2', timestamp: 1001);

      expect(judiciary.highestActiveSanction('sb-1'), SanctionType.termination);
    });

    test('gatherEvidence collects violations from trace graph', () {
      traceGraph.record(sandboxId: 'sb-1', operationType: 'capability', violatedLaw: RuntimeLawId.noBypassCapabilityRouter, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 1);
      traceGraph.record(sandboxId: 'sb-1', operationType: 'task', violatedLaw: RuntimeLawId.noBypassScheduler, compliant: false, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 2);
      traceGraph.record(sandboxId: 'sb-2', operationType: 'capability', violatedLaw: null, compliant: true, escalationBefore: EscalationLevel.warning, escalationAfter: EscalationLevel.warning, timestamp: 3);

      final evidence = judiciary.gatherEvidence('sb-1');

      expect(evidence.length, 2);
      expect(evidence.every((e) => e.sandboxId == 'sb-1'), isTrue);
    });

    test('sanction JSON serialization', () {
      judiciary.imposeSanction(
        sandboxId: 'sb-1',
        type: SanctionType.suspension,
        reason: 'Test',
        violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
        timestamp: 1000,
      );

      final json = judiciary.sanctions[0].toJson();
      expect(json['type'], 'suspension');
      expect(json['sandbox'], 'sb-1');
      expect(json['law'], 'noBypassCapabilityRouter');
      expect(json['reversible'], isTrue);
    });
  });

  group('ConstitutionalGuard + Civilization Integration', () {
    late ConstitutionalGuard guard;

    setUp(() {
      final clock = HybridLogicalClock(nodeId: 'civ-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      guard = ConstitutionalGuard.withSharedState(
        enforcer: enforcer,
        traceGraph: ConstitutionalTraceGraph(),
        ledger: ImmutableAuditLedger(),
      );
    });

    test('guard exposes evolution engine', () {
      expect(guard.evolutionEngine, isNotNull);
    });

    test('guard exposes reputation economy', () {
      expect(guard.reputationEconomy, isNotNull);
    });

    test('guard exposes judiciary', () {
      expect(guard.judiciary, isNotNull);
    });

    test('violation updates reputation economy', () {
      guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.delete',
        callerId: 'plugin.rogue',
        callerTrust: TrustLevel.untrusted,
        requiredTrust: TrustLevel.system,
        wasRoutedThroughRouter: false,
        hasTraceSpan: true,
      );

      final score = guard.reputationEconomy.scoreFor('sb-1');
      expect(score.violations, greaterThan(0));
      expect(score.score, lessThan(100.0));
    });

    test('compliance updates reputation economy', () {
      guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );

      final score = guard.reputationEconomy.scoreFor('sb-1');
      expect(score.compliantActions, 1);
    });

    test('full civilization loop: violation → detection → escalation → sanction → appeal', () {
      final clock = HybridLogicalClock(nodeId: 'civ-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      final guard = ConstitutionalGuard.withSharedState(
        enforcer: enforcer,
        traceGraph: ConstitutionalTraceGraph(),
        ledger: ImmutableAuditLedger(),
        escalationPolicy: const ViolationEscalationPolicy(
          warningThreshold: 3,
          restrictedThreshold: 20,
          terminationThreshold: 50,
        ),
      );

      for (var i = 0; i < 10; i++) {
        guard.checkCapabilityInvocation(
          sandboxId: 'sb-hostile',
          capabilityId: 'storage.delete',
          callerId: 'plugin.rogue',
          callerTrust: TrustLevel.untrusted,
          requiredTrust: TrustLevel.verified,
          wasRoutedThroughRouter: false,
          hasTraceSpan: true,
        );
      }

      expect(guard.traceGraph.totalDecisions, 10);

      guard.judiciary.imposeSanction(
        sandboxId: 'sb-hostile',
        type: SanctionType.termination,
        reason: 'Constitutional violation escalation',
        violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
        timestamp: 5000,
      );

      expect(guard.judiciary.isSanctioned('sb-hostile'), isTrue);

      guard.judiciary.fileAppeal(
        sandboxId: 'sb-hostile',
        sanctionId: 'sanction-0',
        grounds: 'Testing environment — false positives',
        evidence: 'All violations were in test mode',
        timestamp: 6000,
      );

      guard.judiciary.reviewAppeal('appeal-0', overturn: true);

      expect(guard.judiciary.sanctions[0].isLifted, isTrue);

      final loopholes = guard.evolutionEngine.scanForLoopholes();
      expect(loopholes.length, greaterThanOrEqualTo(1));

      final stats = guard.traceGraph.computeStatistics();
      expect(stats.totalViolations, greaterThanOrEqualTo(5));

      final reputation = guard.reputationEconomy.scoreFor('sb-hostile');
      expect(reputation.violations, greaterThan(0));

      expect(guard.ledger.verifyIntegrity(), isTrue);
    });
  });
}
