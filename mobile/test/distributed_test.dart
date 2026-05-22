import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/distributed/distributed_invariants.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/distributed/node_discovery.dart';
import 'package:omnivium/core/runtime/distributed/remote_capability_router.dart';
import 'package:omnivium/core/runtime/distributed/distributed_trace.dart';
import 'package:omnivium/core/runtime/distributed/session_lease_manager.dart';
import 'package:omnivium/core/runtime/distributed/distributed_runtime.dart';
import 'package:omnivium/core/runtime/distributed/vocabulary/node_descriptor.dart';
import 'package:omnivium/core/runtime/distributed/vocabulary/cluster_event.dart';
import 'package:omnivium/core/runtime/distributed/vocabulary/distributed_session_lease.dart';
import 'package:omnivium/core/runtime/distributed/vocabulary/remote_capability_binding.dart';
import 'package:omnivium/core/runtime/distributed/transport/runtime_transport.dart';

void main() {
  group('Distributed Invariants', () {
    test('all 7 invariants are defined', () {
      final invariants = DistributedInvariants.all();
      expect(invariants.length, 7);
    });

    test('message ordering is per-session', () {
      expect(
        DistributedInvariants.messageOrdering,
        MessageOrderingModel.perSessionOrdering,
      );
    });

    test('delivery semantics are differentiated by object type', () {
      expect(
        DistributedInvariants.capabilityInvokeDelivery,
        DeliveryGuarantee.atMostOnce,
      );
      expect(
        DistributedInvariants.eventPropagationDelivery,
        DeliveryGuarantee.atLeastOnce,
      );
      expect(
        DistributedInvariants.journalDelivery,
        DeliveryGuarantee.exactlyOnce,
      );
    });

    test('session ownership is single writer', () {
      expect(DistributedInvariants.sessionSingleWriter, isTrue);
    });

    test('capability consistency is eventually consistent', () {
      expect(
        DistributedInvariants.capabilityConsistency,
        CapabilityConsistencyModel.eventuallyConsistent,
      );
    });

    test('time authority is hybrid logical clock', () {
      expect(
        DistributedInvariants.timeAuthority,
        TimeAuthorityModel.hybridLogicalClock,
      );
    });

    test('node failure is isolated', () {
      expect(DistributedInvariants.nodeFailureIsolated, isTrue);
    });

    test('network is hostile', () {
      expect(DistributedInvariants.networkIsHostile, isTrue);
    });

    test('each invariant has unique id', () {
      final invariants = DistributedInvariants.all();
      final ids = invariants.map((i) => i.id).toSet();
      expect(ids.length, 7);
    });
  });

  group('Hybrid Logical Clock', () {
    test('tick produces monotonically increasing timestamps', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final t1 = clock.tick();
      final t2 = clock.tick();
      final t3 = clock.tick();

      expect(t2.isAfter(t1), isTrue);
      expect(t3.isAfter(t2), isTrue);
    });

    test('receive handles remote timestamp correctly', () {
      final clockA = HybridLogicalClock(nodeId: 'node-A');
      final clockB = HybridLogicalClock(nodeId: 'node-B');

      final tA1 = clockA.tick();
      final tB1 = clockB.receive(tA1);

      expect(tB1.isAfter(tA1), isTrue);
    });

    test('concurrent events are detected', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final tA = HybridTimestamp(
        physicalTime: now,
        logicalTime: 1,
        nodeId: 'node-A',
      );
      final tB = HybridTimestamp(
        physicalTime: now,
        logicalTime: 1,
        nodeId: 'node-B',
      );

      final isConcurrent = tA.isConcurrentWith(tB) || tB.isConcurrentWith(tA);
      expect(isConcurrent, isTrue);
    });

    test('causality is preserved across nodes', () {
      final clockA = HybridLogicalClock(nodeId: 'node-A');
      final clockB = HybridLogicalClock(nodeId: 'node-B');

      final tA1 = clockA.tick();
      final tB1 = clockB.receive(tA1);
      final tA2 = clockA.receive(tB1);

      expect(tA2.isAfter(tA1), isTrue);
      expect(tA2.isAfter(tB1), isTrue);
    });

    test('timestamp serialization round-trip', () {
      final clock = HybridLogicalClock(nodeId: 'node-X');
      final ts = clock.tick();
      final json = ts.toJson();
      final restored = HybridTimestamp.fromJson(json);

      expect(restored.physicalTime, ts.physicalTime);
      expect(restored.logicalTime, ts.logicalTime);
      expect(restored.nodeId, ts.nodeId);
    });

    test('happens-before relation', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final t1 = clock.tick();
      final t2 = clock.tick();

      expect(t1.happensBefore(t2), isTrue);
      expect(t2.happensBefore(t1), isFalse);
    });
  });

  group('Node Descriptor', () {
    test('create and serialize', () {
      final node = NodeDescriptor(
        nodeId: 'tokyo-01',
        address: '192.168.1.10',
        port: 8080,
        role: NodeRole.primary,
        state: NodeState.alive,
      );

      expect(node.isAlive, isTrue);
      expect(node.addressKey, '192.168.1.10:8080');

      final json = node.toJson();
      final restored = NodeDescriptor.fromJson(json);
      expect(restored.nodeId, 'tokyo-01');
      expect(restored.role, NodeRole.primary);
    });

    test('state transitions', () {
      var node = NodeDescriptor(
        nodeId: 'edge-us',
        address: '10.0.0.1',
        state: NodeState.joining,
      );

      expect(node.isAlive, isFalse);

      node = node.copyWith(state: NodeState.alive);
      expect(node.isAlive, isTrue);

      node = node.copyWith(state: NodeState.suspect);
      expect(node.isSuspect, isTrue);

      node = node.copyWith(state: NodeState.dead);
      expect(node.isDead, isTrue);
    });
  });

  group('Node Discovery', () {
    test('join and list alive nodes', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final discovery = NodeDiscovery(localNodeId: 'local', clock: clock);

      discovery.join(
        NodeDescriptor(
          nodeId: 'node-A',
          address: '10.0.0.1',
          state: NodeState.alive,
        ),
      );

      discovery.join(
        NodeDescriptor(
          nodeId: 'node-B',
          address: '10.0.0.2',
          state: NodeState.alive,
        ),
      );

      expect(discovery.aliveCount, 2);
      expect(discovery.isAlive('node-A'), isTrue);
    });

    test('leave removes node', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final discovery = NodeDiscovery(localNodeId: 'local', clock: clock);

      discovery.join(
        NodeDescriptor(
          nodeId: 'node-A',
          address: '10.0.0.1',
          state: NodeState.alive,
        ),
      );

      expect(discovery.aliveCount, 1);
      discovery.leave('node-A');
      expect(discovery.aliveCount, 0);
    });

    test('suspect and dead transitions', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final discovery = NodeDiscovery(localNodeId: 'local', clock: clock);

      discovery.join(
        NodeDescriptor(
          nodeId: 'node-A',
          address: '10.0.0.1',
          state: NodeState.alive,
        ),
      );

      discovery.markSuspect('node-A');
      expect(discovery.get('node-A')!.state, NodeState.suspect);

      discovery.markDead('node-A');
      expect(discovery.get('node-A')!.state, NodeState.dead);
    });

    test('gossip target selection respects fanout', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final discovery = NodeDiscovery(
        localNodeId: 'local',
        clock: clock,
        config: const GossipConfig(gossipFanout: 2),
      );

      for (var i = 0; i < 5; i++) {
        discovery.join(
          NodeDescriptor(
            nodeId: 'node-$i',
            address: '10.0.0.$i',
            state: NodeState.alive,
          ),
        );
      }

      final targets = discovery.selectGossipTargets();
      expect(targets.length, lessThanOrEqualTo(2));
      expect(targets.any((t) => t.nodeId == 'local'), isFalse);
    });

    test('receive gossip propagates node joins', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final discovery = NodeDiscovery(localNodeId: 'local', clock: clock);

      discovery.receiveGossip([
        ClusterEvent(
          id: 'ce-1',
          type: ClusterEventType.nodeJoined,
          sourceNodeId: 'remote-1',
          timestamp: clock.tick().physicalTime,
          payload: {
            'nodeId': 'node-X',
            'address': '10.0.0.99',
            'role': 'worker',
            'incarnation': 0,
          },
        ),
      ]);

      expect(discovery.isAlive('node-X'), isTrue);
    });

    test('duplicate join with lower incarnation is ignored', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final discovery = NodeDiscovery(localNodeId: 'local', clock: clock);

      discovery.join(
        NodeDescriptor(
          nodeId: 'node-A',
          address: '10.0.0.1',
          state: NodeState.alive,
          incarnation: 5,
        ),
      );

      discovery.join(
        NodeDescriptor(
          nodeId: 'node-A',
          address: '10.0.0.1',
          state: NodeState.alive,
          incarnation: 3,
        ),
      );

      expect(discovery.get('node-A')!.incarnation, 5);
    });

    test('event queue drains correctly', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final discovery = NodeDiscovery(localNodeId: 'local', clock: clock);

      discovery.join(
        NodeDescriptor(
          nodeId: 'n1',
          address: '10.0.0.1',
          state: NodeState.alive,
        ),
      );
      discovery.join(
        NodeDescriptor(
          nodeId: 'n2',
          address: '10.0.0.2',
          state: NodeState.alive,
        ),
      );

      final events = discovery.drainEvents();
      expect(events.length, greaterThanOrEqualTo(2));
      expect(discovery.pendingEvents, isEmpty);
    });
  });

  group('Remote Capability Router', () {
    test('local capability routes locally', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final router = RemoteCapabilityRouter(localNodeId: 'local', clock: clock);

      router.registerLocalCapability('storage.read');

      final result = router.route('storage.read');
      expect(result.isLocal, isTrue);
      expect(result.decision, RouteDecision.local);
    });

    test('unknown capability is unavailable', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final router = RemoteCapabilityRouter(localNodeId: 'local', clock: clock);

      final result = router.route('nonexistent.cap');
      expect(result.decision, RouteDecision.unavailable);
    });

    test('remote capability routes remotely', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final router = RemoteCapabilityRouter(localNodeId: 'local', clock: clock);

      router.receiveAdvertisement(
        CapabilityAdvertisement(
          nodeId: 'remote-1',
          capabilityIds: ['agent.chat', 'agent.execute'],
          pluginId: 'agent-plugin',
          timestamp: clock.tick().physicalTime,
        ),
      );

      final result = router.route('agent.chat');
      expect(result.isRemote, isTrue);
      expect(result.targetNodeId, 'remote-1');
    });

    test('fallback routing works', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final router = RemoteCapabilityRouter(localNodeId: 'local', clock: clock);

      router.registerLocalCapability('storage.read');

      final result = router.routeWithFallback('storage.write', [
        'storage.read',
      ]);
      expect(result.decision, RouteDecision.fallback);
      expect(result.capabilityId, 'storage.read');
    });

    test('withdraw node removes its capabilities', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final router = RemoteCapabilityRouter(localNodeId: 'local', clock: clock);

      router.receiveAdvertisement(
        CapabilityAdvertisement(
          nodeId: 'remote-1',
          capabilityIds: ['agent.chat'],
          pluginId: 'agent',
          timestamp: clock.tick().physicalTime,
        ),
      );

      expect(router.route('agent.chat').isRemote, isTrue);

      router.withdrawNodeCapabilities('remote-1');
      expect(router.route('agent.chat').decision, RouteDecision.unavailable);
    });

    test('create advertisement for local capabilities', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final router = RemoteCapabilityRouter(localNodeId: 'local', clock: clock);

      router.registerLocalCapabilities(['storage.read', 'storage.write']);

      final ad = router.createAdvertisement('storage', [
        'storage.read',
        'storage.write',
      ]);
      expect(ad.nodeId, 'local');
      expect(ad.capabilityIds, ['storage.read', 'storage.write']);
    });

    test('mark capability unreachable', () {
      final clock = HybridLogicalClock(nodeId: 'local');
      final router = RemoteCapabilityRouter(localNodeId: 'local', clock: clock);

      router.receiveAdvertisement(
        CapabilityAdvertisement(
          nodeId: 'remote-1',
          capabilityIds: ['agent.chat'],
          pluginId: 'agent',
          timestamp: clock.tick().physicalTime,
        ),
      );

      router.markCapabilityUnreachable('agent.chat');
      final binding = router.remoteBindings.first;
      expect(binding.state, BindingState.unreachable);
    });
  });

  group('Distributed Session Lease', () {
    test('acquire lease', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = SessionLeaseManager(localNodeId: 'node-A', clock: clock);

      final lease = manager.acquire('session-1');
      expect(lease.isActive, isTrue);
      expect(lease.ownerNodeId, 'node-A');
    });

    test('single writer: same node re-acquire returns existing lease', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = SessionLeaseManager(localNodeId: 'node-A', clock: clock);

      final lease1 = manager.acquire('session-1');
      final lease2 = manager.acquire('session-1');

      expect(lease1.ownerNodeId, lease2.ownerNodeId);
      expect(lease1.sessionId, lease2.sessionId);
    });

    test('single writer: cannot write after release', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = SessionLeaseManager(localNodeId: 'node-A', clock: clock);

      manager.acquire('session-1');
      manager.release('session-1');

      expect(manager.canWrite('session-1'), isFalse);
    });

    test('released session can be re-acquired', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = SessionLeaseManager(localNodeId: 'node-A', clock: clock);

      manager.acquire('session-1');
      manager.release('session-1');

      final newLease = manager.tryAcquire('session-1');
      expect(newLease, isNotNull);
      expect(newLease!.isActive, isTrue);
    });

    test('renew lease extends expiry', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = SessionLeaseManager(localNodeId: 'node-A', clock: clock);

      final lease = manager.acquire('session-1');
      final originalExpiry = lease.expiresAt;

      final renewed = manager.renew('session-1');
      expect(renewed, isTrue);
      expect(
        manager.activeLeases.first.expiresAt,
        greaterThanOrEqualTo(originalExpiry),
      );
    });

    test('release lease', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = SessionLeaseManager(localNodeId: 'node-A', clock: clock);

      manager.acquire('session-1');
      expect(manager.release('session-1'), isTrue);
      expect(manager.canWrite('session-1'), isFalse);
    });

    test('lease expiry detection', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = SessionLeaseManager(
        localNodeId: 'node-A',
        clock: clock,
        config: const LeaseConfig(defaultTtl: Duration(milliseconds: 50)),
      );

      manager.acquire('session-1');

      Future.delayed(const Duration(milliseconds: 100), () {
        manager.tickExpiry();
        expect(manager.canWrite('session-1'), isFalse);
      });
    });

    test('tryAcquire returns null for owned session', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = SessionLeaseManager(localNodeId: 'node-A', clock: clock);

      manager.acquire('session-1');
      final result = manager.tryAcquire('session-1');
      expect(result, isNotNull);
    });

    test('revoke lease by another node', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = SessionLeaseManager(localNodeId: 'node-A', clock: clock);

      manager.acquire('session-1');
      expect(manager.revoke('session-1', 'node-B'), isTrue);
      expect(manager.canWrite('session-1'), isFalse);
    });

    test('lease serialization round-trip', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final now = clock.tick().physicalTime;
      final lease = DistributedSessionLease(
        sessionId: 's-1',
        ownerNodeId: 'node-A',
        acquiredAt: now,
        expiresAt: now + 30000,
      );

      final json = lease.toJson();
      final restored = DistributedSessionLease.fromJson(json);
      expect(restored.sessionId, 's-1');
      expect(restored.ownerNodeId, 'node-A');
      expect(restored.state, LeaseState.active);
    });
  });

  group('Distributed Trace', () {
    test('start trace and span', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final service = DistributedTraceService(
        localNodeId: 'node-A',
        clock: clock,
      );

      final trace = service.startTrace();
      final span = service.startSpan(
        traceId: trace.traceId,
        operation: 'capability.invoke',
      );

      expect(span.nodeId, 'node-A');
      expect(span.traceId, trace.traceId);
    });

    test('cross-node trace propagation', () {
      final clockA = HybridLogicalClock(nodeId: 'node-A');
      final serviceA = DistributedTraceService(
        localNodeId: 'node-A',
        clock: clockA,
      );

      final trace = serviceA.startTrace();
      final span = serviceA.startSpan(
        traceId: trace.traceId,
        operation: 'remote.invoke',
      );

      final context = serviceA.propagateContext(span);

      expect(context.traceId, trace.traceId);
      expect(context.originNodeId, 'node-A');
      expect(context.parentSpanId, span.spanId);
    });

    test('receive remote span and correlate', () {
      final clockA = HybridLogicalClock(nodeId: 'node-A');
      final serviceA = DistributedTraceService(
        localNodeId: 'node-A',
        clock: clockA,
      );

      final trace = serviceA.startTrace();
      final spanA = serviceA.startSpan(
        traceId: trace.traceId,
        operation: 'invoke.remote',
      );

      final context = serviceA.propagateContext(spanA);

      final clockB = HybridLogicalClock(nodeId: 'node-B');
      final serviceB = DistributedTraceService(
        localNodeId: 'node-B',
        clock: clockB,
      );

      final spanB = serviceB.startRemoteSpan(
        context,
        operation: 'handle.remote',
      );

      expect(spanB.remoteParentSpanId, spanA.spanId);
      expect(spanB.remoteNodeId, 'node-A');
      expect(spanB.isCrossNode, isTrue);
    });

    test('trace propagation context from headers', () {
      final context = TracePropagationContext(
        traceId: 'trace-123',
        parentSpanId: 'span-456',
        originNodeId: 'node-A',
        hlcTime: 1000,
        baggage: {'env': 'test'},
      );

      final headers = context.toHeaders();
      expect(headers['x-trace-id'], 'trace-123');
      expect(headers['x-origin-node'], 'node-A');
      expect(headers['x-baggage-env'], 'test');

      final restored = TracePropagationContext.fromHeaders(headers);
      expect(restored.traceId, 'trace-123');
      expect(restored.parentSpanId, 'span-456');
      expect(restored.baggage['env'], 'test');
    });

    test('receive remote spans merges into trace', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final service = DistributedTraceService(
        localNodeId: 'node-A',
        clock: clock,
      );

      service.startTrace(traceId: 'trace-1');

      final remoteSpans = [
        DistributedSpan(
          spanId: 'remote-span-1',
          traceId: 'trace-1',
          operation: 'remote.work',
          nodeId: 'node-B',
          startTimeHlc: clock.tick().physicalTime,
        ),
      ];

      service.receiveRemoteSpans('trace-1', remoteSpans);

      final merged = service.getTrace('trace-1');
      expect(merged, isNotNull);
      expect(merged!.spans.length, greaterThanOrEqualTo(1));
      expect(merged.involvedNodes, contains('node-B'));
    });
  });

  group('Local Transport', () {
    test('connect and disconnect', () async {
      final transport = LocalTransport(localNodeId: 'node-A');

      expect(transport.state, TransportState.disconnected);

      await transport.connect();
      expect(transport.state, TransportState.connected);

      await transport.disconnect();
      expect(transport.state, TransportState.disconnected);
    });

    test('health check', () async {
      final transport = LocalTransport(localNodeId: 'node-A');

      expect(await transport.healthCheck(), isFalse);

      await transport.connect();
      expect(await transport.healthCheck(), isTrue);
    });

    test('state change callback', () async {
      final transport = LocalTransport(localNodeId: 'node-A');
      final states = <TransportState>[];

      transport.onStateChange((prev, curr) => states.add(curr));

      await transport.connect();
      await transport.disconnect();

      expect(states, [TransportState.connected, TransportState.disconnected]);
    });

    test('send throws when disconnected', () async {
      final transport = LocalTransport(localNodeId: 'node-A');

      expect(
        () => transport.send(
          TransportMessage(
            id: 'msg-1',
            type: 'test',
            sourceNodeId: 'node-A',
            targetNodeId: 'node-B',
            timestamp: HybridTimestampLike(physicalTime: 0),
          ),
        ),
        throwsStateError,
      );
    });
  });

  group('Transport Registry', () {
    test('register and retrieve transport', () async {
      final registry = TransportRegistry();
      final local = LocalTransport(localNodeId: 'node-A');

      registry.register(TransportType.local, local);

      expect(registry.get(TransportType.local), local);
      expect(registry.availableTypes, [TransportType.local]);
    });

    test('connect all transports', () async {
      final registry = TransportRegistry();
      final local = LocalTransport(localNodeId: 'node-A');

      registry.register(TransportType.local, local);
      await registry.connectAll();

      expect(local.state, TransportState.connected);
    });
  });

  group('Cluster Event', () {
    test('serialization round-trip', () {
      final event = ClusterEvent(
        id: 'ce-1',
        type: ClusterEventType.nodeJoined,
        sourceNodeId: 'node-A',
        timestamp: 1000,
        hlcTime: 1001,
        payload: {'role': 'primary'},
      );

      final json = event.toJson();
      final restored = ClusterEvent.fromJson(json);

      expect(restored.id, 'ce-1');
      expect(restored.type, ClusterEventType.nodeJoined);
      expect(restored.sourceNodeId, 'node-A');
    });
  });

  group('Distributed Runtime Integration', () {
    test('start and stop lifecycle', () async {
      final runtime = DistributedRuntime(
        const DistributedRuntimeConfig(
          nodeId: 'test-node',
          address: '127.0.0.1',
        ),
      );

      expect(runtime.state, DistributedRuntimeState.uninitialized);

      await runtime.start();
      expect(runtime.state, DistributedRuntimeState.running);

      await runtime.stop();
      expect(runtime.state, DistributedRuntimeState.stopped);

      runtime.dispose();
    });

    test('register local capabilities', () async {
      final runtime = DistributedRuntime(
        const DistributedRuntimeConfig(nodeId: 'test-node'),
      );

      await runtime.start();

      runtime.registerLocalCapabilities('storage', [
        'storage.read',
        'storage.write',
      ]);

      expect(runtime.capabilityRouter.localCapabilityCount, 2);

      final route = runtime.capabilityRouter.route('storage.read');
      expect(route.isLocal, isTrue);

      await runtime.stop();
      runtime.dispose();
    });

    test('node failure handling', () async {
      final runtime = DistributedRuntime(
        const DistributedRuntimeConfig(nodeId: 'test-node'),
      );

      await runtime.start();

      runtime.nodeDiscovery.join(
        NodeDescriptor(
          nodeId: 'remote-1',
          address: '10.0.0.1',
          state: NodeState.alive,
        ),
      );

      runtime.capabilityRouter.receiveAdvertisement(
        CapabilityAdvertisement(
          nodeId: 'remote-1',
          capabilityIds: ['agent.chat'],
          pluginId: 'agent',
          timestamp: runtime.clock.tick().physicalTime,
        ),
      );

      expect(runtime.capabilityRouter.route('agent.chat').isRemote, isTrue);

      runtime.handleNodeFailure('remote-1');

      expect(
        runtime.capabilityRouter.route('agent.chat').decision,
        RouteDecision.unavailable,
      );

      await runtime.stop();
      runtime.dispose();
    });

    test('partition detection and healing', () async {
      final runtime = DistributedRuntime(
        const DistributedRuntimeConfig(nodeId: 'test-node'),
      );

      await runtime.start();

      runtime.nodeDiscovery.join(
        NodeDescriptor(
          nodeId: 'remote-1',
          address: '10.0.0.1',
          state: NodeState.alive,
        ),
      );

      runtime.handlePartitionDetected({'remote-1'});
      expect(runtime.nodeDiscovery.get('remote-1')!.state, NodeState.suspect);

      runtime.handlePartitionHealed({'remote-1'});
      expect(runtime.nodeDiscovery.get('remote-1')!.state, NodeState.alive);

      await runtime.stop();
      runtime.dispose();
    });

    test('session lease management in distributed context', () async {
      final runtime = DistributedRuntime(
        const DistributedRuntimeConfig(nodeId: 'test-node'),
      );

      await runtime.start();

      final lease = runtime.leaseManager.acquire('session-1');
      expect(lease.ownerNodeId, 'test-node');
      expect(runtime.leaseManager.canWrite('session-1'), isTrue);

      runtime.leaseManager.release('session-1');
      expect(runtime.leaseManager.canWrite('session-1'), isFalse);

      await runtime.stop();
      runtime.dispose();
    });

    test('distributed trace across operations', () async {
      final runtime = DistributedRuntime(
        const DistributedRuntimeConfig(nodeId: 'test-node'),
      );

      await runtime.start();

      final trace = runtime.traceService.startTrace(
        tags: {'operation': 'distributed.invoke'},
      );
      final span = runtime.traceService.startSpan(
        traceId: trace.traceId,
        operation: 'capability.invoke',
        pluginId: 'storage',
        capabilityId: 'storage.read',
      );

      runtime.traceService.finishSpan(span);

      final retrieved = runtime.traceService.getTrace(trace.traceId);
      expect(retrieved, isNotNull);
      expect(retrieved!.spans.length, 1);

      await runtime.stop();
      runtime.dispose();
    });
  });
}
