import 'dart:async';

enum TransportState { disconnected, connecting, connected, error }

enum TransportType { local, ipc, websocket, mcp }

class TransportMessage {
  final String id;
  final String type;
  final String sourceNodeId;
  final String targetNodeId;
  final Map<String, dynamic> payload;
  final HybridTimestampLike timestamp;
  final Map<String, String> headers;

  const TransportMessage({
    required this.id,
    required this.type,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.payload = const {},
    required this.timestamp,
    this.headers = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'sourceNodeId': sourceNodeId,
    'targetNodeId': targetNodeId,
    'payload': payload,
    'timestamp': timestamp.toJson(),
    'headers': headers,
  };
}

class HybridTimestampLike {
  final int physicalTime;
  final int logicalTime;
  final String nodeId;

  const HybridTimestampLike({
    required this.physicalTime,
    this.logicalTime = 0,
    this.nodeId = 'local',
  });

  Map<String, dynamic> toJson() => {
    'pt': physicalTime,
    'lt': logicalTime,
    'node': nodeId,
  };
}

abstract class RuntimeTransport {
  TransportState get state;
  TransportType get transportType;
  String get localNodeId;

  Future<void> connect();
  Future<void> disconnect();

  Future<void> send(TransportMessage message);
  Stream<TransportMessage> get incoming;

  Future<TransportMessage?> requestResponse(
    TransportMessage message, {
    Duration timeout = const Duration(seconds: 10),
  });

  void onStateChange(
    void Function(TransportState previous, TransportState current) callback,
  );

  Future<bool> healthCheck();
}

class LocalTransport implements RuntimeTransport {
  TransportState _state = TransportState.disconnected;
  final StreamController<TransportMessage> _incomingController =
      StreamController<TransportMessage>.broadcast();
  final String _localNodeId;
  final List<void Function(TransportState, TransportState)> _stateCallbacks =
      [];
  final Map<String, Completer<TransportMessage>> _pendingRequests = {};

  LocalTransport({required String localNodeId}) : _localNodeId = localNodeId;

  @override
  TransportState get state => _state;

  @override
  TransportType get transportType => TransportType.local;

  @override
  String get localNodeId => _localNodeId;

  @override
  Stream<TransportMessage> get incoming => _incomingController.stream;

  @override
  Future<void> connect() async {
    _setState(TransportState.connected);
  }

  @override
  Future<void> disconnect() async {
    _setState(TransportState.disconnected);
    await _incomingController.close();
  }

  @override
  Future<void> send(TransportMessage message) async {
    if (_state != TransportState.connected) {
      throw StateError('Transport not connected');
    }
    _incomingController.add(message);
  }

  @override
  Future<TransportMessage?> requestResponse(
    TransportMessage message, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_state != TransportState.connected) return null;

    final completer = Completer<TransportMessage>();
    _pendingRequests[message.id] = completer;

    final response = TransportMessage(
      id: 'resp_${message.id}',
      type: '${message.type}.response',
      sourceNodeId: message.targetNodeId,
      targetNodeId: message.sourceNodeId,
      payload: {'requestId': message.id},
      timestamp: message.timestamp,
    );

    try {
      return response;
    } finally {
      _pendingRequests.remove(message.id);
    }
  }

  @override
  void onStateChange(
    void Function(TransportState previous, TransportState current) callback,
  ) {
    _stateCallbacks.add(callback);
  }

  @override
  Future<bool> healthCheck() async => _state == TransportState.connected;

  void _setState(TransportState newState) {
    final previous = _state;
    _state = newState;
    for (final cb in _stateCallbacks) {
      cb(previous, newState);
    }
  }

  void deliverMessage(TransportMessage message) {
    if (!_incomingController.isClosed) {
      _incomingController.add(message);
    }
  }
}

class TransportRegistry {
  final Map<TransportType, RuntimeTransport> _transports = {};

  void register(TransportType type, RuntimeTransport transport) {
    _transports[type] = transport;
  }

  RuntimeTransport? get(TransportType type) => _transports[type];

  RuntimeTransport? get defaultTransport =>
      _transports[TransportType.local] ?? _transports.values.firstOrNull;

  List<TransportType> get availableTypes => _transports.keys.toList();

  Future<void> connectAll() async {
    for (final transport in _transports.values) {
      if (transport.state == TransportState.disconnected) {
        await transport.connect();
      }
    }
  }

  Future<void> disconnectAll() async {
    for (final transport in _transports.values) {
      if (transport.state == TransportState.connected) {
        await transport.disconnect();
      }
    }
  }
}
