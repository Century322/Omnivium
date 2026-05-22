import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../distributed/transport/runtime_transport.dart';
import '../stability/security.dart';
import 'runtime_law.dart';
import 'constitutional_sovereign.dart';
import 'constitutional_trace.dart';

enum WireMessageType {
  constitutionSync,
  judiciaryBroadcast,
  reputationExchange,
  legislativeGossip,
  forkNegotiation,
  heartbeat,
  identityAnnounce,
  federationInvite,
  federationAccept,
  consensusVote,
  lawEnactment,
  byzantineAccusation,
}

class WireMessage {
  final WireMessageType type;
  final String senderId;
  final String targetId;
  final int sequenceNumber;
  final int epoch;
  final Map<String, dynamic> payload;
  final int timestamp;
  final String messageId;
  final String signature;

  const WireMessage({
    required this.type,
    required this.senderId,
    required this.targetId,
    required this.sequenceNumber,
    required this.epoch,
    required this.payload,
    required this.timestamp,
    required this.messageId,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sender': senderId,
        'target': targetId,
        'seq': sequenceNumber,
        'epoch': epoch,
        'payload': payload,
        'ts': timestamp,
        'msgId': messageId,
        'sig': signature,
      };

  factory WireMessage.fromJson(Map<String, dynamic> json) => WireMessage(
        type: WireMessageType.values.firstWhere((t) => t.name == json['type']),
        senderId: json['sender'] as String,
        targetId: json['target'] as String,
        sequenceNumber: json['seq'] as int,
        epoch: json['epoch'] as int,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        timestamp: json['ts'] as int,
        messageId: json['msgId'] as String,
        signature: json['sig'] as String,
      );

  List<int> toBytes() {
    return utf8.encode(jsonEncode(toJson()));
  }

  static WireMessage fromBytes(List<int> bytes) {
    final str = utf8.decode(bytes);
    final parsed = jsonDecode(str) as Map<String, dynamic>;
    return WireMessage.fromJson(parsed);
  }

  static String computeSignature(String senderId, String targetId, int timestamp, int seq, Map<String, dynamic> payload) {
    final input = '$senderId|$targetId|$timestamp|$seq|${jsonEncode(payload)}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return 'wire_${digest.toString().substring(0, 32)}';
  }
}

class GossipProtocol {
  final String localNodeId;
  final int fanout;
  final Duration ttl;
  final Map<String, int> _seen = {};
  final List<WireMessage> _pendingGossip = [];
  final Map<String, int> _propagationCount = {};

  GossipProtocol({
    required this.localNodeId,
    this.fanout = 3,
    this.ttl = const Duration(seconds: 30),
  });

  int get pendingCount => _pendingGossip.length;
  Map<String, int> get propagationCounts => Map.unmodifiable(_propagationCount);

  List<WireMessage> gossip(WireMessage message, List<String> knownPeers) {
    if (_seen.containsKey(message.messageId)) return [];
    _seen[message.messageId] = message.timestamp;

    final targets = knownPeers
        .where((p) => p != localNodeId && p != message.senderId)
        .take(fanout)
        .toList();

    final relayed = <WireMessage>[];
    for (final target in targets) {
      final relay = WireMessage(
        type: message.type,
        senderId: localNodeId,
        targetId: target,
        sequenceNumber: message.sequenceNumber,
        epoch: message.epoch,
        payload: message.payload,
        timestamp: message.timestamp,
        messageId: message.messageId,
        signature: message.signature,
      );
      _pendingGossip.add(relay);
      relayed.add(relay);
    }

    _propagationCount[message.messageId] = (_propagationCount[message.messageId] ?? 0) + targets.length;
    return relayed;
  }

  List<WireMessage> drainPending() {
    final pending = List<WireMessage>.from(_pendingGossip);
    _pendingGossip.clear();
    return pending;
  }

  bool hasSeen(String messageId) => _seen.containsKey(messageId);

