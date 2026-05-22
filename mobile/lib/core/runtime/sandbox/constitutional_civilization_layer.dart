import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../stability/security.dart';
import 'constitutional_civilization.dart';
import 'constitutional_sovereign.dart';
import 'constitutional_trace.dart';
import 'runtime_law.dart';

enum DiplomacyMessageType {
  constitutionSync,
  judiciaryBroadcast,
  reputationExchange,
  legislativeGossip,
  forkNegotiation,
  heartbeat,
  identityAnnounce,
  federationInvite,
  federationAccept,
}

class DiplomacyMessage {
  final DiplomacyMessageType type;
  final String senderId;
  final String targetId;
  final int epoch;
  final Map<String, dynamic> payload;
  final int timestamp;
  final String signature;

  const DiplomacyMessage({
    required this.type,
    required this.senderId,
    required this.targetId,
    required this.epoch,
    required this.payload,
    required this.timestamp,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sender': senderId,
        'target': targetId,
        'epoch': epoch,
        'payload': payload,
        'ts': timestamp,
        'sig': signature,
      };

  static String computeSignature(String senderId, String targetId, int timestamp, Map<String, dynamic> payload) {
    final input = utf8.encode('$senderId|$targetId|$timestamp|${jsonEncode(payload)}');
    final digest = sha256.convert(input);
    return 'diplo_${digest.toString().substring(0, 32)}';
  }
}

class DiplomacyChannel {
  final String channelId;
  final String localNodeId;
  final String remoteNodeId;
  final DiplomacyMessageType channelType;
  bool isActive;

  DiplomacyChannel({
    required this.channelId,
    required this.localNodeId,
    required this.remoteNodeId,
    required this.channelType,
    this.isActive = true,
  });
}

class CivilizationTransport {
  final String localNodeId;
  final ConstitutionalTraceGraph? _traceGraph;
  final List<DiplomacyMessage> _outbox = [];
  final List<DiplomacyMessage> _inbox = [];
  final Map<String, DiplomacyChannel> _channels = {};
  int _messageSeq = 0;

  CivilizationTransport({required this.localNodeId, ConstitutionalTraceGraph? traceGraph}) : _traceGraph = traceGraph;

  List<DiplomacyMessage> get outbox => List.unmodifiable(_outbox);
  List<DiplomacyMessage> get inbox => List.unmodifiable(_inbox);
  Map<String, DiplomacyChannel> get channels => Map.unmodifiable(_channels);
  int get outboxCount => _outbox.length;
  int get inboxCount => _inbox.length;

  DiplomacyChannel openChannel(String remoteNodeId, DiplomacyMessageType type) {
    final channelId = '$localNodeId::$remoteNodeId::${type.name}';
    final channel = DiplomacyChannel(
      channelId: channelId,
      localNodeId: localNodeId,
      remoteNodeId: remoteNodeId,
      channelType: type,
    );
    _channels[channelId] = channel;
    return channel;
  }

  DiplomacyMessage sendConstitutionSync(String targetId, LawManifest manifest, int timestamp) {
    final msg = _createMessage(
      type: DiplomacyMessageType.constitutionSync,
      targetId: targetId,
      payload: {
        'manifest': manifest.toJson(),
        'lawCount': manifest.lawVersions.length,
        'epoch': manifest.epoch,
      },
      timestamp: timestamp,
    );
    _outbox.add(msg);
    return msg;
  }

  DiplomacyMessage sendJudiciaryBroadcast(String targetId, Sanction sanction, int timestamp) {
    final msg = _createMessage(
      type: DiplomacyMessageType.judiciaryBroadcast,
      targetId: targetId,
      payload: {
        'sanction': sanction.toJson(),
        'sandboxId': sanction.sandboxId,
        'type': sanction.type.name,
      },
      timestamp: timestamp,
    );
    _outbox.add(msg);
    return msg;
  }

