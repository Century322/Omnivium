import 'dart:async';
import 'dart:math';
import 'vocabulary/node_descriptor.dart';
import 'vocabulary/cluster_event.dart';
import 'hybrid_logical_clock.dart';

class GossipConfig {
  final Duration probeInterval;
  final Duration suspicionTimeout;
  final Duration deadNodeTimeout;
  final int gossipFanout;
  final int maxPiggybackEvents;

  const GossipConfig({
    this.probeInterval = const Duration(seconds: 1),
    this.suspicionTimeout = const Duration(seconds: 5),
    this.deadNodeTimeout = const Duration(seconds: 15),
    this.gossipFanout = 3,
    this.maxPiggybackEvents = 10,
  });
}

class NodeDiscovery {
  final String _localNodeId;
  final Map<String, NodeDescriptor> _members = {};
  final List<ClusterEvent> _eventQueue = [];
  final StreamController<ClusterEvent> _eventController =
      StreamController<ClusterEvent>.broadcast();
  final HybridLogicalClock _clock;
  final GossipConfig _config;
  final Random _random = Random();
  Timer? _probeTimer;
  int _eventSeq = 0;

  NodeDiscovery({
    required String localNodeId,
    required HybridLogicalClock clock,
    GossipConfig config = const GossipConfig(),
  }) : _localNodeId = localNodeId,
       _clock = clock,
       _config = config;

  String get localNodeId => _localNodeId;
  List<NodeDescriptor> get aliveNodes =>
      _members.values.where((n) => n.isAlive).toList();
  List<NodeDescriptor> get allNodes => _members.values.toList();
  int get memberCount => _members.length;
  int get aliveCount => aliveNodes.length;
  Stream<ClusterEvent> get events => _eventController.stream;
  List<ClusterEvent> get pendingEvents => List.unmodifiable(_eventQueue);

  NodeDescriptor? get(String nodeId) => _members[nodeId];

  bool isAlive(String nodeId) {
    final node = _members[nodeId];
    return node != null && node.isAlive;
  }

  void join(NodeDescriptor descriptor) {
    final existing = _members[descriptor.nodeId];
    if (existing != null && existing.incarnation >= descriptor.incarnation)
      return;

    _members[descriptor.nodeId] = descriptor;
    _emitEvent(ClusterEventType.nodeJoined, descriptor.nodeId, {
      'role': descriptor.role.name,
      'address': descriptor.addressKey,
      'incarnation': descriptor.incarnation,
    });
  }

  void leave(String nodeId) {
    final node = _members[nodeId];
    if (node == null) return;

    _members[nodeId] = node.copyWith(state: NodeState.left);
    _emitEvent(ClusterEventType.nodeLeft, nodeId, {
      'incarnation': node.incarnation,
    });
    _members.remove(nodeId);
  }

  void markSuspect(String nodeId) {
    final node = _members[nodeId];
    if (node == null || node.state != NodeState.alive) return;

    _members[nodeId] = node.copyWith(state: NodeState.suspect);
    _emitEvent(ClusterEventType.nodeSuspect, nodeId, {
      'incarnation': node.incarnation,
    });
  }

  void markAlive(String nodeId) {
    final node = _members[nodeId];
    if (node == null) return;

    final now = _clock.tick();
    _members[nodeId] = node.copyWith(
      state: NodeState.alive,
      incarnation: node.incarnation + 1,
      lastHeartbeatAt: now.physicalTime);
    _emitEvent(ClusterEventType.nodeAlive, nodeId, {
      'incarnation': node.incarnation + 1,
    });
  }

  void markDead(String nodeId) {
    final node = _members[nodeId];
    if (node == null) return;

    _members[nodeId] = node.copyWith(state: NodeState.dead);
    _emitEvent(ClusterEventType.nodeDead, nodeId, {
      'incarnation': node.incarnation,
    });
  }

  void heartbeat(String nodeId) {
    final node = _members[nodeId];
    if (node == null) return;

    final now = _clock.tick();
    if (node.state == NodeState.suspect) {
      markAlive(nodeId);
      return;
    }

    _members[nodeId] = node.copyWith(lastHeartbeatAt: now.physicalTime);
  }

