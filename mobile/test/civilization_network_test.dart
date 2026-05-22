import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/runtime_law.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_guard.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_trace.dart';
import 'package:omnivium/core/runtime/sandbox/constitutional_civilization.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/stability/security.dart';

void main() {
  group('WireMessage — Network Wire Protocol', () {
    test('toJson and fromJson round-trip', () {
      final msg = WireMessage(
        type: WireMessageType.constitutionSync,
        senderId: 'node-A',
        targetId: 'node-B',
        sequenceNumber: 1,
        epoch: 5,
        payload: {'lawCount': 10},
        timestamp: 1000,
        messageId: 'node-A_1',
        signature: 'wire_abcd1234',
      );
      final json = msg.toJson();
      final restored = WireMessage.fromJson(json);

      expect(restored.type, WireMessageType.constitutionSync);
      expect(restored.senderId, 'node-A');
      expect(restored.targetId, 'node-B');
      expect(restored.sequenceNumber, 1);
      expect(restored.epoch, 5);
      expect(restored.timestamp, 1000);
      expect(restored.messageId, 'node-A_1');
      expect(restored.signature, 'wire_abcd1234');
    });

    test('computeSignature is deterministic', () {
      final sig1 = WireMessage.computeSignature('A', 'B', 1000, 1, {'key': 'val'});
      final sig2 = WireMessage.computeSignature('A', 'B', 1000, 1, {'key': 'val'});
      expect(sig1, sig2);
    });

    test('computeSignature differs for different inputs', () {
      final sig1 = WireMessage.computeSignature('A', 'B', 1000, 1, {'key': 'val1'});
      final sig2 = WireMessage.computeSignature('A', 'B', 1000, 1, {'key': 'val2'});
      expect(sig1, isNot(equals(sig2)));
    });

    test('all WireMessageType values are distinct', () {
      final names = WireMessageType.values.map((t) => t.name).toList();
      expect(names.toSet().length, names.length);
    });
  });

  group('GossipProtocol — Legislative Gossip Propagation', () {
    late GossipProtocol gossip;

    setUp(() {
      gossip = GossipProtocol(localNodeId: 'node-A', fanout: 2);
    });

    test('gossip relays to fanout peers', () {
      final msg = WireMessage(
        type: WireMessageType.legislativeGossip,
        senderId: 'node-B',
        targetId: 'node-A',
        sequenceNumber: 1,
        epoch: 0,
        payload: {'proposalId': 'leg-0'},
        timestamp: 1000,
        messageId: 'msg-1',
        signature: 'sig-1',
      );
      final relayed = gossip.gossip(msg, ['node-B', 'node-C', 'node-D', 'node-E']);
      expect(relayed.length, 2);
      expect(relayed.every((r) => r.senderId == 'node-A'), isTrue);
      expect(relayed.every((r) => r.type == WireMessageType.legislativeGossip), isTrue);
    });

    test('gossip does not relay to sender or self', () {
      final msg = WireMessage(
        type: WireMessageType.legislativeGossip,
        senderId: 'node-B',
        targetId: 'node-A',
        sequenceNumber: 1,
        epoch: 0,
        payload: {},
        timestamp: 1000,
        messageId: 'msg-1',
        signature: 'sig-1',
      );
      final relayed = gossip.gossip(msg, ['node-A', 'node-B', 'node-C']);
      expect(relayed.any((r) => r.targetId == 'node-A'), isFalse);
      expect(relayed.any((r) => r.targetId == 'node-B'), isFalse);
    });

    test('gossip deduplicates seen messages', () {
      final msg = WireMessage(
        type: WireMessageType.legislativeGossip,
        senderId: 'node-B',
        targetId: 'node-A',
        sequenceNumber: 1,
        epoch: 0,
        payload: {},
        timestamp: 1000,
        messageId: 'msg-1',
        signature: 'sig-1',
      );
      gossip.gossip(msg, ['node-C', 'node-D']);
      final second = gossip.gossip(msg, ['node-C', 'node-D']);
      expect(second, isEmpty);
    });

    test('drainPending returns and clears pending messages', () {
      final msg = WireMessage(
        type: WireMessageType.judiciaryBroadcast,
        senderId: 'node-B',
        targetId: 'node-A',
        sequenceNumber: 1,
        epoch: 0,
        payload: {},
        timestamp: 1000,
        messageId: 'msg-1',
        signature: 'sig-1',
      );
      gossip.gossip(msg, ['node-C', 'node-D']);
      expect(gossip.pendingCount, 2);
      final pending = gossip.drainPending();
      expect(pending.length, 2);
      expect(gossip.pendingCount, 0);
    });

    test('prune removes old entries', () {
      final msg = WireMessage(
        type: WireMessageType.heartbeat,
        senderId: 'node-B',
        targetId: 'node-A',
        sequenceNumber: 1,
        epoch: 0,
        payload: {},
        timestamp: 1000,
        messageId: 'msg-1',
        signature: 'sig-1',
      );
      gossip.gossip(msg, ['node-C']);
      expect(gossip.hasSeen('msg-1'), isTrue);
      gossip.prune(2000);
      expect(gossip.hasSeen('msg-1'), isFalse);
    });

    test('propagationCounts tracks gossip spread', () {
      final msg = WireMessage(
        type: WireMessageType.legislativeGossip,
        senderId: 'node-B',
        targetId: 'node-A',
        sequenceNumber: 1,
        epoch: 0,
        payload: {},
        timestamp: 1000,
        messageId: 'msg-1',
        signature: 'sig-1',
      );
      gossip.gossip(msg, ['node-C', 'node-D', 'node-E']);
      expect(gossip.propagationCounts['msg-1'], 2);
    });
  });

  group('ConstitutionalReplication — Law Manifest Sync', () {
    late ConstitutionalReplication repl;

    setUp(() {
      repl = ConstitutionalReplication(localNodeId: 'node-A', initialEpoch: 0);
    });

    test('replicateFrom stores remote manifest', () {
      final remote = LawManifest.forNode('node-B', 3);
      final result = repl.replicateFrom('node-B', remote, 1000);
      expect(result.replicated, isTrue);
      expect(result.forkDetected, isFalse);
      expect(repl.replicatedManifests.containsKey('node-B'), isTrue);
    });

    test('replicateFrom detects fork on version mismatch', () {
      final remote = LawManifest.forNode('node-B', 0).bumpVersion(RuntimeLawId.noBypassCapabilityRouter);
      final result = repl.replicateFrom('node-B', remote, 1000);
      expect(result.forkDetected, isTrue);
      expect(result.fork, isNotNull);
      expect(result.fork!.resolution, LawForkResolution.adoptRemote);
    });

    test('replicateFrom detects conflict on same epoch different versions', () {
      final remote = LawManifest.forNode('node-B', 0).bumpVersion(RuntimeLawId.noBypassScheduler);
      final result = repl.replicateFrom('node-B', remote, 1000);
      expect(result.forkDetected, isTrue);
    });

    test('replicationLag tracks epoch difference', () {
      repl.replicateFrom('node-B', LawManifest.forNode('node-B', 2), 1000);
      repl.replicateFrom('node-B', LawManifest.forNode('node-B', 5), 2000);
      expect(repl.replicationLagFor('node-B'), 3);
    });

    test('maxReplicationLag returns highest lag', () {
      repl.replicateFrom('node-B', LawManifest.forNode('node-B', 0), 1000);
      repl.replicateFrom('node-C', LawManifest.forNode('node-C', 0), 1000);
      repl.replicateFrom('node-B', LawManifest.forNode('node-B', 3), 2000);
      repl.replicateFrom('node-C', LawManifest.forNode('node-C', 7), 2000);
      expect(repl.maxReplicationLag(), 7);
    });

    test('replicationLog records entries', () {
      repl.replicateFrom('node-B', LawManifest.forNode('node-B', 0), 1000);
      expect(repl.replicationLog.length, 1);
      expect(repl.replicationLog.first.remoteNodeId, 'node-B');
    });
  });

  group('ByzantineDetector — Byzantine Fault Detection', () {
    late ByzantineDetector detector;

    setUp(() {
      detector = ByzantineDetector(localNodeId: 'node-A', accusationThreshold: 3);
    });

    test('no accusation below threshold', () {
      detector.reportInconsistentMessage('node-B', 'msg-1', 1000);
      detector.reportInconsistentMessage('node-B', 'msg-2', 1001);
      expect(detector.verdictFor('node-B'), ByzantineVerdict.trusted);
      expect(detector.accusations, isEmpty);
    });

    test('accusation at threshold', () {
      detector.reportInconsistentMessage('node-B', 'msg-1', 1000);
      detector.reportInconsistentMessage('node-B', 'msg-2', 1001);
      detector.reportInconsistentMessage('node-B', 'msg-3', 1002);
      expect(detector.verdictFor('node-B'), ByzantineVerdict.suspected);
      expect(detector.accusations.length, 1);
      expect(detector.accusations.first.accusedNodeId, 'node-B');
    });

    test('missing heartbeat contributes to evidence', () {
      detector.reportMissingHeartbeat('node-C', 1000);
      detector.reportMissingHeartbeat('node-C', 2000);
      detector.reportMissingHeartbeat('node-C', 3000);
      expect(detector.verdictFor('node-C'), ByzantineVerdict.suspected);
    });

    test('mixed evidence types accumulate', () {
      detector.reportInconsistentMessage('node-D', 'msg-1', 1000);
      detector.reportMissingHeartbeat('node-D', 2000);
      detector.reportConflictingVote('node-D', 'amend-1', 3000);
      expect(detector.verdictFor('node-D'), ByzantineVerdict.suspected);
    });

    test('confirmByzantine sets verdict to confirmed', () {
      detector.reportInconsistentMessage('node-E', 'msg-1', 1000);
      detector.reportInconsistentMessage('node-E', 'msg-2', 1001);
      detector.reportInconsistentMessage('node-E', 'msg-3', 1002);
      detector.confirmByzantine('node-E', 2000);
      expect(detector.isByzantine('node-E'), isTrue);
      expect(detector.verdictFor('node-E'), ByzantineVerdict.confirmed);
    });

    test('exonerate clears evidence and resets verdict', () {
      detector.reportInconsistentMessage('node-F', 'msg-1', 1000);
      detector.reportInconsistentMessage('node-F', 'msg-2', 1001);
      detector.reportInconsistentMessage('node-F', 'msg-3', 1002);
      expect(detector.verdictFor('node-F'), ByzantineVerdict.suspected);
      detector.exonerate('node-F');
      expect(detector.verdictFor('node-F'), ByzantineVerdict.trusted);
      expect(detector.evidenceCount('node-F'), 0);
    });

    test('evidenceCount returns total evidence', () {
      detector.reportInconsistentMessage('node-G', 'msg-1', 1000);
      detector.reportMissingHeartbeat('node-G', 2000);
      expect(detector.evidenceCount('node-G'), 2);
    });

    test('accusation includes evidence map', () {
      detector.reportInconsistentMessage('node-H', 'msg-1', 1000);
      detector.reportInconsistentMessage('node-H', 'msg-2', 1001);
      detector.reportInconsistentMessage('node-H', 'msg-3', 1002);
      final accusation = detector.accusations.first;
      expect(accusation.evidence.containsKey('inconsistentMessages'), isTrue);
      expect(accusation.evidence.containsKey('totalEvidence'), isTrue);
      expect(accusation.evidence['totalEvidence'], 3);
    });
  });

  group('NetworkNode — Node State Management', () {
    test('copyWith updates fields', () {
      final node = NetworkNode(
        nodeId: 'node-A',
        endpoint: 'tcp://node-a:9000',
        status: NodeStatus.connecting,
        lastSeen: 1000,
        connectedAt: 1000,
        trustLevel: TrustLevel.verified,
      );
      final updated = node.copyWith(status: NodeStatus.connected, lastSeen: 2000);
      expect(updated.status, NodeStatus.connected);
      expect(updated.lastSeen, 2000);
      expect(updated.nodeId, 'node-A');
    });

    test('isAlive returns true for connected nodes', () {
      final alive = NetworkNode(
        nodeId: 'A', endpoint: '', status: NodeStatus.connected,
        lastSeen: 0, connectedAt: 0, trustLevel: TrustLevel.verified,
      );
      final dead = NetworkNode(
        nodeId: 'B', endpoint: '', status: NodeStatus.disconnected,
        lastSeen: 0, connectedAt: 0, trustLevel: TrustLevel.verified,
      );
      expect(alive.isAlive, isTrue);
      expect(dead.isAlive, isFalse);
    });

    test('isTrusted returns true for verified and above', () {
      final verified = NetworkNode(
        nodeId: 'A', endpoint: '', status: NodeStatus.connected,
        lastSeen: 0, connectedAt: 0, trustLevel: TrustLevel.verified,
      );
      final untrusted = NetworkNode(
        nodeId: 'B', endpoint: '', status: NodeStatus.connected,
        lastSeen: 0, connectedAt: 0, trustLevel: TrustLevel.untrusted,
      );
      expect(verified.isTrusted, isTrue);
      expect(untrusted.isTrusted, isFalse);
    });
  });

  group('CivilizationNetwork — Full Network Stack', () {
    late CivilizationNetwork netA;
    late CivilizationNetwork netB;

    setUp(() {
      netA = CivilizationNetwork(localNodeId: 'node-A');
      netB = CivilizationNetwork(localNodeId: 'node-B');
    });

    test('addNode and connectNode', () {
      netA.addNode('node-B', 'tcp://node-b:9000', TrustLevel.verified, 1000);
      expect(netA.totalNodeCount, 1);
      expect(netA.connectedNodeCount, 0);
      netA.connectNode('node-B', 1000);
      expect(netA.connectedNodeCount, 1);
    });

    test('disconnectNode changes status', () {
      netA.addNode('node-B', 'tcp://node-b:9000', TrustLevel.verified, 1000);
      netA.connectNode('node-B', 1000);
      netA.disconnectNode('node-B', 2000);
      expect(netA.nodes['node-B']!.status, NodeStatus.disconnected);
    });

    test('banNode confirms byzantine', () {
      netA.addNode('node-C', 'tcp://node-c:9000', TrustLevel.untrusted, 1000);
      netA.connectNode('node-C', 1000);
      netA.banNode('node-C', 2000);
      expect(netA.nodes['node-C']!.status, NodeStatus.banned);
      expect(netA.byzantine.isByzantine('node-C'), isTrue);
    });

    test('sendConstitutionSync creates wire message', () {
      final manifest = LawManifest.forNode('node-A', 0);
      final msg = netA.sendConstitutionSync('node-B', manifest, 1000);
      expect(msg.type, WireMessageType.constitutionSync);
      expect(msg.senderId, 'node-A');
      expect(msg.targetId, 'node-B');
      expect(netA.sendQueue.length, 1);
    });

    test('sendJudiciaryBroadcast triggers gossip', () {
      netA.addNode('node-B', 'tcp://b:9000', TrustLevel.verified, 1000);
      netA.addNode('node-C', 'tcp://c:9000', TrustLevel.verified, 1000);
      netA.connectNode('node-B', 1000);
      netA.connectNode('node-C', 1000);
      netA.sendJudiciaryBroadcast('node-B', {'sanction': 'test'}, 1000);
      expect(netA.gossip.pendingCount, greaterThan(0));
    });

    test('sendLegislativeGossip triggers gossip', () {
      netA.addNode('node-B', 'tcp://b:9000', TrustLevel.verified, 1000);
      netA.addNode('node-C', 'tcp://c:9000', TrustLevel.verified, 1000);
      netA.addNode('node-D', 'tcp://d:9000', TrustLevel.verified, 1000);
      netA.connectNode('node-B', 1000);
      netA.connectNode('node-C', 1000);
      netA.connectNode('node-D', 1000);
      netA.sendLegislativeGossip('node-B', {'proposalId': 'leg-0'}, 1000);
      expect(netA.gossip.pendingCount, greaterThan(0));
    });

    test('sendConsensusVote creates wire message', () {
      final msg = netA.sendConsensusVote('node-B', 'amend-1', true, 'good law', 1000);
      expect(msg.type, WireMessageType.consensusVote);
      expect(msg.payload['amendmentId'], 'amend-1');
      expect(msg.payload['support'], isTrue);
    });

    test('sendHeartbeat updates lastHeartbeatAt', () {
      netA.sendHeartbeat('node-B', 0, 5000);
      expect(netA.sendQueue.length, 1);
    });

    test('receive processes constitution sync and replicates', () {
      final manifest = LawManifest.forNode('node-B', 0);
      final msg = WireMessage(
        type: WireMessageType.constitutionSync,
        senderId: 'node-B',
        targetId: 'node-A',
        sequenceNumber: 1,
        epoch: 0,
        payload: {'manifest': manifest.toJson(), 'lawCount': 10, 'epoch': 0},
        timestamp: 1000,
        messageId: 'node-B_1',
        signature: 'sig-1',
      );
      netA.receive(msg);
      expect(netA.replication.replicatedManifests.containsKey('node-B'), isTrue);
      expect(netA.receiveQueue.length, 1);
    });

    test('receive deduplicates via gossip', () {
      final msg = WireMessage(
        type: WireMessageType.heartbeat,
        senderId: 'node-B',
        targetId: 'node-A',
        sequenceNumber: 1,
        epoch: 0,
        payload: {},
        timestamp: 1000,
        messageId: 'msg-dup',
        signature: 'sig-1',
      );
      netA.receive(msg);
      netA.receive(msg);
      expect(netA.receiveQueue.length, 1);
    });

    test('receive heartbeat updates node lastSeen', () {
      netA.addNode('node-B', 'tcp://b:9000', TrustLevel.verified, 1000);
      netA.connectNode('node-B', 1000);
      final msg = WireMessage(
        type: WireMessageType.heartbeat,
        senderId: 'node-B',
        targetId: 'node-A',
        sequenceNumber: 1,
        epoch: 0,
        payload: {},
        timestamp: 2000,
        messageId: 'hb-1',
        signature: 'sig-1',
      );
      netA.receive(msg);
      expect(netA.nodes['node-B']!.lastSeen, 2000);
    });

    test('drainSendQueue returns and clears', () {
      final manifest = LawManifest.forNode('node-A', 0);
      netA.sendConstitutionSync('node-B', manifest, 1000);
      expect(netA.sendQueue.length, 1);
      final drained = netA.drainSendQueue();
      expect(drained.length, 1);
      expect(netA.sendQueue.length, 0);
    });

    test('drainReceiveQueue returns and clears', () {
      final msg = WireMessage(
        type: WireMessageType.heartbeat,
        senderId: 'node-B',
        targetId: 'node-A',
        sequenceNumber: 1,
        epoch: 0,
        payload: {},
        timestamp: 1000,
        messageId: 'hb-1',
        signature: 'sig-1',
      );
      netA.receive(msg);
      expect(netA.receiveQueue.length, 1);
      final drained = netA.drainReceiveQueue();
      expect(drained.length, 1);
      expect(netA.receiveQueue.length, 0);
    });

    test('checkHeartbeats disconnects stale nodes', () {
      netA.addNode('node-B', 'tcp://b:9000', TrustLevel.verified, 1000);
      netA.connectNode('node-B', 1000);
      netA.checkHeartbeats(30000, timeout: 15000);
      expect(netA.nodes['node-B']!.status, NodeStatus.disconnected);
    });

    test('two-node simulation: constitution sync + fork detection', () {
      netA.addNode('node-B', 'tcp://b:9000', TrustLevel.verified, 1000);
      netA.connectNode('node-B', 1000);

      final manifestA = LawManifest.forNode('node-A', 0).bumpVersion(RuntimeLawId.noBypassScheduler);
      netA.sendConstitutionSync('node-B', manifestA, 1000);

      final remoteManifest = LawManifest.forNode('node-B', 0).bumpVersion(RuntimeLawId.noBudgetBypass);
      final result = netA.replication.replicateFrom('node-B', remoteManifest, 1000);
      expect(result.forkDetected, isTrue);
    });

    test('sendLawEnactment creates wire message and gossips', () {
      netA.addNode('node-B', 'tcp://b:9000', TrustLevel.verified, 1000);
      netA.addNode('node-C', 'tcp://c:9000', TrustLevel.verified, 1000);
      netA.connectNode('node-B', 1000);
      netA.connectNode('node-C', 1000);

      final consensus = ConstitutionalConsensus(localNodeId: 'node-A');
      final legislature = AutonomousLegislature(
        consensus: consensus,
        traceGraph: ConstitutionalTraceGraph(),
        reputationEconomy: ReputationEconomy(ConstitutionalTraceGraph()),
        judiciary: RuntimeJudiciary(ConstitutionalTraceGraph(), ImmutableAuditLedger()),
      );
      legislature.propose(
        description: 'Test law',
        targetLaw: RuntimeLawId.noBypassScheduler,
        proposedChange: 'stricter enforcement',
        rationale: 'too many bypasses',
        timestamp: 1000,
      );
      legislature.simulate();
      legislature.analyzeImpact();
      legislature.judiciaryCheck();
      legislature.submitToVote(1000);
      consensus.castVote(voterId: 'node-A', amendmentId: legislature.proposals.first.proposalId, support: true, timestamp: 1000);
      final enacted = legislature.enact(1000);

      final msg = netA.sendLawEnactment('node-B', enacted, 1000);
      expect(msg.type, WireMessageType.lawEnactment);
      expect(msg.payload['proposalId'], enacted.proposalId);
      expect(netA.gossip.pendingCount, greaterThan(0));
    });

    test('sendByzantineAccusation creates wire message', () {
      final accusation = ByzantineAccusation(
        accusationId: 'byz-0',
        accusedNodeId: 'node-C',
        accuserNodeId: 'node-A',
        reason: 'inconsistent_messages',
        evidence: {'count': 5},
        timestamp: 1000,
      );
      final msg = netA.sendByzantineAccusation('node-B', accusation, 1000);
      expect(msg.type, WireMessageType.byzantineAccusation);
      expect(msg.payload['accused'], 'node-C');
    });
  });

  group('ConstitutionalGuard + Network Integration', () {
    test('guard without network has null network getter', () {
      final clock = HybridLogicalClock(nodeId: 'test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      final guard = ConstitutionalGuard(enforcer: enforcer);
      expect(guard.network, isNull);
    });

    test('guard with nodeId but no network has null network getter', () {
      final clock = HybridLogicalClock(nodeId: 'test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      final guard = ConstitutionalGuard(enforcer: enforcer, nodeId: 'node-A');
      expect(guard.network, isNull);
    });

    test('guard with enableNetwork has network getter', () {
      final clock = HybridLogicalClock(nodeId: 'test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      final guard = ConstitutionalGuard(enforcer: enforcer, nodeId: 'node-A', enableNetwork: true);
      expect(guard.network, isNotNull);
      expect(guard.network!.localNodeId, 'node-A');
    });

    test('guard with network can send constitution sync', () {
      final clock = HybridLogicalClock(nodeId: 'test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      final guard = ConstitutionalGuard(enforcer: enforcer, nodeId: 'node-A', enableNetwork: true);
      final manifest = LawManifest.forNode('node-A', 0);
      guard.network!.sendConstitutionSync('node-B', manifest, 1000);
      expect(guard.network!.sendQueue.length, 1);
    });

    test('full stack: guard + network + byzantine detection', () {
      final clock = HybridLogicalClock(nodeId: 'test');
      final securityManager = SecurityManager();
      final enforcer = RuntimeLawEnforcer(clock: clock, securityManager: securityManager);
      final guard = ConstitutionalGuard(enforcer: enforcer, nodeId: 'node-A', enableNetwork: true);

      guard.network!.addNode('node-B', 'tcp://b:9000', TrustLevel.verified, 1000);
      guard.network!.connectNode('node-B', 1000);
      guard.network!.addNode('node-C', 'tcp://c:9000', TrustLevel.verified, 1000);
      guard.network!.connectNode('node-C', 1000);

      guard.network!.byzantine.reportInconsistentMessage('node-C', 'msg-1', 1000);
      guard.network!.byzantine.reportInconsistentMessage('node-C', 'msg-2', 1001);
      guard.network!.byzantine.reportInconsistentMessage('node-C', 'msg-3', 1002);

      expect(guard.network!.byzantine.verdictFor('node-C'), ByzantineVerdict.suspected);

      guard.network!.banNode('node-C', 2000);
      expect(guard.network!.byzantine.isByzantine('node-C'), isTrue);
      expect(guard.network!.nodes['node-C']!.status, NodeStatus.banned);

      expect(guard.transport, isNotNull);
      expect(guard.identity, isNotNull);
      expect(guard.economy, isNotNull);
      expect(guard.consensus, isNotNull);
    });
  });
}