  DiplomacyMessage sendReputationExchange(String targetId, TrustPassport passport, int timestamp) {
    final msg = _createMessage(
      type: DiplomacyMessageType.reputationExchange,
      targetId: targetId,
      payload: {
        'passport': passport.toJson(),
        'entityId': passport.entityId,
        'score': passport.reputationScore,
      },
      timestamp: timestamp,
    );
    _outbox.add(msg);
    return msg;
  }

  DiplomacyMessage sendLegislativeGossip(String targetId, LegislativeProposal proposal, int timestamp) {
    final msg = _createMessage(
      type: DiplomacyMessageType.legislativeGossip,
      targetId: targetId,
      payload: {
        'proposal': proposal.toJson(),
        'proposalId': proposal.proposalId,
        'stage': proposal.stage.name,
        'targetLaw': proposal.targetLaw.name,
      },
      timestamp: timestamp,
    );
    _outbox.add(msg);
    return msg;
  }

  DiplomacyMessage sendForkNegotiation(String targetId, LawFork fork, String proposedResolution, int timestamp) {
    final msg = _createMessage(
      type: DiplomacyMessageType.forkNegotiation,
      targetId: targetId,
      payload: {
        'forkId': fork.forkId,
        'lawId': fork.lawId.name,
        'localResolution': fork.resolution.name,
        'proposedResolution': proposedResolution,
      },
      timestamp: timestamp,
    );
    _outbox.add(msg);
    return msg;
  }

  DiplomacyMessage sendHeartbeat(String targetId, int epoch, int timestamp) {
    final msg = _createMessage(
      type: DiplomacyMessageType.heartbeat,
      targetId: targetId,
      payload: {'epoch': epoch, 'status': 'alive'},
      timestamp: timestamp,
    );
    _outbox.add(msg);
    return msg;
  }

  DiplomacyMessage sendIdentityAnnounce(String targetId, CivilizationIdentity identity, int timestamp) {
    final msg = _createMessage(
      type: DiplomacyMessageType.identityAnnounce,
      targetId: targetId,
      payload: {
        'nodeId': identity.nodeId,
        'publicKey': identity.publicKey,
        'civilizationEpoch': identity.civilizationEpoch,
        'federationId': identity.federationId,
        'trustLevel': identity.trustLevel.name,
      },
      timestamp: timestamp,
    );
    _outbox.add(msg);
    return msg;
  }

  DiplomacyMessage sendFederationInvite(String targetId, String federationId, int timestamp) {
    final msg = _createMessage(
      type: DiplomacyMessageType.federationInvite,
      targetId: targetId,
      payload: {'federationId': federationId, 'inviter': localNodeId},
      timestamp: timestamp,
    );
    _outbox.add(msg);
    return msg;
  }

  DiplomacyMessage sendFederationAccept(String targetId, String federationId, int timestamp) {
    final msg = _createMessage(
      type: DiplomacyMessageType.federationAccept,
      targetId: targetId,
      payload: {'federationId': federationId, 'acceptor': localNodeId},
      timestamp: timestamp,
    );
    _outbox.add(msg);
    return msg;
  }

  void receive(DiplomacyMessage message) {
    _inbox.add(message);
  }

  List<DiplomacyMessage> inboxOfType(DiplomacyMessageType type) =>
      _inbox.where((m) => m.type == type).toList();

  List<DiplomacyMessage> inboxFrom(String senderId) =>
      _inbox.where((m) => m.senderId == senderId).toList();

  void clearOutbox() => _outbox.clear();
  void clearInbox() => _inbox.clear();

  DiplomacyMessage _createMessage({
    required DiplomacyMessageType type,
    required String targetId,
    required Map<String, dynamic> payload,
    required int timestamp,
  }) {
    final sig = DiplomacyMessage.computeSignature(localNodeId, targetId, timestamp, payload);
    return DiplomacyMessage(
      type: type,
      senderId: localNodeId,
      targetId: targetId,
      epoch: _messageSeq++,
      payload: payload,
      timestamp: timestamp,
      signature: sig,
    );
  }
}

class CivilizationIdentity {
  final String nodeId;
  final String publicKey;
  final int civilizationEpoch;
  final String? federationId;
  final TrustLevel trustLevel;
  final List<String> constitutionalAncestry;
  final int createdAt;
  final String signature;

