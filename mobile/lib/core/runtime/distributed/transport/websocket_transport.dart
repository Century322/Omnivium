import 'dart:async';
import 'dart:convert';
import 'dart:io' if (dart.library.html) '';
import 'runtime_transport.dart';

class WebSocketTransport implements RuntimeTransport {
  final String _localNodeId;
  final String _serverUrl;
  final Duration _reconnectInterval;
  final int _maxReconnectAttempts;

  TransportState _state = TransportState.disconnected;
  final StreamController<TransportMessage> _incomingController =
      StreamController<TransportMessage>.broadcast();
  final List<void Function(TransportState, TransportState)> _stateCallbacks =
      [];
  final Map<String, Completer<TransportMessage>> _pendingRequests = {};

  _IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;

  WebSocketTransport({
    required String localNodeId,
    required String serverUrl,
    Duration reconnectInterval = const Duration(seconds: 5),
    int maxReconnectAttempts = 10,
  }) : _localNodeId = localNodeId,
       _serverUrl = serverUrl,
       _reconnectInterval = reconnectInterval,
       _maxReconnectAttempts = maxReconnectAttempts;

  @override
  TransportState get state => _state;

  @override
  TransportType get transportType => TransportType.websocket;

  @override
  String get localNodeId => _localNodeId;

  @override
  Stream<TransportMessage> get incoming => _incomingController.stream;

  @override
  Future<void> connect() async {
    if (_state == TransportState.connected) return;
    _intentionalDisconnect = false;
    _setState(TransportState.connecting);

    try {
      final uri = Uri.parse('$_serverUrl?nodeId=$_localNodeId');
      final socket = await WebSocket.connect(uri.toString());
      final channel = _IOWebSocketChannel(socket);
      _channel = channel;

      _subscription = channel.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      _reconnectAttempts = 0;
      _setState(TransportState.connected);
    } catch (e) {
      _setState(TransportState.error);
      _scheduleReconnect();
    }
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.close();
    _channel = null;
    _setState(TransportState.disconnected);
  }

  @override
  Future<void> send(TransportMessage message) async {
    if (_state != TransportState.connected || _channel == null) {
      throw StateError('Transport not connected');
    }
    final ch = _channel;
    if (ch != null) {
      ch.sink.add(jsonEncode(message.toJson()));
    }
  }

  @override
  Future<TransportMessage?> requestResponse(
    TransportMessage message, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_state != TransportState.connected) return null;

    final completer = Completer<TransportMessage>();
    _pendingRequests[message.id] = completer;

    try {
      await send(message);

      final response = await completer.future.timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Request ${message.id} timed out');
        },
      );
      return response;
    } catch (e) {
      AppLogger.instance.debug('WS handshake failed', error: e);
      return null;
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
  Future<bool> healthCheck() async {
    if (_state != TransportState.connected || _channel == null) return false;
    try {
      final ping = TransportMessage(
        id: 'ping_${DateTime.now().millisecondsSinceEpoch}',
        type: 'health.ping',
        sourceNodeId: _localNodeId,
        targetNodeId: 'server',
        timestamp: HybridTimestampLike(
          physicalTime: DateTime.now().millisecondsSinceEpoch,
          nodeId: _localNodeId,
        ),
      );
      final response = await requestResponse(
        ping,
        timeout: const Duration(seconds: 5),
      );
      return response != null;
    } catch (e) {
      AppLogger.instance.debug('WS send failed', error: e);
      return false;
    }
  }

  void _onData(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = _parseMessage(json);

      if (_pendingRequests.containsKey(message.payload['requestId'])) {
        final requestId = message.payload['requestId'] as String;
        _pendingRequests[requestId]?.complete(message);
      } else {
        _incomingController.add(message);
      }
    } catch (e) {
      AppLogger.instance.debug('WS message parse failed', error: e);
    }
  }

  TransportMessage _parseMessage(Map<String, dynamic> json) {
    final tsJson = json['timestamp'] as Map<String, dynamic>? ?? {};
    return TransportMessage(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      sourceNodeId: json['sourceNodeId'] as String? ?? '',
      targetNodeId: json['targetNodeId'] as String? ?? _localNodeId,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      timestamp: HybridTimestampLike(
        physicalTime: tsJson['pt'] as int? ?? 0,
        logicalTime: tsJson['lt'] as int? ?? 0,
        nodeId: tsJson['node'] as String? ?? '',
      ),
      headers:
          (json['headers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
    );
  }

  void _onError(dynamic error) {
    _setState(TransportState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    if (!_intentionalDisconnect) {
      _setState(TransportState.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectTimer?.cancel();
    final delay = Duration(
      milliseconds:
          _reconnectInterval.inMilliseconds *
          (1 << _reconnectAttempts.clamp(0, 5)),
    );
    final maxDelay = const Duration(seconds: 30);
    final actualDelay = delay < maxDelay ? delay : maxDelay;
    _reconnectTimer = Timer(actualDelay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  void _setState(TransportState newState) {
    final previous = _state;
    _state = newState;
    for (final cb in _stateCallbacks) {
      cb(previous, newState);
    }
  }
}

class _IOWebSocketChannel {
  final WebSocket _socket;

  _IOWebSocketChannel(this._socket);

  Stream get stream => _socket;

  _IOWebSocketSink get sink => _IOWebSocketSink(_socket);

  Future<void> close([int? closeCode, String? closeReason]) =>
      _socket.close(closeCode, closeReason);
}

class _IOWebSocketSink {
  final WebSocket _socket;

  _IOWebSocketSink(this._socket);

  void add(dynamic data) => _socket.add(data);

  Future<void> close([int? closeCode, String? closeReason]) =>
      _socket.close(closeCode, closeReason);
}
