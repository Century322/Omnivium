import 'dart:async';
import 'wire_protocol.dart';
import '../hybrid_logical_clock.dart';

enum ProtocolState { uninitialized, handshaking, ready, closing, closed, error }

class PendingAck {
  final WireFrame frame;
  final Completer<AckFrame> completer;
  int sentAt;
  int retryCount;

  PendingAck({
    required this.frame,
    required this.completer,
    required this.sentAt,
    this.retryCount = 0,
  });
}

class ChunkAssembly {
  final String correlationId;
  final int totalChunks;
  final Map<int, WireEnvelope> receivedChunks;
  final int startedAt;

  ChunkAssembly({
    required this.correlationId,
    required this.totalChunks,
    required this.startedAt,
  }) : receivedChunks = {};

  bool get isComplete => receivedChunks.length == totalChunks;

  void addChunk(int index, WireEnvelope envelope) {
    receivedChunks[index] = envelope;
  }

  List<int> assemble() {
    final buffer = <int>[];
    for (var i = 0; i < totalChunks; i++) {
      final chunk = receivedChunks[i];
      if (chunk != null) {
        buffer.addAll(chunk.payload);
      }
    }
    return buffer;
  }
}

class ProtocolHandler {
  final String _localNodeId;
  final HybridLogicalClock _clock;
  final WireProtocolConfig _config;
  final StreamController<WireFrame> _outgoingController =
      StreamController<WireFrame>.broadcast();
  final StreamController<WireEnvelope> _incomingEnvelopeController =
      StreamController<WireEnvelope>.broadcast();
  final Map<int, PendingAck> _pendingAcks = {};
  final Map<String, ChunkAssembly> _chunkAssemblies = {};

  ProtocolState _state = ProtocolState.uninitialized;
  int _frameSeq = 0;
  int _envelopeSeq = 0;
  Timer? _heartbeatTimer;
  Timer? _ackTimeoutTimer;
  CompressionType _negotiatedCompression = CompressionType.none;
  int _negotiatedMaxFrameSize = 65536;
  String? _remoteNodeId;

  ProtocolHandler({
    required String localNodeId,
    required HybridLogicalClock clock,
    WireProtocolConfig config = const WireProtocolConfig(),
  }) : _localNodeId = localNodeId,
       _clock = clock,
       _config = config;

  ProtocolState get state => _state;
  String get localNodeId => _localNodeId;
  String? get remoteNodeId => _remoteNodeId;
  Stream<WireFrame> get outgoing => _outgoingController.stream;
  Stream<WireEnvelope> get incomingEnvelopes =>
      _incomingEnvelopeController.stream;
  int get pendingAckCount => _pendingAcks.length;
  int get pendingChunkCount => _chunkAssemblies.length;
  bool get isReady => _state == ProtocolState.ready;

  HandshakeFrame createHandshake() {
    _state = ProtocolState.handshaking;
    return HandshakeFrame(
      sourceNodeId: _localNodeId,
      protocolVersion: _config.protocolVersion,
      authMethod: _config.authMethod,
      authToken: _config.authToken,
      supportedCompression: _config.compression,
      maxFrameSize: _config.maxFrameSize);
  }

  HandshakeAckFrame handleHandshake(HandshakeFrame handshake) {
    _remoteNodeId = handshake.sourceNodeId;

    final negotiatedCompression = handshake.supportedCompression;
    final negotiatedMaxFrameSize = handshake.maxFrameSize < _config.maxFrameSize
        ? handshake.maxFrameSize
        : _config.maxFrameSize;

    _negotiatedCompression = negotiatedCompression;
    _negotiatedMaxFrameSize = negotiatedMaxFrameSize;

    return HandshakeAckFrame(
      sourceNodeId: _localNodeId,
      accepted: true,
      negotiatedCompression: negotiatedCompression,
      negotiatedMaxFrameSize: negotiatedMaxFrameSize,
      hlcTime: _clock.tick().physicalTime);
  }