  const CivilizationIdentity({
    required this.nodeId,
    required this.publicKey,
    required this.civilizationEpoch,
    this.federationId,
    required this.trustLevel,
    required this.constitutionalAncestry,
    required this.createdAt,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'publicKey': publicKey,
        'epoch': civilizationEpoch,
        'federation': federationId,
        'trust': trustLevel.name,
        'ancestry': constitutionalAncestry,
        'created': createdAt,
        'sig': signature,
      };

  CivilizationIdentity bumpEpoch() => CivilizationIdentity(
        nodeId: nodeId,
        publicKey: publicKey,
        civilizationEpoch: civilizationEpoch + 1,
        federationId: federationId,
        trustLevel: trustLevel,
        constitutionalAncestry: constitutionalAncestry,
        createdAt: createdAt,
        signature: signature,
      );

  CivilizationIdentity joinFederation(String fedId) => CivilizationIdentity(
        nodeId: nodeId,
        publicKey: publicKey,
        civilizationEpoch: civilizationEpoch,
        federationId: fedId,
        trustLevel: trustLevel,
        constitutionalAncestry: constitutionalAncestry,
        createdAt: createdAt,
        signature: signature,
      );

  CivilizationIdentity updateTrust(TrustLevel newLevel) => CivilizationIdentity(
        nodeId: nodeId,
        publicKey: publicKey,
        civilizationEpoch: civilizationEpoch,
        federationId: federationId,
        trustLevel: newLevel,
        constitutionalAncestry: constitutionalAncestry,
        createdAt: createdAt,
        signature: signature,
      );

  static CivilizationIdentity generate(String nodeId, {String? federationId}) {
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final publicKey = _generatePublicKey(nodeId);
    final signature = _computeSignature(nodeId, publicKey, createdAt);
    return CivilizationIdentity(
      nodeId: nodeId,
      publicKey: publicKey,
      civilizationEpoch: 0,
      federationId: federationId,
      trustLevel: TrustLevel.verified,
      constitutionalAncestry: ['genesis'],
      createdAt: createdAt,
      signature: signature,
    );
  }

  static bool verify(CivilizationIdentity identity) {
    final expectedSig = _computeSignature(identity.nodeId, identity.publicKey, identity.createdAt);
    return identity.signature == expectedSig;
  }

  static String _generatePublicKey(String nodeId) {
    final input = utf8.encode('pubkey_$nodeId');
    final digest = sha256.convert(input);
    return 'pk_${digest.toString().substring(0, 32)}';
  }

  static String _computeSignature(String nodeId, String publicKey, int createdAt) {
    final input = utf8.encode('$nodeId|$publicKey|$createdAt');
    final digest = sha256.convert(input);
    return 'id_${digest.toString().substring(0, 32)}';
  }
}

class TrustGraph {
  final Map<String, Set<String>> _edges = {};

  Map<String, Set<String>> get edges => Map.unmodifiable(_edges);

  void addTrustEdge(String from, String to) {
    _edges.putIfAbsent(from, () => {});
    _edges[from]!.add(to);
  }

  void removeTrustEdge(String from, String to) {
    _edges[from]?.remove(to);
  }

  bool trusts(String from, String to) =>
      _edges[from]?.contains(to) ?? false;

  Set<String> trustedBy(String nodeId) {
    final result = <String>{};
    for (final entry in _edges.entries) {
      if (entry.value.contains(nodeId)) {
        result.add(entry.key);
      }
    }
    return result;
  }

  Set<String> trustsList(String nodeId) => _edges[nodeId] ?? {};

