import 'dart:async';

class StreamChunk {
  final String content;
  final bool isDone;
  final String? error;

  const StreamChunk({this.content = '', this.isDone = false, this.error});
}

class StreamingController {
  StreamController<StreamChunk>? _controller =
      StreamController<StreamChunk>.broadcast();
  bool _isStreaming = false;
  String _buffer = '';
  bool _disposed = false;
  static const int _maxBufferSize = 1024 * 1024;

  Stream<StreamChunk> get stream => _controller?.stream ?? const Stream.empty();
  bool get isStreaming => _isStreaming;
  String get buffer => _buffer;
  bool get isDisposed => _disposed;

  void addChunk(String content) {
    if (_disposed) return;
    final ctrl = _controller;
    if (ctrl == null || ctrl.isClosed) return;
    if (_buffer.length + content.length > _maxBufferSize) {
      addError('Response buffer overflow');
      return;
    }
    _isStreaming = true;
    _buffer += content;
    ctrl.add(StreamChunk(content: content));
  }

  void complete() {
    if (_disposed) return;
    final ctrl = _controller;
    if (ctrl == null || ctrl.isClosed) return;
    _isStreaming = false;
    ctrl.add(const StreamChunk(isDone: true));
  }

  void addError(String error) {
    if (_disposed) return;
    final ctrl = _controller;
    if (ctrl == null || ctrl.isClosed) return;
    _isStreaming = false;
    ctrl.add(StreamChunk(error: error, isDone: true));
  }

  void reset() {
    _buffer = '';
    _isStreaming = false;
    if (_disposed) return;
    final ctrl = _controller;
    if (ctrl != null && ctrl.isClosed) {
      _controller = StreamController<StreamChunk>.broadcast();
    }
  }

  void dispose() {
    _disposed = true;
    _controller?.close();
    _controller = null;
  }
}