  void completeHandshake(HandshakeAckFrame ack) {
    if (ack.accepted) {
      _negotiatedCompression = ack.negotiatedCompression;
      _negotiatedMaxFrameSize = ack.negotiatedMaxFrameSize;
      _state = ProtocolState.ready;
      _startHeartbeat();
      _startAckTimeout();
    } else {
      _state = ProtocolState.error;
    }
  }

  WireFrame createDataFrame(
    String targetNodeId,
    String messageType,
    List<int> payload) {
    final now = _clock.tick();
    final frame = WireFrame(
      frameId: _frameSeq++,
      type: FrameType.data,
      sourceNodeId: _localNodeId,
      targetNodeId: targetNodeId,
      hlcTime: now.physicalTime,
      sequence: _frameSeq,
      headers: {'messageType': messageType},
      payload: payload);
    return frame;
  }

  Future<AckFrame> sendWithAck(WireFrame frame) {
    if (_pendingAcks.length >= _config.maxPendingAcks) {
      return Future.value(
        AckFrame(
          ackFrameId: -1,
          originalFrameId: frame.frameId,
          sourceNodeId: _localNodeId,
          success: false,
          errorCode: 'ACK_QUEUE_FULL',
          hlcTime: _clock.tick().physicalTime));
    }

    final completer = Completer<AckFrame>();
    _pendingAcks[frame.frameId] = PendingAck(
      frame: frame,
      completer: completer,
      sentAt: _clock.tick().physicalTime);

    _outgoingController.add(frame);
    return completer.future.timeout(
      _config.ackTimeout,
      onTimeout: () {
        _pendingAcks.remove(frame.frameId);
        return AckFrame(
          ackFrameId: -1,
          originalFrameId: frame.frameId,
          sourceNodeId: _localNodeId,
          success: false,
          errorCode: 'ACK_TIMEOUT',
          hlcTime: _clock.tick().physicalTime);
      });
  }

  AckFrame createAck(
    WireFrame originalFrame, {
    bool success = true,
    String? errorCode,
  }) {
    return AckFrame(
      ackFrameId: _frameSeq++,
      originalFrameId: originalFrame.frameId,
      sourceNodeId: _localNodeId,
      success: success,
      errorCode: errorCode,
      hlcTime: _clock.tick().physicalTime);
  }