  int trustDepth(String from, String to, {int maxDepth = 10}) {
    if (from == to) return 0;
    final visited = <String>{};
    final queue = <(String, int)>[(from, 0)];

    while (queue.isNotEmpty) {
      final (current, depth) = queue.removeAt(0);
      if (depth > maxDepth) return -1;
      if (current == to) return depth;
      if (visited.contains(current)) continue;
      visited.add(current);

      for (final neighbor in _edges[current] ?? <String>{}) {
        if (!visited.contains(neighbor)) {
          queue.add((neighbor, depth + 1));
        }
      }
    }
    return -1;
  }

  bool isReachable(String from, String to, {int maxDepth = 10}) =>
      trustDepth(from, to, maxDepth: maxDepth) >= 0;
}

class FederationMembership {
  final String federationId;
  final List<String> members;
  final String founder;
  final int createdAt;
  final Map<String, TrustLevel> memberTrustLevels;

  const FederationMembership({
    required this.federationId,
    required this.members,
    required this.founder,
    required this.createdAt,
    required this.memberTrustLevels,
  });

  FederationMembership addMember(String nodeId, TrustLevel trustLevel) =>
      FederationMembership(
        federationId: federationId,
        members: [...members, nodeId],
        founder: founder,
        createdAt: createdAt,
        memberTrustLevels: {...memberTrustLevels, nodeId: trustLevel},
      );

  FederationMembership removeMember(String nodeId) =>
      FederationMembership(
        federationId: federationId,
        members: members.where((m) => m != nodeId).toList(),
        founder: founder,
        createdAt: createdAt,
        memberTrustLevels: Map.fromEntries(
          memberTrustLevels.entries.where((e) => e.key != nodeId),
        ),
      );

  bool isMember(String nodeId) => members.contains(nodeId);
  int get size => members.length;

  Map<String, dynamic> toJson() => {
        'id': federationId,
        'members': members,
        'founder': founder,
        'created': createdAt,
        'trustLevels': memberTrustLevels.map((k, v) => MapEntry(k, v.name)),
      };

  static FederationMembership create(String federationId, String founder) =>
      FederationMembership(
        federationId: federationId,
        members: [founder],
        founder: founder,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        memberTrustLevels: {founder: TrustLevel.system},
      );
}

class ExecutionCredits {
  final String entityId;
  final double balance;
  final double earnedTotal;
  final double spentTotal;
  final double taxPaid;
  final int lastUpdated;

  const ExecutionCredits({
    required this.entityId,
    required this.balance,
    required this.earnedTotal,
    required this.spentTotal,
    required this.taxPaid,
    required this.lastUpdated,
  });

  ExecutionCredits copyWith({
    double? balance,
    double? earnedTotal,
    double? spentTotal,
    double? taxPaid,
    int? lastUpdated,
  }) =>
      ExecutionCredits(
        entityId: entityId,
        balance: balance ?? this.balance,
        earnedTotal: earnedTotal ?? this.earnedTotal,
        spentTotal: spentTotal ?? this.spentTotal,
        taxPaid: taxPaid ?? this.taxPaid,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  Map<String, dynamic> toJson() => {
        'entity': entityId,
        'balance': balance.toStringAsFixed(2),
        'earned': earnedTotal.toStringAsFixed(2),
        'spent': spentTotal.toStringAsFixed(2),
        'tax': taxPaid.toStringAsFixed(2),
        'updated': lastUpdated,
      };
}

class FederationTreasury {
  final String federationId;
  double _balance;
  final Map<String, double> _taxCollected;
  final List<Map<String, dynamic>> _transactions;

  FederationTreasury({
    required this.federationId,
    double initialBalance = 0,
  })  : _balance = initialBalance,
        _taxCollected = {},
        _transactions = [];

  double get balance => _balance;
  Map<String, double> get taxCollected => Map.unmodifiable(_taxCollected);
  List<Map<String, dynamic>> get transactions => List.unmodifiable(_transactions);