  void prune(int olderThanTimestamp) {
    _seen.removeWhere((_, ts) => ts < olderThanTimestamp);
  }
}

class ConstitutionalReplication {
  final String localNodeId;
  final LawManifest _localManifest;
  final Map<String, LawManifest> _replicatedManifests = {};
  final List<ReplicationEntry> _replicationLog = [];
  final Map<String, int> _replicationLag = {};
  int _replicationSeq = 0;

  ConstitutionalReplication({
    required this.localNodeId,
    int initialEpoch = 0,
  }) : _localManifest = LawManifest.forNode(localNodeId, initialEpoch);

  LawManifest get localManifest => _localManifest;
  Map<String, LawManifest> get replicatedManifests => Map.unmodifiable(_replicatedManifests);
  List<ReplicationEntry> get replicationLog => List.unmodifiable(_replicationLog);

  ReplicationResult replicateFrom(String remoteNodeId, LawManifest remoteManifest, int timestamp) {
    final existing = _replicatedManifests[remoteNodeId];
    final lag = existing != null ? remoteManifest.epoch - existing.epoch : 0;
    _replicationLag[remoteNodeId] = lag;

    _replicatedManifests[remoteNodeId] = remoteManifest;

    final fork = _detectFork(remoteManifest);

    final entry = ReplicationEntry(
      entryId: 'repl-${_replicationSeq++}',
      remoteNodeId: remoteNodeId,
      remoteEpoch: remoteManifest.epoch,
      localEpoch: _localManifest.epoch,
      forkDetected: fork != null,
      forkResolution: fork?.resolution,
      timestamp: timestamp,
    );
    _replicationLog.add(entry);

    return ReplicationResult(
      replicated: true,
      forkDetected: fork != null,
      fork: fork,
      lag: lag,
    );
  }