  void handleAck(AckFrame ack) {
    final pending = _pendingAcks.remove(ack.originalFrameId);
    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.complete(ack);
    }
  }

  HeartbeatFrame createHeartbeat() {
    return HeartbeatFrame(
      sourceNodeId: _localNodeId,
      hlcTime: _clock.tick().physicalTime);
  }

  void handleHeartbeat(HeartbeatFrame hb) {
    _clock.receive(
      HybridTimestamp(physicalTime: hb.hlcTime, nodeId: hb.sourceNodeId));
  }

  List<WireEnvelope> chunkEnvelope(WireEnvelope envelope) {
    if (envelope.payload.length <= _negotiatedMaxFrameSize) {
      return [envelope];
    }

    final chunks = <WireEnvelope>[];
    final totalChunks = (envelope.payload.length / _config.chunkSize).ceil();

    for (var i = 0; i < totalChunks; i++) {
      final start = i * _config.chunkSize;
      final end = (start + _config.chunkSize).clamp(0, envelope.payload.length);
      chunks.add(
        WireEnvelope(
          envelopeId: '${envelope.envelopeId}_$i',
          correlationId: envelope.correlationId,
          messageType: envelope.messageType,
          sourceNodeId: envelope.sourceNodeId,
          targetNodeId: envelope.targetNodeId,
          hlcTime: envelope.hlcTime,
          compression: envelope.compression,
          totalChunks: totalChunks,
          chunkIndex: i,
          payload: envelope.payload.sublist(start, end),
          metadata: i == 0 ? envelope.metadata : {}));
    }

    return chunks;
  }

  void handleEnvelopeChunk(WireEnvelope envelope) {
    if (!envelope.isChunked) {
      if (!_incomingEnvelopeController.isClosed) {
        _incomingEnvelopeController.add(envelope);
      }
      return;
    }

    var assembly = _chunkAssemblies[envelope.correlationId];
    if (assembly == null) {
      assembly = ChunkAssembly(
        correlationId: envelope.correlationId,
        totalChunks: envelope.totalChunks,
        startedAt: _clock.tick().physicalTime);
      _chunkAssemblies[envelope.correlationId] = assembly;
    }

    assembly.addChunk(envelope.chunkIndex, envelope);

    if (assembly.isComplete) {
      final assembledPayload = assembly.assemble();
      _chunkAssemblies.remove(envelope.correlationId);

      final fullEnvelope = WireEnvelope(
        envelopeId: envelope.correlationId,
        correlationId: envelope.correlationId,
        messageType: envelope.messageType,
        sourceNodeId: envelope.sourceNodeId,
        targetNodeId: envelope.targetNodeId,
        hlcTime: envelope.hlcTime,
        compression: envelope.compression,
        payload: assembledPayload,
        metadata: assembly.receivedChunks[0]?.metadata ?? {});

      if (!_incomingEnvelopeController.isClosed) {
        _incomingEnvelopeController.add(fullEnvelope);
      }
    }
  }

  WireEnvelope createEnvelope(
    String targetNodeId,
    String messageType,
    List<int> payload, {
    Map<String, String> metadata = const {},
  }) {
    final now = _clock.tick();
    return WireEnvelope(
      envelopeId: 'env_${_envelopeSeq++}',
      correlationId: 'corr_$_envelopeSeq',
      messageType: messageType,
      sourceNodeId: _localNodeId,
      targetNodeId: targetNodeId,
      hlcTime: now.physicalTime,
      compression: _negotiatedCompression,
      payload: payload,
      metadata: metadata);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_config.heartbeatInterval, (_) {
      if (_state == ProtocolState.ready) {
        final hb = createHeartbeat();
        _outgoingController.add(
          WireFrame(
            frameId: _frameSeq++,
            type: FrameType.heartbeat,
            sourceNodeId: _localNodeId,
            targetNodeId: _remoteNodeId ?? '',
            hlcTime: hb.hlcTime,
            headers: {'incarnation': hb.incarnation.toString()}));
      }
    });
  }

  void _startAckTimeout() {
    _ackTimeoutTimer?.cancel();
    _ackTimeoutTimer = Timer.periodic(_config.ackTimeout, (_) {
      final now = _clock.tick().physicalTime;
      final timeoutMs = _config.ackTimeout.inMilliseconds;

      final timedOut = _pendingAcks.entries
          .where((e) => now - e.value.sentAt > timeoutMs)
          .toList();

      for (final entry in timedOut) {
        final pending = entry.value;
        if (pending.retryCount < _config.maxRetries) {
          pending.retryCount++;
          pending.sentAt = now;
          _outgoingController.add(pending.frame);
        } else {
          _pendingAcks.remove(entry.key);
          if (!pending.completer.isCompleted) {
            pending.completer.complete(
              AckFrame(
                ackFrameId: -1,
                originalFrameId: pending.frame.frameId,
                sourceNodeId: _localNodeId,
                success: false,
                errorCode: 'RETRY_EXHAUSTED',
                hlcTime: now));
          }
        }
      }
    });
  }

  Future<void> close() async {
    _state = ProtocolState.closing;
    _heartbeatTimer?.cancel();
    _ackTimeoutTimer?.cancel();

    for (final pending in _pendingAcks.values) {
      if (!pending.completer.isCompleted) {
        pending.completer.complete(
          AckFrame(
            ackFrameId: -1,
            originalFrameId: pending.frame.frameId,
            sourceNodeId: _localNodeId,
            success: false,
            errorCode: 'CONNECTION_CLOSED',
            hlcTime: _clock.tick().physicalTime));
      }
    }
    _pendingAcks.clear();
    _chunkAssemblies.clear();

    _state = ProtocolState.closed;
    await _outgoingController.close();
    await _incomingEnvelopeController.close();
  }
}
