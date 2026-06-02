import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/distributed/protocol/wire_protocol.dart';
import 'package:omnivium/core/runtime/distributed/protocol/protocol_handler.dart';
import 'package:omnivium/core/runtime/distributed/recovery/recovery_manager.dart';
import 'package:omnivium/core/runtime/distributed/persistence/write_ahead_log.dart';
import 'package:omnivium/core/runtime/distributed/lease/unified_lease.dart';
import 'package:omnivium/core/runtime/distributed/hybrid_logical_clock.dart';
import 'package:omnivium/core/runtime/distributed/session_lease_manager.dart'
    show SessionLeaseManager;

void main() {
  group('Wire Protocol', () {
    test('WireFrame creation and serialization', () {
      final frame = WireFrame(
        frameId: 1,
        type: FrameType.data,
        sourceNodeId: 'node-A',
        targetNodeId: 'node-B',
        hlcTime: 1000,
        sequence: 1,
        headers: {'messageType': 'capability.invoke'},
        payload: [1, 2, 3],
      );

      final json = frame.toJson();
      expect(json['type'], 'data');
      expect(json['src'], 'node-A');
      expect(json['dst'], 'node-B');
    });

    test('WireEnvelope chunking detection', () {
      final single = WireEnvelope(
        envelopeId: 'env-1',
        correlationId: 'corr-1',
        messageType: 'invoke',
        sourceNodeId: 'node-A',
        targetNodeId: 'node-B',
        payload: [1, 2, 3],
      );

      expect(single.isChunked, isFalse);
      expect(single.isFirstChunk, isTrue);
      expect(single.isLastChunk, isTrue);

      final chunked = WireEnvelope(
        envelopeId: 'env-2',
        correlationId: 'corr-2',
        messageType: 'invoke',
        sourceNodeId: 'node-A',
        targetNodeId: 'node-B',
        totalChunks: 3,
        chunkIndex: 1,
        payload: [4, 5, 6],
      );

      expect(chunked.isChunked, isTrue);
      expect(chunked.isFirstChunk, isFalse);
      expect(chunked.isLastChunk, isFalse);
    });

    test('AckFrame creation', () {
      final ack = AckFrame(
        ackFrameId: 2,
        originalFrameId: 1,
        sourceNodeId: 'node-B',
        success: true,
      );

      expect(ack.success, isTrue);
      expect(ack.originalFrameId, 1);
    });

    test('HeartbeatFrame creation', () {
      final hb = HeartbeatFrame(
        sourceNodeId: 'node-A',
        hlcTime: 1000,
        incarnation: 5,
      );

      expect(hb.sourceNodeId, 'node-A');
      expect(hb.incarnation, 5);
    });

    test('Handshake negotiation', () {
      final handshake = HandshakeFrame(
        sourceNodeId: 'node-A',
        protocolVersion: '1.0.0',
        authMethod: AuthMethod.token,
        authToken: 'secret',
        supportedCompression: CompressionType.gzip,
        maxFrameSize: 32768,
      );

      expect(handshake.authMethod, AuthMethod.token);
      expect(handshake.supportedCompression, CompressionType.gzip);
      expect(handshake.maxFrameSize, 32768);
    });

    test('NodeHealth enum values', () {
      expect(NodeHealth.values.length, 4);
      expect(NodeHealth.healthy.name, 'healthy');
      expect(NodeHealth.overloaded.name, 'overloaded');
    });
  });

  group('Protocol Handler', () {
    test('handshake flow', () {
      final clockA = HybridLogicalClock(nodeId: 'node-A');
      final clockB = HybridLogicalClock(nodeId: 'node-B');

      final handlerA = ProtocolHandler(
        localNodeId: 'node-A',
        clock: clockA,
        config: const WireProtocolConfig(
          authMethod: AuthMethod.token,
          authToken: 'secret',
        ),
      );

      final handlerB = ProtocolHandler(localNodeId: 'node-B', clock: clockB);

      final handshake = handlerA.createHandshake();
      expect(handlerA.state, ProtocolState.handshaking);

      final ack = handlerB.handleHandshake(handshake);
      expect(ack.accepted, isTrue);

      handlerA.completeHandshake(ack);
      expect(handlerA.state, ProtocolState.ready);
    });

    test('create data frame', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final handler = ProtocolHandler(localNodeId: 'node-A', clock: clock);

      handler.createHandshake();
      final handshakeAck = HandshakeAckFrame(
        sourceNodeId: 'node-B',
        accepted: true,
      );
      handler.completeHandshake(handshakeAck);

      final frame = handler.createDataFrame('node-B', 'capability.invoke', [
        1,
        2,
        3,
      ]);
      expect(frame.type, FrameType.data);
      expect(frame.sourceNodeId, 'node-A');
      expect(frame.targetNodeId, 'node-B');
    });

    test('create and verify ack', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final handler = ProtocolHandler(localNodeId: 'node-A', clock: clock);

      final frame = WireFrame(
        frameId: 42,
        type: FrameType.data,
        sourceNodeId: 'node-B',
        targetNodeId: 'node-A',
      );

      final ack = handler.createAck(frame, success: true);
      expect(ack.originalFrameId, 42);
      expect(ack.success, isTrue);
    });

    test('create envelope', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final handler = ProtocolHandler(localNodeId: 'node-A', clock: clock);

      final envelope = handler.createEnvelope(
        'node-B',
        'capability.invoke',
        [1, 2, 3],
        metadata: {'traceId': 'trace-1'},
      );

      expect(envelope.sourceNodeId, 'node-A');
      expect(envelope.targetNodeId, 'node-B');
      expect(envelope.messageType, 'capability.invoke');
    });

    test('chunk large envelope', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final handler = ProtocolHandler(
        localNodeId: 'node-A',
        clock: clock,
        config: const WireProtocolConfig(chunkSize: 10, maxFrameSize: 10),
      );

      handler.createHandshake();
      handler.completeHandshake(
        HandshakeAckFrame(
          sourceNodeId: 'node-B',
          accepted: true,
          negotiatedMaxFrameSize: 10,
        ),
      );

      final envelope = WireEnvelope(
        envelopeId: 'env-big',
        correlationId: 'corr-big',
        messageType: 'large.data',
        sourceNodeId: 'node-A',
        targetNodeId: 'node-B',
        payload: List.generate(50, (i) => i),
      );

      final chunks = handler.chunkEnvelope(envelope);
      expect(chunks.length, greaterThan(1));
      expect(chunks.first.isFirstChunk, isTrue);
      expect(chunks.last.isLastChunk, isTrue);
    });

    test('assemble chunks', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final handler = ProtocolHandler(
        localNodeId: 'node-A',
        clock: clock,
        config: const WireProtocolConfig(chunkSize: 10),
      );

      final chunks = [
        WireEnvelope(
          envelopeId: 'env-0',
          correlationId: 'corr-1',
          messageType: 'data',
          sourceNodeId: 'node-B',
          targetNodeId: 'node-A',
          totalChunks: 3,
          chunkIndex: 0,
          payload: [1, 2, 3],
          metadata: {'key': 'value'},
        ),
        WireEnvelope(
          envelopeId: 'env-1',
          correlationId: 'corr-1',
          messageType: 'data',
          sourceNodeId: 'node-B',
          targetNodeId: 'node-A',
          totalChunks: 3,
          chunkIndex: 1,
          payload: [4, 5, 6],
        ),
        WireEnvelope(
          envelopeId: 'env-2',
          correlationId: 'corr-1',
          messageType: 'data',
          sourceNodeId: 'node-B',
          targetNodeId: 'node-A',
          totalChunks: 3,
          chunkIndex: 2,
          payload: [7, 8, 9],
        ),
      ];

      for (final chunk in chunks) {
        handler.handleEnvelopeChunk(chunk);
      }

      expect(handler.pendingChunkCount, 0);
    });
  });

  group('Recovery Manager', () {
    test('detect node partition failure', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final leaseManager = SessionLeaseManager(
        localNodeId: 'node-A',
        clock: clock,
      );
      final recovery = RecoveryManager(
        localNodeId: 'node-A',
        clock: clock,
        leaseManager: leaseManager,
      );

      final failure = recovery.detectFailure(
        FailureType.nodePartition,
        'node-B',
      );
      expect(failure.type, FailureType.nodePartition);
      expect(recovery.failureCount, 1);
    });

    test('analyze node partition returns markNodeDead', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final leaseManager = SessionLeaseManager(
        localNodeId: 'node-A',
        clock: clock,
      );
      final recovery = RecoveryManager(
        localNodeId: 'node-A',
        clock: clock,
        leaseManager: leaseManager,
      );

      final failure = recovery.detectFailure(
        FailureType.nodePartition,
        'node-B',
      );
      final decision = recovery.analyze(failure);

      expect(decision.action, RecoveryAction.markNodeDead);
      expect(decision.needsAction, isTrue);
    });

    test('recover lease orphan', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final leaseManager = SessionLeaseManager(
        localNodeId: 'node-A',
        clock: clock,
      );
      final recovery = RecoveryManager(
        localNodeId: 'node-A',
        clock: clock,
        leaseManager: leaseManager,
      );

      leaseManager.acquire('session-1');

      final result = recovery.detectAndRecover(
        FailureType.leaseOrphan,
        'node-B',
        context: {'sessionId': 'session-1'},
      );

      expect(result.success, isTrue);
      expect(result.action, RecoveryAction.reclaimLease);
      expect(recovery.recoveryCount, 1);
    });

    test('replay duplication detection', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final leaseManager = SessionLeaseManager(
        localNodeId: 'node-A',
        clock: clock,
      );
      final recovery = RecoveryManager(
        localNodeId: 'node-A',
        clock: clock,
        leaseManager: leaseManager,
      );

      expect(recovery.isDuplicate('entry-1'), isFalse);
      expect(recovery.isDuplicate('entry-1'), isTrue);
      expect(recovery.isDuplicate('entry-2'), isFalse);
    });

    test('split brain resolution by incarnation', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final leaseManager = SessionLeaseManager(
        localNodeId: 'node-A',
        clock: clock,
      );
      final recovery = RecoveryManager(
        localNodeId: 'node-A',
        clock: clock,
        leaseManager: leaseManager,
      );

      final result = recovery.detectAndRecover(
        FailureType.splitBrain,
        'node-B',
        context: {
          'nodeA': 'tokyo-01',
          'nodeB': 'edge-us',
          'incarnationA': 10,
          'incarnationB': 5,
        },
      );

      expect(result.success, isTrue);
      expect(result.action, RecoveryAction.splitBrainResolve);
    });

    test('half-open session recovery', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final leaseManager = SessionLeaseManager(
        localNodeId: 'node-A',
        clock: clock,
      );
      final recovery = RecoveryManager(
        localNodeId: 'node-A',
        clock: clock,
        leaseManager: leaseManager,
      );

      leaseManager.acquire('session-1');

      final result = recovery.detectAndRecover(
        FailureType.halfOpenSession,
        'node-B',
        context: {'sessionId': 'session-1'},
      );

      expect(result.success, isTrue);
    });

    test('incarnation tracking', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final leaseManager = SessionLeaseManager(
        localNodeId: 'node-A',
        clock: clock,
      );
      final recovery = RecoveryManager(
        localNodeId: 'node-A',
        clock: clock,
        leaseManager: leaseManager,
      );

      recovery.updateIncarnation('node-B', 5);
      expect(recovery.lastKnownIncarnation('node-B'), 5);
      expect(recovery.lastKnownIncarnation('node-C'), isNull);
    });
  });

  group('Write-Ahead Log', () {
    test('append entries', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);

      wal.append(WalEntryType.sessionCreate, {'sessionId': 's-1'});
      wal.append(WalEntryType.pluginLoad, {'pluginId': 'storage'});

      expect(wal.entryCount, 2);
      expect(wal.currentLsn, 2);
    });

    test('transaction commit', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);

      final txId = wal.beginTransaction();
      wal.append(WalEntryType.sessionCreate, {
        'sessionId': 's-1',
      }, transactionId: txId);
      wal.append(WalEntryType.leaseAcquire, {
        'sessionId': 's-1',
      }, transactionId: txId);
      final committed = wal.commitTransaction(txId);

      expect(committed, isTrue);
      expect(wal.activeTransactionCount, 0);
    });

    test('transaction rollback', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);

      final txId = wal.beginTransaction();
      wal.append(WalEntryType.sessionCreate, {
        'sessionId': 's-1',
      }, transactionId: txId);
      final rolled = wal.rollbackTransaction(txId);

      expect(rolled, isTrue);
      expect(wal.activeTransactionCount, 0);
    });

    test('replay entries', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);

      wal.append(WalEntryType.sessionCreate, {'sessionId': 's-1'});
      wal.append(WalEntryType.pluginLoad, {'pluginId': 'storage'});
      wal.append(WalEntryType.taskSchedule, {'taskId': 't-1'});

      final all = wal.replay();
      expect(all.length, 3);

      final fromLsn1 = wal.replay(fromLsn: 1);
      expect(fromLsn1.length, 2);

      final typeOnly = wal.replayType(WalEntryType.pluginLoad);
      expect(typeOnly.length, 1);
    });

    test('replay transaction', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);

      final txId = wal.beginTransaction();
      wal.append(WalEntryType.sessionCreate, {
        'sessionId': 's-1',
      }, transactionId: txId);
      wal.append(WalEntryType.leaseAcquire, {
        'sessionId': 's-1',
      }, transactionId: txId);
      wal.commitTransaction(txId);

      final txEntries = wal.replayTransaction(txId);
      expect(txEntries.length, 4);
    });

    test('checkpoint', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);

      wal.append(WalEntryType.sessionCreate, {'sessionId': 's-1'});
      wal.checkpoint();
      wal.append(WalEntryType.pluginLoad, {'pluginId': 'storage'});

      expect(wal.lastCheckpointLsn, greaterThan(0));

      final sinceCheckpoint = wal.replaySinceCheckpoint();
      expect(sinceCheckpoint.length, greaterThanOrEqualTo(1));
    });

    test('integrity validation', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);

      wal.append(WalEntryType.sessionCreate, {'sessionId': 's-1'});
      wal.append(WalEntryType.pluginLoad, {'pluginId': 'storage'});

      expect(wal.validateIntegrity(), isTrue);
    });

    test('compact reduces log size', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);

      for (var i = 0; i < 100; i++) {
        wal.append(WalEntryType.eventPublish, {'index': i});
      }

      wal.checkpoint();
      wal.compact(keepLastN: 50);

      expect(wal.entryCount, lessThan(100));
    });

    test('WAL entry serialization', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);

      final entry = wal.append(WalEntryType.sessionCreate, {
        'sessionId': 's-1',
      });
      final json = entry.toJson();
      final restored = WalEntry.fromJson(json);

      expect(restored.lsn, entry.lsn);
      expect(restored.type, entry.type);
      expect(restored.sourceNodeId, entry.sourceNodeId);
    });
  });

  group('Event Store', () {
    test('append to stream and read', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);
      final store = EventStore(wal);

      store.appendToStream('session-1', WalEntryType.sessionCreate, {
        'userId': 'user-A',
      });
      store.appendToStream('session-1', WalEntryType.sessionUpdate, {
        'action': 'activate',
      });

      expect(store.streamVersion('session-1'), 2);

      final entries = store.readStream('session-1');
      expect(entries.length, 2);
    });

    test('multiple streams', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);
      final store = EventStore(wal);

      store.appendToStream('session-1', WalEntryType.sessionCreate, {});
      store.appendToStream('session-2', WalEntryType.sessionCreate, {});
      store.appendToStream('session-1', WalEntryType.sessionUpdate, {});

      expect(store.streamCount, 2);
      expect(store.streamVersion('session-1'), 2);
      expect(store.streamVersion('session-2'), 1);
    });

    test('read stream from version', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);
      final store = EventStore(wal);

      store.appendToStream('session-1', WalEntryType.sessionCreate, {});
      store.appendToStream('session-1', WalEntryType.sessionUpdate, {});
      store.appendToStream('session-1', WalEntryType.sessionClose, {});

      final fromV2 = store.readStream('session-1', fromVersion: 2);
      expect(fromV2.length, 2);
    });

    test('rebuild from WAL', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final wal = WriteAheadLog(nodeId: 'node-A', clock: clock);
      final store = EventStore(wal);

      store.appendToStream('session-1', WalEntryType.sessionCreate, {});
      store.appendToStream('session-2', WalEntryType.sessionCreate, {});

      store.clear();
      expect(store.streamCount, 0);

      store.rebuildFromWal();
      expect(store.streamCount, 2);
    });
  });

  group('Unified Lease (Semantic Compression)', () {
    test('session lease acquire and release', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      final lease = manager.acquire(LeaseType.session, 'session-1');
      expect(lease.isSessionLease, isTrue);
      expect(lease.isActive, isTrue);
      expect(manager.isOwner('session-1'), isTrue);

      manager.release('session-1');
      expect(manager.canWrite('session-1'), isFalse);
    });

    test('resource lease acquire and release', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      final lease = manager.acquire(LeaseType.resource, 'gpu-0');
      expect(lease.isResourceLease, isTrue);
      expect(lease.isActive, isTrue);

      manager.release('gpu-0');
      expect(manager.isOwner('gpu-0'), isFalse);
    });

    test('capability lease acquire and release', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      final lease = manager.acquire(LeaseType.capability, 'storage.write');
      expect(lease.isCapabilityLease, isTrue);
      expect(lease.isActive, isTrue);
    });

    test('single writer: same node re-acquire returns existing lease', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      final lease1 = manager.acquire(LeaseType.session, 'session-1');
      final lease2 = manager.acquire(LeaseType.session, 'session-1');

      expect(lease1.ownerId, lease2.ownerId);
      expect(lease1.targetId, lease2.targetId);
    });

    test('single writer: cannot write after release', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      manager.acquire(LeaseType.session, 'session-1');
      manager.release('session-1');

      expect(manager.canWrite('session-1'), isFalse);
    });

    test('lease renewal extends expiry', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      final lease = manager.acquire(LeaseType.session, 'session-1');
      final originalExpiry = lease.expiresAt;

      final renewed = manager.renew('session-1');
      expect(renewed, isTrue);
      expect(
        manager.getLease('session-1')!.expiresAt,
        greaterThanOrEqualTo(originalExpiry),
      );
    });

    test('lease expiry detection', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(
        localNodeId: 'node-A',
        clock: clock,
        config: const LeaseConfig(sessionTtl: Duration(milliseconds: 50)),
      );

      manager.acquire(LeaseType.session, 'session-1');

      Future<void>.delayed(const Duration(milliseconds: 100), () {
        manager.tickExpiry();
        expect(manager.canWrite('session-1'), isFalse);
      });
    });

    test('lease revocation', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      manager.acquire(LeaseType.session, 'session-1');
      manager.revoke('session-1', 'node-B');

      expect(manager.canWrite('session-1'), isFalse);
    });

    test('different lease types have different TTLs', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(
        localNodeId: 'node-A',
        clock: clock,
        config: const LeaseConfig(
          sessionTtl: Duration(seconds: 30),
          resourceTtl: Duration(seconds: 60),
          capabilityTtl: Duration(seconds: 15),
        ),
      );

      final sessionLease = manager.acquire(LeaseType.session, 's-1');
      final sessionTtl = sessionLease.ttl.inSeconds;

      manager.release('s-1');

      final resourceLease = manager.acquire(LeaseType.resource, 'r-1');
      final resourceTtl = resourceLease.ttl.inSeconds;

      expect(resourceTtl, greaterThan(sessionTtl));
    });

    test('lease serialization round-trip', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      final lease = manager.acquire(LeaseType.session, 'session-1');
      final json = lease.toJson();
      final restored = UnifiedLease.fromJson(json);

      expect(restored.leaseId, lease.leaseId);
      expect(restored.leaseType, LeaseType.session);
      expect(restored.ownerId, 'node-A');
    });

    test('released lease can be re-acquired', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      manager.acquire(LeaseType.session, 'session-1');
      manager.release('session-1');

      final newLease = manager.tryAcquire(LeaseType.session, 'session-1');
      expect(newLease, isNotNull);
      expect(newLease!.isActive, isTrue);
    });

    test('lease type filtering', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      manager.acquire(LeaseType.session, 's-1');
      manager.acquire(LeaseType.resource, 'r-1');
      manager.acquire(LeaseType.capability, 'c-1');

      expect(manager.sessionLeases.length, 1);
      expect(manager.resourceLeases.length, 1);
      expect(manager.capabilityLeases.length, 1);
      expect(manager.activeLeaseCount, 3);
    });

    test('receive remote lease state', () {
      final clock = HybridLogicalClock(nodeId: 'node-A');
      final manager = UnifiedLeaseManager(localNodeId: 'node-A', clock: clock);

      final remoteLease = UnifiedLease(
        leaseId: 'lease-remote',
        leaseType: LeaseType.session,
        ownerId: 'node-B',
        targetId: 'session-remote',
        acquiredAt: clock.tick().physicalTime,
        expiresAt: clock.tick().physicalTime + 30000,
        incarnation: 1,
      );

      manager.receiveLeaseState(remoteLease);
      expect(manager.getLease('session-remote'), isNotNull);
    });
  });
}
