import 'dart:async';
import 'runtime_metadata.dart';
import 'runtime_route.dart';
import 'runtime_event.dart';

enum BackpressureStrategy { buffer, dropOldest, dropNewest, pause }

class StreamChunk {
  final int index;
  final Object? data;
  final RuntimeMetadata metadata;
  final bool isFinal;

  const StreamChunk({
    required this.index,
    this.data,
    required this.metadata,
    this.isFinal = false,
  });
}

class RuntimeStream {
  final String id;
  final int version;
  final String type;
  final RuntimeRoute source;
  final BackpressureStrategy backpressure;
  final PropagationScope scope;
  final Stream<StreamChunk> _chunkStream;
  final void Function() onCancel;

  RuntimeStream._({
    required this.id,
    // ignore: unused_element_parameter
    this.version = 1,
    required this.type,
    required this.source,
    required this.backpressure,
    this.scope = PropagationScope.local,
    required Stream<StreamChunk> chunkStream,
    required this.onCancel,
  }) : _chunkStream = chunkStream;

  Stream<StreamChunk> get chunks => _chunkStream;

  static (RuntimeStream, StreamController<StreamChunk>) create({
    required String id,
    required String type,
    required RuntimeRoute source,
    BackpressureStrategy backpressure = BackpressureStrategy.buffer,
    PropagationScope scope = PropagationScope.local,
    void Function()? onCancel,
  }) {
    final controller = StreamController<StreamChunk>();
    final stream = RuntimeStream._(
      id: id,
      type: type,
      source: source,
      backpressure: backpressure,
      scope: scope,
      chunkStream: controller.stream,
      onCancel: onCancel ?? controller.close);
    return (stream, controller);
  }
}
