import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/streaming_controller.dart';

void main() {
  group('StreamChunk', () {
    test('default values', () {
      const chunk = StreamChunk();
      expect(chunk.content, '');
      expect(chunk.isDone, false);
      expect(chunk.error, isNull);
    });

    test('custom values', () {
      const chunk = StreamChunk(content: 'hello', isDone: true, error: 'err');
      expect(chunk.content, 'hello');
      expect(chunk.isDone, true);
      expect(chunk.error, 'err');
    });
  });

  group('StreamingController', () {
    late StreamingController controller;

    setUp(() {
      controller = StreamingController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state', () {
      expect(controller.isStreaming, isFalse);
      expect(controller.buffer, '');
    });

    test('addChunk updates buffer and isStreaming', () {
      controller.addChunk('Hello');
      expect(controller.buffer, 'Hello');
      expect(controller.isStreaming, isTrue);
    });

    test('multiple addChunk accumulates buffer', () {
      controller.addChunk('Hello');
      controller.addChunk(' World');
      expect(controller.buffer, 'Hello World');
    });

    test('addChunk emits StreamChunk via stream', () async {
      final chunks = <StreamChunk>[];
      controller.stream.listen(chunks.add);
      controller.addChunk('test');
      await Future.delayed(Duration.zero);
      expect(chunks.length, 1);
      expect(chunks.first.content, 'test');
      expect(chunks.first.isDone, isFalse);
    });

    test('complete sets isStreaming to false', () {
      controller.addChunk('data');
      controller.complete();
      expect(controller.isStreaming, isFalse);
    });

    test('complete emits isDone=true', () async {
      final chunks = <StreamChunk>[];
      controller.stream.listen(chunks.add);
      controller.addChunk('data');
      controller.complete();
      await Future.delayed(Duration.zero);
      expect(chunks.last.isDone, isTrue);
    });

    test('addError sets isStreaming to false', () {
      controller.addChunk('data');
      controller.addError('Network error');
      expect(controller.isStreaming, isFalse);
    });

    test('addError emits error chunk', () async {
      final chunks = <StreamChunk>[];
      controller.stream.listen(chunks.add);
      controller.addError('Network error');
      await Future.delayed(Duration.zero);
      expect(chunks.last.error, 'Network error');
      expect(chunks.last.isDone, isTrue);
    });

    test('reset clears buffer and isStreaming', () {
      controller.addChunk('data');
      controller.reset();
      expect(controller.buffer, '');
      expect(controller.isStreaming, isFalse);
    });

    test('full flow: addChunk -> complete', () async {
      final chunks = <StreamChunk>[];
      controller.stream.listen(chunks.add);
      controller.addChunk('Hello');
      controller.addChunk(' World');
      controller.complete();
      await Future.delayed(Duration.zero);
      expect(chunks.length, 3);
      expect(controller.buffer, 'Hello World');
      expect(controller.isStreaming, isFalse);
    });
  });
}