  LawFork? _detectFork(LawManifest remoteManifest) {
    final conflictingLaws = <RuntimeLawId>[];

    for (final lawId in RuntimeLawId.values) {
      final localVer = _localManifest.lawVersions[lawId] ?? 0;
      final remoteVer = remoteManifest.lawVersions[lawId] ?? 0;
      if (localVer != remoteVer) {
        conflictingLaws.add(lawId);
      }
    }

    if (conflictingLaws.isEmpty) return null;

    LawForkResolution resolution;
    if (remoteManifest.epoch > _localManifest.epoch) {
      resolution = LawForkResolution.adoptRemote;
    } else if (_localManifest.epoch > remoteManifest.epoch) {
      resolution = LawForkResolution.keepLocal;
    } else {
      resolution = LawForkResolution.conflict;
    }

    return LawFork(
      forkId: 'fork-repl-$_replicationSeq',
      lawId: conflictingLaws.first,
      localManifest: _localManifest,
      remoteManifest: remoteManifest,
      resolution: resolution,
      detectedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  int replicationLagFor(String nodeId) => _replicationLag[nodeId] ?? 0;

  int maxReplicationLag() {
    if (_replicationLag.isEmpty) return 0;
    return _replicationLag.values.reduce((a, b) => a > b ? a : b);
  }
}

class ReplicationEntry {
  final String entryId;
  final String remoteNodeId;
  final int remoteEpoch;
  final int localEpoch;
  final bool forkDetected;
  final LawForkResolution? forkResolution;
  final int timestamp;

  const ReplicationEntry({
    required this.entryId,
    required this.remoteNodeId,
    required this.remoteEpoch,
    required this.localEpoch,
    required this.forkDetected,
    this.forkResolution,
    required this.timestamp,
  });
}

class ReplicationResult {
  final bool replicated;
  final bool forkDetected;
  final LawFork? fork;
  final int lag;

  const ReplicationResult({
    required this.replicated,
    required this.forkDetected,
    this.fork,
    required this.lag,
  });
}

class ByzantineDetector {
  final String localNodeId;
  final int accusationThreshold;
  final Map<String, int> _inconsistentMessages = {};
  final Map<String, int> _missingHeartbeats = {};
  final Map<String, int> _conflictingVotes = {};
  final List<ByzantineAccusation> _accusations = [];
  final Map<String, ByzantineVerdict> _verdicts = {};
  int _accusationSeq = 0;

  ByzantineDetector({
    required this.localNodeId,
    this.accusationThreshold = 3,
  });

  List<ByzantineAccusation> get accusations => List.unmodifiable(_accusations);
  Map<String, ByzantineVerdict> get verdicts => Map.unmodifiable(_verdicts);

  void reportInconsistentMessage(String nodeId, String messageId, int timestamp) {
    _inconsistentMessages[nodeId] = (_inconsistentMessages[nodeId] ?? 0) + 1;
    _checkThreshold(nodeId, 'inconsistent_messages', timestamp);
  }

  void reportMissingHeartbeat(String nodeId, int timestamp) {
    _missingHeartbeats[nodeId] = (_missingHeartbeats[nodeId] ?? 0) + 1;
    _checkThreshold(nodeId, 'missing_heartbeat', timestamp);
  }

  void reportConflictingVote(String nodeId, String amendmentId, int timestamp) {
    _conflictingVotes[nodeId] = (_conflictingVotes[nodeId] ?? 0) + 1;
    _checkThreshold(nodeId, 'conflicting_vote', timestamp);
  }

  void _checkThreshold(String nodeId, String reason, int timestamp) {
    final totalEvidence = (_inconsistentMessages[nodeId] ?? 0) +
        (_missingHeartbeats[nodeId] ?? 0) +
        (_conflictingVotes[nodeId] ?? 0);

    if (totalEvidence >= accusationThreshold && !_verdicts.containsKey(nodeId)) {
      final accusation = ByzantineAccusation(
        accusationId: 'byz-${_accusationSeq++}',
        accusedNodeId: nodeId,
        accuserNodeId: localNodeId,
        reason: reason,
        evidence: {
          'inconsistentMessages': _inconsistentMessages[nodeId] ?? 0,
          'missingHeartbeats': _missingHeartbeats[nodeId] ?? 0,
          'conflictingVotes': _conflictingVotes[nodeId] ?? 0,
          'totalEvidence': totalEvidence,
        },
        timestamp: timestamp,
      );
      _accusations.add(accusation);
      _verdicts[nodeId] = ByzantineVerdict.suspected;
    }
  }

  ByzantineVerdict verdictFor(String nodeId) => _verdicts[nodeId] ?? ByzantineVerdict.trusted;

  bool isByzantine(String nodeId) => _verdicts[nodeId] == ByzantineVerdict.confirmed;

  void confirmByzantine(String nodeId, int timestamp) {
    _verdicts[nodeId] = ByzantineVerdict.confirmed;
  }

  void exonerate(String nodeId) {
    _verdicts[nodeId] = ByzantineVerdict.trusted;
    _inconsistentMessages.remove(nodeId);
    _missingHeartbeats.remove(nodeId);
    _conflictingVotes.remove(nodeId);
  }

  int evidenceCount(String nodeId) =>
      (_inconsistentMessages[nodeId] ?? 0) +
      (_missingHeartbeats[nodeId] ?? 0) +
      (_conflictingVotes[nodeId] ?? 0);
}

enum ByzantineVerdict {
  trusted,
  suspected,
  confirmed,
}

class ByzantineAccusation {
  final String accusationId;
  final String accusedNodeId;
  final String accuserNodeId;
  final String reason;
  final Map<String, dynamic> evidence;
  final int timestamp;

  const ByzantineAccusation({
    required this.accusationId,
    required this.accusedNodeId,
    required this.accuserNodeId,
    required this.reason,
    required this.evidence,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': accusationId,
        'accused': accusedNodeId,
        'accuser': accuserNodeId,
        'reason': reason,
        'evidence': evidence,
        'ts': timestamp,
      };
}

class NetworkNode {
  final String nodeId;
  final String endpoint;
  final NodeStatus status;
  final int lastSeen;
  final int connectedAt;
  final TrustLevel trustLevel;
  final int latency;

  const NetworkNode({
    required this.nodeId,
    required this.endpoint,
    required this.status,
    required this.lastSeen,
    required this.connectedAt,
    required this.trustLevel,
    this.latency = 0,
  });

  NetworkNode copyWith({
    NodeStatus? status,
    int? lastSeen,
    TrustLevel? trustLevel,
    int? latency,
  }) =>
      NetworkNode(
        nodeId: nodeId,
        endpoint: endpoint,
        status: status ?? this.status,
        lastSeen: lastSeen ?? this.lastSeen,
        connectedAt: connectedAt,
        trustLevel: trustLevel ?? this.trustLevel,
        latency: latency ?? this.latency,
      );

  bool get isAlive => status == NodeStatus.connected;
  bool get isTrusted => trustLevel.index <= TrustLevel.verified.index;
}

enum NodeStatus {
  connecting,
  connected,
  disconnected,
  banned,
}

class CivilizationNetwork {
  final String localNodeId;
  final ConstitutionalTraceGraph? _traceGraph;
  final Map<String, NetworkNode> _nodes = {};
  final ConstitutionalReplication _replication;
  final GossipProtocol _gossip;
  final ByzantineDetector _byzantine;
  final List<WireMessage> _sendQueue = [];
  final List<WireMessage> _receiveQueue = [];
  int _messageSeq = 0;
  final int _heartbeatInterval;
  RuntimeTransport? _transport;

  CivilizationNetwork({
    required this.localNodeId,
    int initialEpoch = 0,
    int gossipFanout = 3,
    int byzantineThreshold = 3,
    int heartbeatInterval = 5000,
    ConstitutionalTraceGraph? traceGraph,
  })  : _traceGraph = traceGraph,
        _replication = ConstitutionalReplication(localNodeId: localNodeId, initialEpoch: initialEpoch),
        _gossip = GossipProtocol(localNodeId: localNodeId, fanout: gossipFanout),
        _byzantine = ByzantineDetector(localNodeId: localNodeId, accusationThreshold: byzantineThreshold),
        _heartbeatInterval = heartbeatInterval;

  void attachTransport(RuntimeTransport transport) {
    _transport = transport;
    transport.incoming.listen((msg) {
      final wireMsg = WireMessage.fromBytes(msg.payload['raw'] is List<int> ? msg.payload['raw'] as List<int> : utf8.encode(jsonEncode(msg.payload)));
      _receiveQueue.add(wireMsg);
    });
  }

  ConstitutionalReplication get replication => _replication;
  GossipProtocol get gossip => _gossip;
  ByzantineDetector get byzantine => _byzantine;
  Map<String, NetworkNode> get nodes => Map.unmodifiable(_nodes);
  List<WireMessage> get sendQueue => List.unmodifiable(_sendQueue);
  List<WireMessage> get receiveQueue => List.unmodifiable(_receiveQueue);
  int get connectedNodeCount => _nodes.values.where((n) => n.isAlive).length;
  int get totalNodeCount => _nodes.length;

  NetworkNode addNode(String nodeId, String endpoint, TrustLevel trustLevel, int timestamp) {
    final node = NetworkNode(
      nodeId: nodeId,
      endpoint: endpoint,
      status: NodeStatus.connecting,
      lastSeen: timestamp,
      connectedAt: timestamp,
      trustLevel: trustLevel,
    );
    _nodes[nodeId] = node;
    return node;
  }

  NetworkNode? connectNode(String nodeId, int timestamp) {
    final node = _nodes[nodeId];
    if (node == null) return null;
    _nodes[nodeId] = node.copyWith(status: NodeStatus.connected, lastSeen: timestamp);
    return _nodes[nodeId];
  }

  NetworkNode? disconnectNode(String nodeId, int timestamp) {
    final node = _nodes[nodeId];
    if (node == null) return null;
    _nodes[nodeId] = node.copyWith(status: NodeStatus.disconnected, lastSeen: timestamp);
    return _nodes[nodeId];
  }

  void banNode(String nodeId, int timestamp) {
    final node = _nodes[nodeId];
    if (node == null) return;
    _nodes[nodeId] = node.copyWith(status: NodeStatus.banned, lastSeen: timestamp);
    _byzantine.confirmByzantine(nodeId, timestamp);
  }

  WireMessage sendConstitutionSync(String targetId, LawManifest manifest, int timestamp) {
    final msg = _createWireMessage(
      type: WireMessageType.constitutionSync,
      targetId: targetId,
      payload: {
        'manifest': manifest.toJson(),
        'lawCount': manifest.lawVersions.length,
        'epoch': manifest.epoch,
      },
      timestamp: timestamp,
    );
    _sendQueue.add(msg);
    return msg;
  }

  WireMessage sendJudiciaryBroadcast(String targetId, Map<String, dynamic> sanctionData, int timestamp) {
    final msg = _createWireMessage(
      type: WireMessageType.judiciaryBroadcast,
      targetId: targetId,
      payload: sanctionData,
      timestamp: timestamp,
    );
    _sendQueue.add(msg);
    _gossip.gossip(msg, _aliveNodeIds());
    return msg;
  }

  WireMessage sendLegislativeGossip(String targetId, Map<String, dynamic> proposalData, int timestamp) {
    final msg = _createWireMessage(
      type: WireMessageType.legislativeGossip,
      targetId: targetId,
      payload: proposalData,
      timestamp: timestamp,
    );
    _sendQueue.add(msg);
    _gossip.gossip(msg, _aliveNodeIds());
    return msg;
  }

  WireMessage sendConsensusVote(String targetId, String amendmentId, bool support, String? reason, int timestamp) {
    final msg = _createWireMessage(
      type: WireMessageType.consensusVote,
      targetId: targetId,
      payload: {
        'amendmentId': amendmentId,
        'support': support,
        'reason': reason,
      },
      timestamp: timestamp,
    );
    _sendQueue.add(msg);
    return msg;
  }

  WireMessage sendHeartbeat(String targetId, int epoch, int timestamp) {
    final msg = _createWireMessage(
      type: WireMessageType.heartbeat,
      targetId: targetId,
      payload: {'epoch': epoch, 'status': 'alive', 'nodes': _aliveNodeIds().length},
      timestamp: timestamp,
    );
    _sendQueue.add(msg);
    return msg;
  }

  WireMessage sendByzantineAccusation(String targetId, ByzantineAccusation accusation, int timestamp) {
    final msg = _createWireMessage(
      type: WireMessageType.byzantineAccusation,
      targetId: targetId,
      payload: accusation.toJson(),
      timestamp: timestamp,
    );
    _sendQueue.add(msg);
    _gossip.gossip(msg, _aliveNodeIds());
    return msg;
  }

  WireMessage sendLawEnactment(String targetId, LegislativeProposal proposal, int timestamp) {
    final msg = _createWireMessage(
      type: WireMessageType.lawEnactment,
      targetId: targetId,
      payload: {
        'proposal': proposal.toJson(),
        'proposalId': proposal.proposalId,
        'lawId': proposal.targetLaw.name,
        'stage': proposal.stage.name,
      },
      timestamp: timestamp,
    );
    _sendQueue.add(msg);
    _gossip.gossip(msg, _aliveNodeIds());
    return msg;
  }

  void receive(WireMessage message) {
    if (_gossip.hasSeen(message.messageId)) return;
    _gossip.gossip(message, _aliveNodeIds());
    _receiveQueue.add(message);

    switch (message.type) {
      case WireMessageType.constitutionSync:
        _handleConstitutionSync(message);
        break;
      case WireMessageType.heartbeat:
        _handleHeartbeat(message);
        break;
      case WireMessageType.byzantineAccusation:
        _handleByzantineAccusation(message);
        break;
      default:
        break;
    }
  }

  void _handleConstitutionSync(WireMessage message) {
    final manifestJson = message.payload['manifest'];
    if (manifestJson is Map<String, dynamic>) {
      final versions = <RuntimeLawId, int>{};
      final rawVersions = manifestJson['versions'] as Map<String, dynamic>?;
      if (rawVersions != null) {
        for (final entry in rawVersions.entries) {
          final lawId = RuntimeLawId.values.firstWhere(
            (l) => l.name == entry.key,
            orElse: () => RuntimeLawId.noBypassCapabilityRouter,
          );
          versions[lawId] = entry.value as int;
        }
      }
      final manifest = LawManifest(
        nodeId: manifestJson['node'] as String? ?? message.senderId,
        epoch: manifestJson['epoch'] as int? ?? 0,
        lawVersions: versions,
        hash: manifestJson['hash'] as int? ?? 0,
      );
      _replication.replicateFrom(message.senderId, manifest, message.timestamp);
    }
  }

  void _handleHeartbeat(WireMessage message) {
    final node = _nodes[message.senderId];
    if (node != null && node.isAlive) {
      _nodes[message.senderId] = node.copyWith(lastSeen: message.timestamp);
    }
  }

  void _handleByzantineAccusation(WireMessage message) {
    final accusedId = message.payload['accused'] as String?;
    if (accusedId != null) {
      _byzantine.reportInconsistentMessage(accusedId, message.messageId, message.timestamp);
    }
  }

  List<WireMessage> drainSendQueue() {
    final messages = List<WireMessage>.from(_sendQueue);
    _sendQueue.clear();
    if (_transport != null && _transport!.state == TransportState.connected) {
      for (final msg in messages) {
        try {
          final transportMsg = TransportMessage(
            id: msg.sequenceNumber.toString(),
            type: msg.type.name,
            sourceNodeId: msg.senderId,
            targetNodeId: msg.targetId,
            payload: {'raw': msg.toBytes()},
            timestamp: HybridTimestampLike(
              physicalTime: msg.timestamp,
              nodeId: msg.senderId,
            ),
          );
          _transport!.send(transportMsg);
        } catch (_) {}
      }
    }
    return messages;
  }

  List<WireMessage> drainReceiveQueue() {
    final messages = List<WireMessage>.from(_receiveQueue);
    _receiveQueue.clear();
    return messages;
  }

  void checkHeartbeats(int timestamp, {int timeout = 15000}) {
    for (final entry in _nodes.entries) {
      if (entry.value.isAlive && timestamp - entry.value.lastSeen > timeout) {
        _byzantine.reportMissingHeartbeat(entry.key, timestamp);
        _nodes[entry.key] = entry.value.copyWith(status: NodeStatus.disconnected);
      }
    }
  }

  List<String> _aliveNodeIds() =>
      _nodes.values.where((n) => n.isAlive).map((n) => n.nodeId).toList();

  WireMessage _createWireMessage({
    required WireMessageType type,
    required String targetId,
    required Map<String, dynamic> payload,
    required int timestamp,
  }) {
    final seq = _messageSeq++;
    final msgId = '${localNodeId}_$seq';
    final sig = WireMessage.computeSignature(localNodeId, targetId, timestamp, seq, payload);
    return WireMessage(
      type: type,
      senderId: localNodeId,
      targetId: targetId,
      sequenceNumber: seq,
      epoch: _replication.localManifest.epoch,
      payload: payload,
      timestamp: timestamp,
      messageId: msgId,
      signature: sig,
    );
  }
}
