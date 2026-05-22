import 'hybrid_logical_clock.dart';
import 'node_discovery.dart';
import 'remote_capability_router.dart';
import 'distributed_trace.dart';
import 'session_lease_manager.dart';
import 'vocabulary/node_descriptor.dart';
import 'transport/runtime_transport.dart';
import '../plugin/plugin_handler.dart';

class DistributedRuntimeConfig {
  final String nodeId;
  final String address;
  final int port;
  final NodeRole role;
  final GossipConfig gossipConfig;
  final LeaseConfig leaseConfig;

  const DistributedRuntimeConfig({
    this.nodeId = 'node-0',
    this.address = '127.0.0.1',
    this.port = 8080,
    this.role = NodeRole.primary,
    this.gossipConfig = const GossipConfig(),
    this.leaseConfig = const LeaseConfig(),
  });
}

class DistributedRuntime {
  final DistributedRuntimeConfig _config;
  final HybridLogicalClock _clock;
  final NodeDiscovery _nodeDiscovery;
  final RemoteCapabilityRouter _capabilityRouter;
  final DistributedTraceService _traceService;
  final SessionLeaseManager _leaseManager;
  final TransportRegistry _transportRegistry;

  DistributedRuntimeState _state = DistributedRuntimeState.uninitialized;

  DistributedRuntime(this._config)
    : _clock = HybridLogicalClock(nodeId: _config.nodeId),
      _nodeDiscovery = NodeDiscovery(
        localNodeId: _config.nodeId,
        clock: HybridLogicalClock(nodeId: _config.nodeId),
        config: _config.gossipConfig,
      ),
      _capabilityRouter = RemoteCapabilityRouter(
        localNodeId: _config.nodeId,
        clock: HybridLogicalClock(nodeId: _config.nodeId),
      ),
      _traceService = DistributedTraceService(
        localNodeId: _config.nodeId,
        clock: HybridLogicalClock(nodeId: _config.nodeId),
      ),
      _leaseManager = SessionLeaseManager(
        localNodeId: _config.nodeId,
        clock: HybridLogicalClock(nodeId: _config.nodeId),
        config: _config.leaseConfig,
      ),
      _transportRegistry = TransportRegistry();

  DistributedRuntimeState get state => _state;
  HybridLogicalClock get clock => _clock;
  NodeDiscovery get nodeDiscovery => _nodeDiscovery;
  RemoteCapabilityRouter get capabilityRouter => _capabilityRouter;
  DistributedTraceService get traceService => _traceService;
  SessionLeaseManager get leaseManager => _leaseManager;
  TransportRegistry get transportRegistry => _transportRegistry;
  String get nodeId => _config.nodeId;
  DistributedRuntimeConfig get config => _config;

  Future<void> start() async {
    if (_state == DistributedRuntimeState.running) return;

    _state = DistributedRuntimeState.starting;

    _nodeDiscovery.join(
      NodeDescriptor(
        nodeId: _config.nodeId,
        address: _config.address,
        port: _config.port,
        role: _config.role,
        state: NodeState.alive,
        joinedAt: _clock.tick().physicalTime,
        lastHeartbeatAt: _clock.tick().physicalTime,
      ),
    );

    _nodeDiscovery.startProbing();

    _state = DistributedRuntimeState.running;
  }

  Future<void> stop() async {
    if (_state != DistributedRuntimeState.running) return;

    _state = DistributedRuntimeState.stopping;

    _nodeDiscovery.stopProbing();
    _nodeDiscovery.leave(_config.nodeId);
    await _transportRegistry.disconnectAll();

    _state = DistributedRuntimeState.stopped;
  }

  void registerTransport(TransportType type, RuntimeTransport transport) {
    _transportRegistry.register(type, transport);
    if (type == TransportType.local) {
      _capabilityRouter.setTransport(transport);
    }
  }

  void registerLocalCapabilities(String pluginId, List<String> capabilityIds) {
    _capabilityRouter.registerLocalCapabilities(capabilityIds);
  }

  Future<void> joinCluster(NodeDescriptor seedNode) async {
    _nodeDiscovery.join(seedNode);
  }

  void handleNodeFailure(String nodeId) {
    _capabilityRouter.withdrawNodeCapabilities(nodeId);
    _nodeDiscovery.markDead(nodeId);
  }

  void handlePartitionDetected(Set<String> unreachableNodes) {
    for (final nodeId in unreachableNodes) {
      _nodeDiscovery.markSuspect(nodeId);
      _capabilityRouter.withdrawNodeCapabilities(nodeId);
    }
  }

  void handlePartitionHealed(Set<String> recoveredNodes) {
    for (final nodeId in recoveredNodes) {
      _nodeDiscovery.markAlive(nodeId);
    }
  }

  void tick() {
    _leaseManager.tickExpiry();
    _leaseManager.reclaimExpiredLeases();
    _nodeDiscovery.updateSelf();
  }

  Future<CapabilityResult> sendAndReceive({
    required String capabilityId,
    required String targetNodeId,
    dynamic params,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final transport = _transportRegistry.defaultTransport;
    if (transport == null || transport.state != TransportState.connected) {
      return CapabilityResult.fail(
        RuntimeError.unavailable(
          message: 'No transport available for remote invocation',
        ),
      );
    }

    final transportMessage = TransportMessage(
      id: 'remote_${_clock.now.physicalTime}',
      type: 'capability.invoke',
      sourceNodeId: _config.nodeId,
      targetNodeId: targetNodeId,
      payload: {'capabilityId': capabilityId, 'params': params},
      timestamp: HybridTimestampLike(
        physicalTime: _clock.now.physicalTime,
        logicalTime: _clock.now.logicalTime,
        nodeId: _config.nodeId,
      ),
    );

    final response = await transport.requestResponse(
      transportMessage,
      timeout: timeout,
    );
    if (response == null) {
      return CapabilityResult.fail(
        RuntimeError.unavailable(
          message: 'No response from $targetNodeId within timeout',
        ),
      );
    }

    final payload = response.payload;
    if (payload.containsKey('error')) {
      return CapabilityResult.fail(
        RuntimeError(
          code: payload['error']['code'] ?? 'REMOTE_ERROR',
          message: payload['error']['message'] ?? 'Remote invocation failed',
        ),
      );
    }

    return CapabilityResult.ok(payload);
  }

  void dispose() {
    _nodeDiscovery.dispose();
  }
}

enum DistributedRuntimeState {
  uninitialized,
  starting,
  running,
  stopping,
  stopped,
}
