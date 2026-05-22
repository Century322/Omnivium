import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/runtime_law.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_guard.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/stability/security.dart';

void main() {
  group('CivilizationTransport �?Runtime Diplomacy', () {
    late CivilizationTransport transportA;
    late CivilizationTransport transportB;

    setUp(() {
      transportA = CivilizationTransport(localNodeId: 'node-A');
      transportB = CivilizationTransport(localNodeId: 'node-B');
    });

    test('send constitution sync message', () {
      final manifest = LawManifest.forNode('node-A', 0);
      final msg = transportA.sendConstitutionSync('node-B', manifest, 1000);

      expect(msg.type, DiplomacyMessageType.constitutionSync);
      expect(msg.senderId, 'node-A');
      expect(msg.targetId, 'node-B');
      expect(msg.payload.containsKey('manifest'), isTrue);
      expect(transportA.outboxCount, 1);
    });

    test('send judiciary broadcast', () {
      final sanction = Sanction(
        sanctionId: 's-0',
        sandboxId: 'sb-1',
        type: SanctionType.termination,
        reason: 'Hostile',
        violatedLaw: RuntimeLawId.noBypassCapabilityRouter,
        imposedAt: 1000,
      );
      final msg = transportA.sendJudiciaryBroadcast('node-B', sanction, 1000);

      expect(msg.type, DiplomacyMessageType.judiciaryBroadcast);
      expect(msg.payload['sandboxId'], 'sb-1');
    });

    test('send reputation exchange', () {
      final passport = TrustPassport(
        entityId: 'plugin-1',
        issuingRuntime: 'node-A',
        reputationScore: 95.0,
        trustLevel: TrustLevel.signed,
        totalInteractions: 100,
        complianceRatio: 0.95,
        issuedAt: 1000,
        expiresAt: 2000,
        signature: 'sig',
      );
      final msg = transportA.sendReputationExchange('node-B', passport, 1000);

      expect(msg.type, DiplomacyMessageType.reputationExchange);
      expect(msg.payload['entityId'], 'plugin-1');
    });

    test('send legislative gossip', () {
      final proposal = LegislativeProposal(
        proposalId: 'leg-0',
        description: 'Test',
        targetLaw: RuntimeLawId.noSideChannels,
        proposedChange: 'Add proof',
        stage: LegislativeStage.proposed,
        rationale: 'Test',
        proposedAt: 1000,
      );
      final msg = transportA.sendLegislativeGossip('node-B', proposal, 1000);

      expect(msg.type, DiplomacyMessageType.legislativeGossip);
      expect(msg.payload['proposalId'], 'leg-0');
    });

    test('send fork negotiation', () {
      final fork = LawFork(
        forkId: 'fork-0',
        lawId: RuntimeLawId.noBypassCapabilityRouter,
        localManifest: LawManifest.forNode('node-A', 0),
        remoteManifest: LawManifest.forNode('node-B', 1),
        resolution: LawForkResolution.conflict,
        detectedAt: 1000,
      );
      final msg = transportA.sendForkNegotiation('node-B', fork, 'adoptRemote', 1000);

      expect(msg.type, DiplomacyMessageType.forkNegotiation);
      expect(msg.payload['proposedResolution'], 'adoptRemote');
    });

    test('send heartbeat', () {
      final msg = transportA.sendHeartbeat('node-B', 5, 1000);

      expect(msg.type, DiplomacyMessageType.heartbeat);
      expect(msg.payload['epoch'], 5);
    });

    test('send identity announce', () {
      final identity = CivilizationIdentity.generate('node-A');
      final msg = transportA.sendIdentityAnnounce('node-B', identity, 1000);

      expect(msg.type, DiplomacyMessageType.identityAnnounce);
      expect(msg.payload['nodeId'], 'node-A');
    });

    test('federation invite and accept', () {
      final invite = transportA.sendFederationInvite('node-B', 'fed-1', 1000);
      expect(invite.type, DiplomacyMessageType.federationInvite);

      final accept = transportB.sendFederationAccept('node-A', 'fed-1', 1001);
      expect(accept.type, DiplomacyMessageType.federationAccept);
    });

    test('open channel between nodes', () {
      final channel = transportA.openChannel('node-B', DiplomacyMessageType.constitutionSync);

      expect(channel.localNodeId, 'node-A');
      expect(channel.remoteNodeId, 'node-B');
      expect(channel.isActive, isTrue);
      expect(transportA.channels.length, 1);
    });

    test('receive message adds to inbox', () {
      final manifest = LawManifest.forNode('node-A', 0);
      final msg = transportA.sendConstitutionSync('node-B', manifest, 1000);

      transportB.receive(msg);

      expect(transportB.inboxCount, 1);
      expect(transportB.inboxOfType(DiplomacyMessageType.constitutionSync).length, 1);
    });

    test('filter inbox by sender', () {
      final manifest = LawManifest.forNode('node-A', 0);
      transportB.receive(transportA.sendConstitutionSync('node-B', manifest, 1000));
      transportB.receive(transportA.sendHeartbeat('node-B', 0, 1001));

      expect(transportB.inboxFrom('node-A').length, 2);
    });

    test('message signature verification', () {
      final msg = transportA.sendHeartbeat('node-B', 0, 1000);
      final expectedSig = DiplomacyMessage.computeSignature('node-A', 'node-B', 1000, msg.payload);
      expect(msg.signature, expectedSig);
    });

    test('clear outbox and inbox', () {
      transportA.sendHeartbeat('node-B', 0, 1000);
      transportB.receive(transportA.sendHeartbeat('node-B', 0, 1001));

      transportA.clearOutbox();
      transportB.clearInbox();

      expect(transportA.outboxCount, 0);
      expect(transportB.inboxCount, 0);
    });
  });

  group('CivilizationIdentity �?Sovereign Runtime Identity', () {
    test('generate creates valid identity', () {
      final identity = CivilizationIdentity.generate('node-A');

      expect(identity.nodeId, 'node-A');
      expect(identity.publicKey, isNotEmpty);
      expect(identity.civilizationEpoch, 0);
      expect(identity.trustLevel, TrustLevel.verified);
      expect(identity.constitutionalAncestry, ['genesis']);
      expect(identity.signature, isNotEmpty);
    });

    test('verify own identity', () {
      final identity = CivilizationIdentity.generate('node-A');
      expect(CivilizationIdentity.verify(identity), isTrue);
    });

    test('tampered identity fails verification', () {
      final identity = CivilizationIdentity.generate('node-A');
      final tampered = CivilizationIdentity(
        nodeId: 'node-A',
        publicKey: identity.publicKey,
        civilizationEpoch: 0,
        trustLevel: TrustLevel.system,
        constitutionalAncestry: ['genesis'],
        createdAt: identity.createdAt,
        signature: 'tampered',
      );

      expect(CivilizationIdentity.verify(tampered), isFalse);
    });

    test('bump epoch increments civilization epoch', () {
      final identity = CivilizationIdentity.generate('node-A');
      final bumped = identity.bumpEpoch();

      expect(bumped.civilizationEpoch, 1);
      expect(bumped.nodeId, identity.nodeId);
    });

    test('join federation', () {
      final identity = CivilizationIdentity.generate('node-A');
      final joined = identity.joinFederation('fed-1');

      expect(joined.federationId, 'fed-1');
    });

    test('update trust level', () {
      final identity = CivilizationIdentity.generate('node-A');
      final updated = identity.updateTrust(TrustLevel.system);

      expect(updated.trustLevel, TrustLevel.system);
    });

    test('identity JSON serialization', () {
      final identity = CivilizationIdentity.generate('node-A');
      final json = identity.toJson();

      expect(json['nodeId'], 'node-A');
      expect(json['publicKey'], isNotEmpty);
      expect(json['epoch'], 0);
      expect(json['trust'], 'verified');
      expect(json['ancestry'], ['genesis']);
    });

    test('different nodes have different public keys', () {
      final idA = CivilizationIdentity.generate('node-A');
      final idB = CivilizationIdentity.generate('node-B');

      expect(idA.publicKey, isNot(equals(idB.publicKey)));
    });
  });

  group('TrustGraph �?Civilization Trust Network', () {
    late TrustGraph graph;

    setUp(() {
      graph = TrustGraph();
    });

    test('add and query trust edge', () {
      graph.addTrustEdge('A', 'B');

      expect(graph.trusts('A', 'B'), isTrue);
      expect(graph.trusts('B', 'A'), isFalse);
    });

    test('remove trust edge', () {
      graph.addTrustEdge('A', 'B');
      graph.removeTrustEdge('A', 'B');

      expect(graph.trusts('A', 'B'), isFalse);
    });

    test('trusted by �?reverse lookup', () {
      graph.addTrustEdge('A', 'C');
      graph.addTrustEdge('B', 'C');

      final trustedBy = graph.trustedBy('C');
      expect(trustedBy, {'A', 'B'});
    });

    test('trusts list �?forward lookup', () {
      graph.addTrustEdge('A', 'B');
      graph.addTrustEdge('A', 'C');

      final trusts = graph.trustsList('A');
      expect(trusts, {'B', 'C'});
    });

    test('trust depth �?direct trust', () {
      graph.addTrustEdge('A', 'B');

      expect(graph.trustDepth('A', 'B'), 1);
    });

    test('trust depth �?transitive trust', () {
      graph.addTrustEdge('A', 'B');
      graph.addTrustEdge('B', 'C');

      expect(graph.trustDepth('A', 'C'), 2);
    });

    test('trust depth �?unreachable', () {
      graph.addTrustEdge('A', 'B');

      expect(graph.trustDepth('A', 'Z'), -1);
    });

    test('is reachable', () {
      graph.addTrustEdge('A', 'B');
      graph.addTrustEdge('B', 'C');
      graph.addTrustEdge('C', 'D');

      expect(graph.isReachable('A', 'D'), isTrue);
      expect(graph.isReachable('D', 'A'), isFalse);
    });

    test('trust depth �?self', () {
      expect(graph.trustDepth('A', 'A'), 0);
    });
  });

  group('FederationMembership �?Federation Governance', () {
    test('create federation with founder', () {
      final fed = FederationMembership.create('fed-1', 'node-A');

      expect(fed.federationId, 'fed-1');
      expect(fed.founder, 'node-A');
      expect(fed.size, 1);
      expect(fed.isMember('node-A'), isTrue);
      expect(fed.memberTrustLevels['node-A'], TrustLevel.system);
    });

    test('add member to federation', () {
      var fed = FederationMembership.create('fed-1', 'node-A');
      fed = fed.addMember('node-B', TrustLevel.verified);

      expect(fed.size, 2);
      expect(fed.isMember('node-B'), isTrue);
    });

    test('remove member from federation', () {
      var fed = FederationMembership.create('fed-1', 'node-A');
      fed = fed.addMember('node-B', TrustLevel.verified);
      fed = fed.removeMember('node-B');

      expect(fed.size, 1);
      expect(fed.isMember('node-B'), isFalse);
    });

    test('JSON serialization', () {
      final fed = FederationMembership.create('fed-1', 'node-A');
      final json = fed.toJson();

      expect(json['id'], 'fed-1');
      expect(json['founder'], 'node-A');
      expect(json['members'], ['node-A']);
    });
  });

  group('ResourceEconomy �?Execution Credits & Taxation', () {
    late ResourceEconomy economy;

    setUp(() {
      economy = ResourceEconomy(taxRate: 0.1, executionCreditRate: 1.0);
    });

    test('new entity starts with 100 credits', () {
      final account = economy.accountFor('plugin-1');
      expect(account.balance, 100.0);
    });

    test('earn credits with tax deduction', () {
      final account = economy.earn('plugin-1', 100.0, 1000);

      expect(account.earnedTotal, 200.0);
      expect(account.balance, closeTo(190.0, 0.01));
      expect(account.taxPaid, closeTo(10.0, 0.01));
      expect(economy.treasury.balance, closeTo(10.0, 0.01));
    });

    test('spend credits', () {
      economy.earn('plugin-1', 1000.0, 1000);
      final account = economy.spend('plugin-1', 50.0, 2000);

      expect(account, isNotNull);
      expect(account!.balance, lessThanOrEqualTo(950.0));
      expect(account.spentTotal, 50.0);
    });

    test('cannot spend more than balance', () {
      final account = economy.spend('plugin-1', 200.0, 1000);
      expect(account, isNull);
    });

    test('execution cost calculation', () {
      final cost = economy.executionCost(100, 5, 2);
      expect(cost, greaterThan(0));
      expect(cost, 100 * 0.01 + 5 * 1.0 + 2 * 0.5);
    });

    test('can afford check', () {
      expect(economy.canAfford('plugin-1', 10, 1, 1), isTrue);
      expect(economy.canAfford('plugin-1', 10000, 10000, 10000), isFalse);
    });

    test('charge execution', () {
      economy.earn('plugin-1', 1000.0, 1000);
      final account = economy.chargeExecution('plugin-1', 100, 5, 2, 2000);

      expect(account, isNotNull);
    });

    test('impose penalty', () {
      economy.earn('plugin-1', 1000.0, 1000);
      economy.imposePenalty('plugin-1', 50.0, 'constitutional_violation', 2000);

      final account = economy.accountFor('plugin-1');
      expect(account.spentTotal, greaterThan(0));
      expect(economy.treasury.balance, greaterThan(0));
    });

    test('treasury tracks tax collection', () {
      economy.earn('plugin-1', 100.0, 1000);
      economy.earn('plugin-2', 200.0, 1001);

      expect(economy.treasury.taxCollected['plugin-1'], closeTo(10.0, 0.01));
      expect(economy.treasury.taxCollected['plugin-2'], closeTo(20.0, 0.01));
    });

    test('treasury distributes funds', () {
      economy.earn('plugin-1', 1000.0, 1000);
      economy.treasury.distribute('plugin-2', 5.0, 'reward', 2000);

      expect(economy.treasury.balance, lessThan(100.0));
    });

    test('execution credits JSON serialization', () {
      economy.earn('plugin-1', 100.0, 1000);
      final json = economy.accountFor('plugin-1').toJson();

      expect(json['entity'], 'plugin-1');
      expect(json.containsKey('balance'), isTrue);
      expect(json.containsKey('earned'), isTrue);
    });
  });

  group('ConstitutionalGuard + Civilization Layer Integration', () {
    test('guard with nodeId exposes transport, identity, economy', () {
      final clock = HybridLogicalClock(nodeId: 'civ-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);

      final guard = ConstitutionalGuard(enforcer: enforcer, nodeId: 'node-A');

      expect(guard.transport, isNotNull);
      expect(guard.identity, isNotNull);
      expect(guard.economy, isNotNull);
      expect(guard.identity!.nodeId, 'node-A');
    });

    test('guard without nodeId has null civilization layer', () {
      final clock = HybridLogicalClock(nodeId: 'basic-test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);

      final guard = ConstitutionalGuard(enforcer: enforcer);

      expect(guard.transport, isNull);
      expect(guard.identity, isNull);
      expect(guard.economy, isNull);
    });

    test('full civilization stack: guard + transport + identity + economy', () {
      final clock = HybridLogicalClock(nodeId: 'full-stack');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);

      final guard = ConstitutionalGuard(enforcer: enforcer, nodeId: 'node-A');

      guard.checkCapabilityInvocation(
        sandboxId: 'sb-1',
        capabilityId: 'storage.read',
        callerId: 'plugin.main',
        callerTrust: TrustLevel.verified,
        requiredTrust: TrustLevel.verified,
        wasRoutedThroughRouter: true,
        hasTraceSpan: true,
      );

      expect(guard.traceGraph.totalDecisions, 1);
      expect(guard.ledger.verifyIntegrity(), isTrue);

      final manifest = LawManifest.forNode('node-A', 0);
      guard.transport!.sendConstitutionSync('node-B', manifest, 1000);
      expect(guard.transport!.outboxCount, 1);

      expect(CivilizationIdentity.verify(guard.identity!), isTrue);

      guard.economy!.earn('plugin.main', 100.0, 1000);
      expect(guard.economy!.accountFor('plugin.main').earnedTotal, 200.0);
    });
  });
}