  double collectTax(String entityId, double amount, int timestamp) {
    _balance += amount;
    _taxCollected[entityId] = (_taxCollected[entityId] ?? 0) + amount;
    _transactions.add({
      'type': 'tax',
      'entity': entityId,
      'amount': amount,
      'ts': timestamp,
    });
    return _balance;
  }

  double distribute(String entityId, double amount, String reason, int timestamp) {
    if (amount > _balance) return _balance;
    _balance -= amount;
    _transactions.add({
      'type': 'distribution',
      'entity': entityId,
      'amount': amount,
      'reason': reason,
      'ts': timestamp,
    });
    return _balance;
  }

  double imposePenalty(String entityId, double amount, String reason, int timestamp) {
    _balance += amount;
    _transactions.add({
      'type': 'penalty',
      'entity': entityId,
      'amount': amount,
      'reason': reason,
      'ts': timestamp,
    });
    return _balance;
  }
}

class ResourceEconomy {
  final double _taxRate;
  final double _executionCreditRate;
  final Map<String, ExecutionCredits> _accounts = {};
  final FederationTreasury _treasury;
  final ImmutableAuditLedger? _ledger;

  ResourceEconomy({
    double taxRate = 0.1,
    double executionCreditRate = 1.0,
    String federationId = 'default',
    ImmutableAuditLedger? ledger,
  })  : _taxRate = taxRate,
        _executionCreditRate = executionCreditRate,
        _treasury = FederationTreasury(federationId: federationId),
        _ledger = ledger;

  double get taxRate => _taxRate;
  FederationTreasury get treasury => _treasury;
  Map<String, ExecutionCredits> get accounts => Map.unmodifiable(_accounts);

  ExecutionCredits accountFor(String entityId) =>
      _accounts[entityId] ?? ExecutionCredits(
        entityId: entityId,
        balance: 100.0,
        earnedTotal: 100.0,
        spentTotal: 0,
        taxPaid: 0,
        lastUpdated: 0,
      );

  ExecutionCredits earn(String entityId, double amount, int timestamp) {
    final current = accountFor(entityId);
    final tax = amount * _taxRate;
    final net = amount - tax;

    _treasury.collectTax(entityId, tax, timestamp);

    final updated = current.copyWith(
      balance: current.balance + net,
      earnedTotal: current.earnedTotal + amount,
      taxPaid: current.taxPaid + tax,
      lastUpdated: timestamp,
    );
    _accounts[entityId] = updated;
    return updated;
  }

  ExecutionCredits? spend(String entityId, double amount, int timestamp) {
    final current = accountFor(entityId);
    if (current.balance < amount) return null;

    final updated = current.copyWith(
      balance: current.balance - amount,
      spentTotal: current.spentTotal + amount,
      lastUpdated: timestamp,
    );
    _accounts[entityId] = updated;
    return updated;
  }

  double executionCost(int tokens, int tasks, int streams) {
    return tokens * _executionCreditRate * 0.01 +
        tasks * _executionCreditRate * 1.0 +
        streams * _executionCreditRate * 0.5;
  }

  bool canAfford(String entityId, int tokens, int tasks, int streams) {
    final cost = executionCost(tokens, tasks, streams);
    return accountFor(entityId).balance >= cost;
  }

  ExecutionCredits? chargeExecution(String entityId, int tokens, int tasks, int streams, int timestamp) {
    final cost = executionCost(tokens, tasks, streams);
    return spend(entityId, cost, timestamp);
  }

  void imposePenalty(String entityId, double amount, String reason, int timestamp) {
    final current = accountFor(entityId);
    _treasury.imposePenalty(entityId, amount, reason, timestamp);

    final updated = current.copyWith(
      balance: (current.balance - amount).clamp(0, double.infinity),
      spentTotal: current.spentTotal + amount,
      lastUpdated: timestamp,
    );
    _accounts[entityId] = updated;
  }
}
