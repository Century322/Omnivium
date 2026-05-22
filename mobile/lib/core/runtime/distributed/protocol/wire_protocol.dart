
enum FrameType {
  data,
  ack,
  nack,
  heartbeat,
  handshake,
  handshakeAck,
  chunk,
  chunkAck,
  control,
}

enum CompressionType {
  none,
  gzip,
  lz4,
  zstd,
}

enum AuthMethod {
  none,
  token,
  certificate,
  sharedSecret,
}

class WireFrame {
  final int frameId;
  final FrameType type;
  final String sourceNodeId;
  final String targetNodeId;
  final int hlcTime;
  final int sequence;
  final Map<String, String> headers;
  final List<int> payload;

  const WireFrame({
    required this.frameId,
    required this.type,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.hlcTime = 0,
    this.sequence = 0,
    this.headers = const {},
    this.payload = const [],
  });

  int get estimatedSize => 32 + headers.length * 32 + payload.length;

  Map<String, dynamic> toJson() => {
        'fid': frameId,
        'type': type.name,
        'src': sourceNodeId,
        'dst': targetNodeId,
        'hlc': hlcTime,
        'seq': sequence,
        'hdr': headers,
        'payloadLen': payload.length,
      };
}

class WireEnvelope {
  final String envelopeId;
  final String correlationId;
  final String messageType;
  final String sourceNodeId;
  final String targetNodeId;
  final int hlcTime;
  final CompressionType compression;
  final int totalChunks;
  final int chunkIndex;
  final List<int> payload;
  final Map<String, String> metadata;

  const WireEnvelope({
    required this.envelopeId,
    required this.correlationId,
    required this.messageType,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.hlcTime = 0,
    this.compression = CompressionType.none,
    this.totalChunks = 1,
    this.chunkIndex = 0,
    this.payload = const [],
    this.metadata = const {},
  });

  bool get isChunked => totalChunks > 1;
  bool get isLastChunk => chunkIndex == totalChunks - 1;
  bool get isFirstChunk => chunkIndex == 0;

  Map<String, dynamic> toJson() => {
        'eid': envelopeId,
        'cid': correlationId,
        'msgType': messageType,
        'src': sourceNodeId,
        'dst': targetNodeId,
        'hlc': hlcTime,
        'comp': compression.name,
        'chunks': totalChunks,
        'chunkIdx': chunkIndex,
        'payloadLen': payload.length,
        'meta': metadata,
      };
}

class AckFrame {
  final int ackFrameId;
  final int originalFrameId;
  final String sourceNodeId;
  final bool success;
  final String? errorCode;
  final int hlcTime;

  const AckFrame({
    required this.ackFrameId,
    required this.originalFrameId,
    required this.sourceNodeId,
    this.success = true,
    this.errorCode,
    this.hlcTime = 0,
  });

  Map<String, dynamic> toJson() => {
        'ackFid': ackFrameId,
        'origFid': originalFrameId,
        'src': sourceNodeId,
        'ok': success,
        'err': errorCode,
        'hlc': hlcTime,
      };
}

class HeartbeatFrame {
  final String sourceNodeId;
  final int hlcTime;
  final int incarnation;
  final NodeHealth health;

  const HeartbeatFrame({
    required this.sourceNodeId,
    required this.hlcTime,
    this.incarnation = 0,
    this.health = NodeHealth.healthy,
  });

  Map<String, dynamic> toJson() => {
        'src': sourceNodeId,
        'hlc': hlcTime,
        'inc': incarnation,
        'health': health.name,
      };
}

enum NodeHealth {
  healthy,
  degraded,
  overloaded,
  recovering,
}

class HandshakeFrame {
  final String sourceNodeId;
  final String protocolVersion;
  final AuthMethod authMethod;
  final String? authToken;
  final CompressionType supportedCompression;
  final int maxFrameSize;
  final Map<String, String> capabilities;

  const HandshakeFrame({
    required this.sourceNodeId,
    this.protocolVersion = '1.0.0',
    this.authMethod = AuthMethod.none,
    this.authToken,
    this.supportedCompression = CompressionType.none,
    this.maxFrameSize = 65536,
    this.capabilities = const {},
  });

  Map<String, dynamic> toJson() => {
        'src': sourceNodeId,
        'ver': protocolVersion,
        'auth': authMethod.name,
        'comp': supportedCompression.name,
        'maxFrame': maxFrameSize,
        'caps': capabilities,
      };
}

class HandshakeAckFrame {
  final String sourceNodeId;
  final bool accepted;
  final String? rejectReason;
  final CompressionType negotiatedCompression;
  final int negotiatedMaxFrameSize;
  final int hlcTime;

  const HandshakeAckFrame({
    required this.sourceNodeId,
    this.accepted = true,
    this.rejectReason,
    this.negotiatedCompression = CompressionType.none,
    this.negotiatedMaxFrameSize = 65536,
    this.hlcTime = 0,
  });

  Map<String, dynamic> toJson() => {
        'src': sourceNodeId,
        'ok': accepted,
        'reason': rejectReason,
        'comp': negotiatedCompression.name,
        'maxFrame': negotiatedMaxFrameSize,
        'hlc': hlcTime,
      };
}

class WireProtocolConfig {
  final String protocolVersion;
  final Duration heartbeatInterval;
  final Duration ackTimeout;
  final int maxRetries;
  final int maxFrameSize;
  final CompressionType compression;
  final AuthMethod authMethod;
  final String? authToken;
  final int chunkSize;
  final int maxPendingAcks;

  const WireProtocolConfig({
    this.protocolVersion = '1.0.0',
    this.heartbeatInterval = const Duration(seconds: 5),
    this.ackTimeout = const Duration(seconds: 3),
    this.maxRetries = 3,
    this.maxFrameSize = 65536,
    this.compression = CompressionType.none,
    this.authMethod = AuthMethod.none,
    this.authToken,
    this.chunkSize = 32768,
    this.maxPendingAcks = 256,
  });
}
