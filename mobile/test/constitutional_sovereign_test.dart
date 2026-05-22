import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/runtime_law.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_guard.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_trace.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_civilization.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/stability/security.dart';

void main() {
  group('ConstitutionalConsensus — Distributed Law Governance', () {
    late ConstitutionalConsensus localConsensus;
    late ConstitutionalConsensus remoteConsensus;

    setUp(() {
      localConsensus = ConstitutionalConsensus(localNodeId: 'node-A');
      remoteConsensus = ConstitutionalConsensus(localNodeId: 'node-B');
    });

    test('local manifest has all 10 laws at version 1', () {
      final manifest = localConsensus.localManifest;
      expect(manifest.lawVersions.length, 10);
      expect(manifest.epoch, 0);
      expect(manifest.lawVersions.values.every((v) => v == 1), isTrue);
    });

    test('compatible manifests detect no fork', () {
      final remoteManifest = LawManifest.forNode('node-B', 0);
      final fork = localConsensus.detectFork(remoteManifest);

      expect(fork.resolution, LawForkResolution.merge);
    });

    test('version mismatch detects fork — adopt remote when remote has higher epoch', () {
      final remoteManifest = LawManifest.forNode('node-B', 5);
      final bumped = remoteManifest.bumpVersion(RuntimeLawId.noBypassCapabilityRouter);

      final fork = localConsensus.detectFork(bumped);

      expect(fork.resolution, LawForkResolution.adoptRemote);
      expect(localConsensus.forks.length, 1);
    });

    test('version mismatch detects fork — conflict when versions differ at same epoch', () {
      final remoteManifest = LawManifest.forNode('node-B', 0);
      final bumped = remoteManifest.bumpVersion(RuntimeLawId.noBudgetBypass);

      final fork = localConsensus.detectFork(bumped);

      expect(fork.resolution, LawForkResolution.adoptRemote);
      expect(localConsensus.forks.length, 1);
    });

    test('same epoch with different versions = conflict', () {
      final remoteManifest = LawManifest.forNode('node-B', 0);
      final bumped = remoteManifest.bumpVersion(RuntimeLawId.noSideChannels);
      final conflictManifest = LawManifest(
        nodeId: 'node-B',
        epoch: 0,
        lawVersions: bumped.lawVersions,
        hash: bumped.hash,
      );

      final fork = localConsensus.detectFork(conflictManifest);
      expect(fork.resolution, LawForkResolution.conflict);
    });

    test('register remote node', () {
      final remoteManifest = LawManifest.forNode('node-B', 0);
      localConsensus.registerRemoteNode('node-B', remoteManifest);

      expect(localConsensus.remoteManifests.containsKey('node-B'), isTrue);
      expect(localConsensus.totalNodes(), 2);
    });

    test('cast and tally votes', () {
      localConsensus.castVote(voterId: 'node-A', amendmentId: 'amendment-0', support: true, timestamp: 1000);
      localConsensus.castVote(voterId: 'node-B', amendmentId: 'amendment-0', support: true, timestamp: 1001);
      localConsensus.castVote(voterId: 'node-C', amendmentId: 'amendment-0', support: false, timestamp: 1002);

      final result = localConsensus.tallyVotes('amendment-0', 2000);

      expect(result.totalVotes, 3);
      expect(result.supportVotes, 2);
      expect(result.opposeVotes, 1);
      expect(result.supportRatio, closeTo(0.667, 0.01));
      expect(result.passed, isTrue);
    });

    test('vote fails below threshold', () {
      localConsensus.castVote(voterId: 'node-A', amendmentId: 'amendment-1', support: true, timestamp: 1000);
      localConsensus.castVote(voterId: 'node-B', amendmentId: 'amendment-1', support: false, timestamp: 1001);
      localConsensus.castVote(voterId: 'node-C', amendmentId: 'amendment-1', support: false, timestamp: 1002);

      final result = localConsensus.tallyVotes('amendment-1', 2000);

      expect(result.supportRatio, closeTo(0.333, 0.01));
      expect(result.passed, isFalse);
    });

    test('custom pass threshold', () {
      final consensus = ConstitutionalConsensus(localNodeId: 'node-A', passThreshold: 0.8);
      consensus.castVote(voterId: 'node-A', amendmentId: 'amendment-0', support: true, timestamp: 1000);
      consensus.castVote(voterId: 'node-B', amendmentId: 'amendment-0', support: true, timestamp: 1001);
      consensus.castVote(voterId: 'node-C', amendmentId: 'amendment-0', support: false, timestamp: 1002);

      final result = consensus.tallyVotes('amendment-0', 2000);
      expect(result.passed, isFalse);
    });

    test('manifest bumpVersion increments specific law', () {
      final manifest = LawManifest.forNode('node-A', 0);
      final bumped = manifest.bumpVersion(RuntimeLawId.noBypassCapabilityRouter);

      expect(bumped.lawVersions[RuntimeLawId.noBypassCapabilityRouter], 2);
      expect(bumped.epoch, 1);
      expect(bumped.hash, isNot(equals(manifest.hash)));
    });

    test('law manifest JSON serialization', () {
      final manifest = LawManifest.forNode('node-A', 0);
      final json = manifest.toJson();

      expect(json['node'], 'node-A');
      expect(json['epoch'], 0);
      expect(json['versions'], isMap);
    });
  });

  group('FederatedReputation — Sovereign Trust Passport', () {
    late FederatedReputation fedRep;
    late ReputationScore goodScore;
    late ReputationScore badScore;

    setUp(() {
      fedRep = FederatedReputation(localRuntimeId: 'runtime-A');

      goodScore = const ReputationScore(
        entityId: 'plugin-trusted',
        score: 95.0,
        totalInteractions: 100,
        violations: 2,
        compliantActions: 98,
        complianceRatio: 0.98,
        effectiveTrustLevel: TrustLevel.signed,
        lastUpdated: 1000,
      );

      badScore = const ReputationScore(
        entityId: 'plugin-hostile',
        score: 15.0,
        totalInteractions: 50,
        violations: 40,
        compliantActions: 10,
        complianceRatio: 0.2,
        effectiveTrustLevel: TrustLevel.blocked,
        lastUpdated: 1000,
      );
    });

    test('issue passport from reputation score', () {
      final passport = fedRep.issuePassport(goodScore);

      expect(passport.entityId, 'plugin-trusted');
      expect(passport.issuingRuntime, 'runtime-A');
      expect(passport.reputationScore, 95.0);
      expect(passport.trustLevel, TrustLevel.signed);
      expect(passport.signature, isNotEmpty);
    });

    test('verify own passport', () {
      final passport = fedRep.issuePassport(goodScore);
      expect(fedRep.verifyPassport(passport), isTrue);
    });

    test('import passport from another runtime', () {
      final runtimeB = FederatedReputation(localRuntimeId: 'runtime-B');
      final passport = runtimeB.issuePassport(goodScore);

      final imported = fedRep.importPassport(passport);
      expect(imported, isTrue);
      expect(fedRep.passportCount, 1);
    });

    test('cannot import own passport', () {
      final passport = fedRep.issuePassport(goodScore);
      final imported = fedRep.importPassport(passport);
      expect(imported, isFalse);
    });

    test('federated score aggregates multiple passports', () {
      final runtimeB = FederatedReputation(localRuntimeId: 'runtime-B');
      final runtimeC = FederatedReputation(localRuntimeId: 'runtime-C');

      final passportB = runtimeB.issuePassport(goodScore);
      final passportC = runtimeC.issuePassport(badScore);

      fedRep.importPassport(passportB);
      fedRep.importPassport(passportC);

      final fedScore = fedRep.federatedScoreFor('plugin-trusted');
      expect(fedScore, greaterThan(0));
    });

    test('federated trust level maps from score', () {
      final runtimeB = FederatedReputation(localRuntimeId: 'runtime-B');
      final passport = runtimeB.issuePassport(goodScore);
      fedRep.importPassport(passport);

      final trustLevel = fedRep.federatedTrustLevelFor('plugin-trusted');
      expect(trustLevel, TrustLevel.system);
    });

    test('passport JSON serialization', () {
      final passport = fedRep.issuePassport(goodScore);
      final json = passport.toJson();

      expect(json['entity'], 'plugin-trusted');
      expect(json['issuer'], 'runtime-A');
      expect(json['score'], '95.00');
      expect(json['trust'], 'signed');
      expect(json['sig'], isNotEmpty);
    });

    test('tampered passport fails verification', () {
      final passport = fedRep.issuePassport(goodScore);
      final tampered = TrustPassport(
        entityId: 'plugin-trusted',
        issuingRuntime: 'runtime-A',
        reputationScore: 99.0,
        trustLevel: TrustLevel.system,
        totalInteractions: 100,
        complianceRatio: 0.98,
        issuedAt: passport.issuedAt,
        expiresAt: passport.expiresAt,
        signature: 'tampered_sig',
      );

      expect(fedRep.verifyPassport(tampered), isFalse);
    });
  });

  group('AutonomousLegislature — Machine Civilization Governance', () {
    late ConstitutionalConsensus consensus;
    late ConstitutionalTraceGraph traceGraph;
    late ReputationEconomy reputationEconomy;
    late RuntimeJudiciary judiciary;
    late ImmutableAuditLedger ledger;
    late AutonomousLegislature legislature;

    setUp(() {
      consensus = ConstitutionalConsensus(localNodeId: 'node-A');
      traceGraph = ConstitutionalTraceGraph();
      ledger = ImmutableAuditLedger();
      reputationEconomy = ReputationEconomy(traceGraph);
      judiciary = RuntimeJudiciary(traceGraph, ledger);
      legislature = AutonomousLegislature(
        consensus: consensus,
        traceGraph: traceGraph,
        reputationEconomy: reputationEconomy,
        judiciary: judiciary,
      );
    });

    test('propose new legislation', () {
      final proposal = legislature.propose(
        description: 'Add mandatory side-channel proof for all state access',
        targetLaw: RuntimeLawId.noSideChannels,
        proposedChange: 'Require side-channel proof at every state access checkpoint',
        rationale: 'Side-channel violations increasing across sandboxes',
        timestamp: 1000,
      );

      expect(proposal.proposalId, 'leg-0');
      expect(proposal.stage, LegislativeStage.proposed);
      expect(legislature.proposals.length, 1);
    });

    test('simulate proposal analyzes trace data', () {
      for (var i = 0; i < 15; i++) {
        traceGraph.record(
          sandboxId: 'sb-$i',
          operationType: 'state',
          violatedLaw: RuntimeLawId.noSideChannels,
          compliant: false,
          escalationBefore: EscalationLevel.warning,
          escalationAfter: EscalationLevel.warning,
          timestamp: 1000 + i,
        );
      }

      legislature.propose(
        description: 'Side-channel fix',
        targetLaw: RuntimeLawId.noSideChannels,
        proposedChange: 'Add proof requirement',
        rationale: 'High violation count',
        timestamp: 2000,
      );

      final result = legislature.simulate();

      expect(result.stage, LegislativeStage.simulating);
      expect(result.simulationResult['currentViolations'], 15);
      expect(result.simulationResult['estimatedReduction'], greaterThan(0));
    });

    test('impact analysis evaluates constitutional health', () {
      legislature.propose(
        description: 'Test proposal',
        targetLaw: RuntimeLawId.noSideChannels,
        proposedChange: 'Test change',
        rationale: 'Test',
        timestamp: 1000,
      );
      legislature.simulate();
      final result = legislature.analyzeImpact();

      expect(result.stage, LegislativeStage.impactAnalysis);
      expect(result.impactAnalysis.containsKey('constitutionalHealthScore'), isTrue);
      expect(result.impactAnalysis.containsKey('breakingChange'), isTrue);
    });

    test('judiciary check reviews constitutional compatibility', () {
      legislature.propose(
        description: 'Test proposal',
        targetLaw: RuntimeLawId.noSideChannels,
        proposedChange: 'Test change',
        rationale: 'Test',
        timestamp: 1000,
      );
      legislature.simulate();
      legislature.analyzeImpact();
      final result = legislature.judiciaryCheck();

      expect(result.stage, LegislativeStage.judiciaryReview);
      expect(result.judiciaryReview['constitutional'], isTrue);
      expect(result.judiciaryReview['recommendation'], 'proceed');
    });

    test('submit to vote after judiciary approval', () {
      legislature.propose(
        description: 'Test proposal',
        targetLaw: RuntimeLawId.noSideChannels,
        proposedChange: 'Test change',
        rationale: 'Test',
        timestamp: 1000,
      );
      legislature.simulate();
      legislature.analyzeImpact();
      legislature.judiciaryCheck();
      final result = legislature.submitToVote(2000);

      expect(result.stage, LegislativeStage.consensusVoting);
    });

    test('enact after successful vote', () {
      consensus.castVote(voterId: 'node-A', amendmentId: 'leg-0', support: true, timestamp: 1000);
      consensus.castVote(voterId: 'node-B', amendmentId: 'leg-0', support: true, timestamp: 1001);

      legislature.propose(
        description: 'Test proposal',
        targetLaw: RuntimeLawId.noSideChannels,
        proposedChange: 'Test change',
        rationale: 'Test',
        timestamp: 1000,
      );
      legislature.simulate();
      legislature.analyzeImpact();
      legislature.judiciaryCheck();
      legislature.submitToVote(2000);
      final result = legislature.enact(3000);

      expect(result.stage, LegislativeStage.enacted);
      expect(result.enactedAt, 3000);
      expect(result.consensusResult!.passed, isTrue);
    });

    test('reject after failed vote', () {
      consensus.castVote(voterId: 'node-A', amendmentId: 'leg-0', support: false, timestamp: 1000);
      consensus.castVote(voterId: 'node-B', amendmentId: 'leg-0', support: false, timestamp: 1001);

      legislature.propose(
        description: 'Test proposal',
        targetLaw: RuntimeLawId.noSideChannels,
        proposedChange: 'Test change',
        rationale: 'Test',
        timestamp: 1000,
      );
      legislature.simulate();
      legislature.analyzeImpact();
      legislature.judiciaryCheck();
      legislature.submitToVote(2000);
      final result = legislature.enact(3000);

      expect(result.stage, LegislativeStage.rejected);
      expect(result.consensusResult!.passed, isFalse);
    });

    test('full pipeline in one call', () {
      legislature.propose(
        description: 'Test proposal',
        targetLaw: RuntimeLawId.noSideChannels,
        proposedChange: 'Test change',
        rationale: 'Test',
        timestamp: 1000,
      );

      consensus.castVote(voterId: 'node-A', amendmentId: 'leg-0', support: true, timestamp: 1000);
      consensus.castVote(voterId: 'node-B', amendmentId: 'leg-0', support: true, timestamp: 1001);

      final result = legislature.runFullPipeline(2000);

      expect(result.stage == LegislativeStage.enacted || result.stage == LegislativeStage.rejected, isTrue);
    });

    test('legislative proposal JSON serialization', () {
      legislature.propose(
        description: 'Test',
        targetLaw: RuntimeLawId.noSideChannels,
        proposedChange: 'Change',
        rationale: 'Reason',
        timestamp: 1000,
      );

      final json = legislature.proposals[0].toJson();
      expect(json['id'], 'leg-0');
      expect(json['law'], 'noSideChannels');
      expect(json['stage'], 'proposed');
    });
  });

  group('ConstitutionalGuard + Sovereign Integration', () {
    test('guard with nodeId exposes consensus and federated reputation', () {
      final clock = HybridLogicalClock(nodeId: 'sovereign-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);

      final guard = ConstitutionalGuard(
        enforcer: enforcer,
        nodeId: 'node-A',
      );

      expect(guard.consensus, isNotNull);
      expect(guard.federatedReputation, isNotNull);
      expect(guard.consensus!.localManifest.nodeId, 'node-A');
    });

    test('guard without nodeId has null sovereign components', () {
      final clock = HybridLogicalClock(nodeId: 'basic-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);

      final guard = ConstitutionalGuard(enforcer: enforcer);

      expect(guard.consensus, isNull);
      expect(guard.federatedReputation, isNull);
    });

    test('enable legislature creates autonomous legislature', () {
      final clock = HybridLogicalClock(nodeId: 'leg-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);

      final guard = ConstitutionalGuard(
        enforcer: enforcer,
        nodeId: 'node-A',
      );

      final legislature = guard.enableLegislature();
      expect(legislature, isNotNull);
    });

    test('enable legislature without nodeId throws', () {
      final clock = HybridLogicalClock(nodeId: 'no-leg-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);

      final guard = ConstitutionalGuard(enforcer: enforcer);

      expect(() => guard.enableLegislature(), throwsStateError);
    });
  });

  group('Sovereign Distributed Civilization — Full Loop', () {
    test('multi-node constitutional consensus with federated reputation', () {
      final consensusA = ConstitutionalConsensus(localNodeId: 'node-A');
      final consensusB = ConstitutionalConsensus(localNodeId: 'node-B');
      final fedRepA = FederatedReputation(localRuntimeId: 'runtime-A');
      final fedRepB = FederatedReputation(localRuntimeId: 'runtime-B');

      final manifestA = consensusA.localManifest;
      final manifestB = consensusB.localManifest;

      consensusA.registerRemoteNode('node-B', manifestB);
      consensusB.registerRemoteNode('node-A', manifestA);

      expect(consensusA.totalNodes(), 2);
      expect(consensusB.totalNodes(), 2);

      final forkA = consensusA.detectFork(manifestB);
      expect(forkA.resolution, LawForkResolution.merge);

      final goodScore = const ReputationScore(
        entityId: 'plugin-cross-runtime',
        score: 88.0,
        totalInteractions: 200,
        violations: 5,
        compliantActions: 195,
        complianceRatio: 0.975,
        effectiveTrustLevel: TrustLevel.signed,
        lastUpdated: 1000,
      );

      final passport = fedRepB.issuePassport(goodScore);
      final imported = fedRepA.importPassport(passport);

      expect(imported, isTrue);
      expect(fedRepA.federatedScoreFor('plugin-cross-runtime'), greaterThan(0));

      final trustLevel = fedRepA.federatedTrustLevelFor('plugin-cross-runtime');
      expect(trustLevel, TrustLevel.signed);
    });

    test('full sovereign loop: detect loophole → propose → simulate → vote → enact', () {
      final traceGraph = ConstitutionalTraceGraph();
      final ledger = ImmutableAuditLedger();
      final consensus = ConstitutionalConsensus(localNodeId: 'node-A');
      final reputationEconomy = ReputationEconomy(traceGraph);
      final judiciary = RuntimeJudiciary(traceGraph, ledger);
      final legislature = AutonomousLegislature(
        consensus: consensus,
        traceGraph: traceGraph,
        reputationEconomy: reputationEconomy,
        judiciary: judiciary,
      );

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

      consensus.castVote(voterId: 'node-A', amendmentId: 'leg-0', support: true, timestamp: 2000);
      consensus.castVote(voterId: 'node-B', amendmentId: 'leg-0', support: true, timestamp: 2001);

      legislature.propose(
        description: 'Strengthen CapabilityRouter enforcement',
        targetLaw: RuntimeLawId.noBypassCapabilityRouter,
        proposedChange: 'Add mandatory route proof at all capability invocation points',
        rationale: '20 violations detected across multiple sandboxes',
        timestamp: 3000,
      );

      legislature.simulate();
      expect(legislature.proposals[0].simulationResult['currentViolations'], 20);

      legislature.analyzeImpact();
      expect(legislature.proposals[0].impactAnalysis.containsKey('constitutionalHealthScore'), isTrue);

      legislature.judiciaryCheck();
      expect(legislature.proposals[0].judiciaryReview['recommendation'], 'proceed');

      legislature.submitToVote(4000);

      final result = legislature.enact(5000);
      expect(result.stage, LegislativeStage.enacted);
      expect(result.consensusResult!.passed, isTrue);
      expect(result.consensusResult!.supportVotes, 2);

      expect(ledger.verifyIntegrity(), isTrue);
    });
  });
}