  void updateSelf() {
    final self = _members[_localNodeId];
    if (self == null) return;

    final now = _clock.tick();
    _members[_localNodeId] = self.copyWith(
      state: NodeState.alive,
      lastHeartbeatAt: now.physicalTime,
      incarnation: self.incarnation + 1);
  }

  List<NodeDescriptor> selectGossipTargets() {
    final alive = aliveNodes.where((n) => n.nodeId != _localNodeId).toList();
    if (alive.isEmpty) return [];

    final fanout = _config.gossipFanout.clamp(1, alive.length);
    final shuffled = List<NodeDescriptor>.from(alive)..shuffle(_random);
    return shuffled.take(fanout).toList();
  }

  List<ClusterEvent> drainEvents() {
    final events = List<ClusterEvent>.from(_eventQueue);
    _eventQueue.clear();
    return events;
  }

  void receiveGossip(List<ClusterEvent> remoteEvents) {
    for (final event in remoteEvents) {
      _clock.receive(
        HybridTimestamp(
          physicalTime: event.hlcTime,
          nodeId: event.sourceNodeId));

      switch (event.type) {
        case ClusterEventType.nodeJoined:
          final nodeId =
              event.payload['nodeId'] as String? ?? event.sourceNodeId;
          if (!_members.containsKey(nodeId)) {
            join(
              NodeDescriptor(
                nodeId: nodeId,
                address: event.payload['address'] as String? ?? '',
                role: NodeRole.values.firstWhere(
                  (r) => r.name == event.payload['role'],
                  orElse: () => NodeRole.worker),
                state: NodeState.alive,
                incarnation: event.payload['incarnation'] as int? ?? 0,
                joinedAt: event.timestamp,
                lastHeartbeatAt: event.timestamp));
          }
          break;
        case ClusterEventType.nodeLeft:
          leave(event.sourceNodeId);
          break;
        case ClusterEventType.nodeSuspect:
          markSuspect(event.payload['nodeId'] as String? ?? event.sourceNodeId);
          break;
        case ClusterEventType.nodeAlive:
          markAlive(event.payload['nodeId'] as String? ?? event.sourceNodeId);
          break;
        case ClusterEventType.nodeDead:
          markDead(event.payload['nodeId'] as String? ?? event.sourceNodeId);
          break;
        default:
          _eventController.add(event);
          break;
      }
    }
  }

  void startProbing() {
    _probeTimer?.cancel();
    _probeTimer = Timer.periodic(_config.probeInterval, (_) {
      _probeCycle();
    });
  }

  void stopProbing() {
    _probeTimer?.cancel();
    _probeTimer = null;
  }

  void _probeCycle() {
    final now = _clock.tick().physicalTime;

    for (final node in _members.values.toList()) {
      if (node.nodeId == _localNodeId) continue;

      if (node.state == NodeState.alive) {
        final elapsed = now - node.lastHeartbeatAt;
        if (elapsed > _config.suspicionTimeout.inMilliseconds) {
          markSuspect(node.nodeId);
        }
      } else if (node.state == NodeState.suspect) {
        final elapsed = now - node.lastHeartbeatAt;
        if (elapsed > _config.deadNodeTimeout.inMilliseconds) {
          markDead(node.nodeId);
        }
      }
    }

    updateSelf();
  }

  void _emitEvent(
    ClusterEventType type,
    String targetNodeId,
    Map<String, dynamic> extra) {
    final now = _clock.tick();
    final event = ClusterEvent(
      id: 'ce_${_eventSeq++}',
      type: type,
      sourceNodeId: _localNodeId,
      timestamp: now.physicalTime,
      hlcTime: now.physicalTime,
      payload: {'nodeId': targetNodeId, ...extra});

    _eventQueue.add(event);
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }

    if (_eventQueue.length > _config.maxPiggybackEvents * 2) {
      _eventQueue.removeRange(
        0,
        _eventQueue.length - _config.maxPiggybackEvents);
    }
  }

  void dispose() {
    _probeTimer?.cancel();
    _eventController.close();
  }
}
