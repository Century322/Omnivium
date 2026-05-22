import 'dart:async';
import 'dart:math';
import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/runtime_stream.dart';
import '../vocabulary/runtime_route.dart';
import '../vocabulary/runtime_metadata.dart';
import '../vocabulary/capability_context.dart';

class ChaosAgentPlugin implements PluginHandler {
  static final _random = Random();

  @override
  Future<HandlerResult> handleMessage(
    RuntimeMessage message,
    CapabilityContext context,
  ) async {
    return HandlerResult.ok();
  }

  @override
  Future<HandlerResult> handleEvent(
    RuntimeEvent event,
    CapabilityContext context,
  ) async {
    return HandlerResult.ok();
  }

  @override
  Future<CapabilityResult> invokeCapability(
    String capabilityId,
    dynamic params,
    CapabilityContext context,
  ) async {
    switch (capabilityId) {
      case 'chaos.timeout':
        await Future.delayed(const Duration(hours: 1));
        return CapabilityResult.ok('should not reach');
      case 'chaos.malformed_stream':
        return _malformedStream(context);
      case 'chaos.partial_failure':
        return _partialFailure(params);
      case 'chaos.infinite_stream':
        return _infiniteStream(context);
      case 'chaos.retry_storm':
        return _retryStorm(params);
      case 'chaos.event_flood':
        return _eventFlood(params, context);
      case 'chaos.recursive_tool':
        return _recursiveTool(params, context);
      case 'chaos.crash':
        throw StateError('ChaosAgent intentional crash');
      case 'chaos.memory_pressure':
        return _memoryPressure(params);
      case 'chaos.cancel_test':
        return _cancelTest(context);
      default:
        return CapabilityResult.fail(
          RuntimeError(
            code: 'UNKNOWN_CAPABILITY',
            message: 'Unknown: $capabilityId',
          ),
        );
    }
  }

  CapabilityResult _malformedStream(CapabilityContext context) {
    final (stream, controller) = RuntimeStream.create(
      id: 'chaos_malformed',
      type: 'chaos.malformed_stream',
      source: RuntimeRoute(
        capability: 'chaos.malformed_stream',
        pluginId: 'chaos-agent',
      ),
    );

    () async {
      controller.add(
        StreamChunk(
          index: 0,
          data: 'valid chunk',
          metadata: RuntimeMetadata(traceId: 'chaos', spanId: '0'),
          isFinal: false,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      controller.addError(StateError('Malformed stream chunk'));
      controller.add(
        StreamChunk(
          index: 1,
          data: null,
          metadata: RuntimeMetadata(traceId: 'chaos', spanId: '1'),
          isFinal: false,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 10));
      controller.add(
        StreamChunk(
          index: 3,
          data: 'skipped index 2',
          metadata: RuntimeMetadata(traceId: 'chaos', spanId: '3'),
          isFinal: true,
        ),
      );
      await controller.close();
    }();

    return CapabilityResult.streaming(stream);
  }

  CapabilityResult _partialFailure(dynamic params) {
    final failRate = params is Map
        ? (params['failRate'] as num?)?.toDouble() ?? 0.5
        : 0.5;
    final shouldFail = _random.nextDouble() < failRate;
    if (shouldFail) {
      return CapabilityResult.fail(
        const RuntimeError(
          code: 'CHAOS_PARTIAL',
          message: 'Random partial failure',
          recoverable: true,
        ),
      );
    }
    return CapabilityResult.ok({'result': 'survived', 'failRate': failRate});
  }

  CapabilityResult _infiniteStream(CapabilityContext context) {
    final (stream, controller) = RuntimeStream.create(
      id: 'chaos_infinite',
      type: 'chaos.infinite_stream',
      source: RuntimeRoute(
        capability: 'chaos.infinite_stream',
        pluginId: 'chaos-agent',
      ),
    );

    () async {
      var index = 0;
      while (!context.shouldAbort) {
        controller.add(
          StreamChunk(
            index: index,
            data: 'chunk_$index',
            metadata: RuntimeMetadata(traceId: 'chaos', spanId: '$index'),
            isFinal: false,
          ),
        );
        index++;
        await Future.delayed(const Duration(milliseconds: 10));
      }
      controller.add(
        StreamChunk(
          index: index,
          data: '[ABORTED]',
          metadata: RuntimeMetadata(traceId: 'chaos', spanId: '$index'),
          isFinal: true,
        ),
      );
      await controller.close();
    }();

    return CapabilityResult.streaming(stream);
  }

  Future<CapabilityResult> _retryStorm(dynamic params) async {
    final maxRetries = params is Map
        ? (params['maxRetries'] as int?) ?? 100
        : 100;
    return CapabilityResult.fail(
      RuntimeError(
        code: 'CHAOS_RETRY_STORM',
        message: 'Always fails to trigger retry storm (maxRetries=$maxRetries)',
        recoverable: true,
      ),
    );
  }

  CapabilityResult _eventFlood(dynamic params, CapabilityContext context) {
    final count = params is Map ? (params['count'] as int?) ?? 1000 : 1000;
    return CapabilityResult.ok({
      'eventsToEmit': count,
      'instruction': 'Use EventBus.publish in loop from test harness',
    });
  }

  Future<CapabilityResult> _recursiveTool(
    dynamic params,
    CapabilityContext context,
  ) async {
    final depth = params is Map ? (params['depth'] as int?) ?? 5 : 5;
    if (depth <= 0) {
      return CapabilityResult.ok({'result': 'bottom'});
    }
    return CapabilityResult.ok({
      'depth': depth,
      'instruction':
          'Test harness should call chaos.recursive_tool with depth=${depth - 1}',
    });
  }

  CapabilityResult _memoryPressure(dynamic params) {
    final sizeKb = params is Map ? (params['sizeKb'] as int?) ?? 1024 : 1024;
    final data = List.filled(sizeKb * 1024, 0);
    return CapabilityResult.ok({
      'allocated': '${sizeKb}KB',
      'length': data.length,
    });
  }

  Future<CapabilityResult> _cancelTest(CapabilityContext context) async {
    final steps = <String>[];
    steps.add('started');

    await Future.delayed(const Duration(milliseconds: 50));
    if (context.shouldAbort) {
      steps.add('aborted_after_delay');
      return CapabilityResult.fail(
        const RuntimeError(
          code: 'CANCELLED',
          message: 'Operation cancelled',
          recoverable: false,
        ),
      );
    }
    steps.add('completed');
    return CapabilityResult.ok({'steps': steps});
  }

  static PluginDescriptor descriptor() => PluginDescriptor(
    id: 'chaos-agent',
    name: 'Chaos Agent Plugin',
    version: '1.0.0',
    description:
        'Runtime torture tool - generates timeout, malformed stream, partial failure, infinite stream, retry storm, event flood, crash',
    capabilities: const [
      CapabilityDeclaration(
        id: 'chaos.timeout',
        name: 'Timeout',
        description: 'Never returns (triggers timeout)',
        permission: 'auto',
        timeoutMs: 100,
        maxRetries: 0,
      ),
      CapabilityDeclaration(
        id: 'chaos.malformed_stream',
        name: 'Malformed Stream',
        description: 'Stream with errors, null data, skipped indices',
        permission: 'auto',
        timeoutMs: 5000,
      ),
      CapabilityDeclaration(
        id: 'chaos.partial_failure',
        name: 'Partial Failure',
        description: 'Randomly fails based on failRate param',
        permission: 'auto',
        maxRetries: 5,
      ),
      CapabilityDeclaration(
        id: 'chaos.infinite_stream',
        name: 'Infinite Stream',
        description: 'Streams forever until cancelled',
        permission: 'auto',
        timeoutMs: 30000,
      ),
      CapabilityDeclaration(
        id: 'chaos.retry_storm',
        name: 'Retry Storm',
        description: 'Always fails to trigger retry loops',
        permission: 'auto',
        maxRetries: 3,
      ),
      CapabilityDeclaration(
        id: 'chaos.event_flood',
        name: 'Event Flood',
        description: 'Returns instruction for mass event emission',
        permission: 'auto',
      ),
      CapabilityDeclaration(
        id: 'chaos.recursive_tool',
        name: 'Recursive Tool',
        description: 'Simulates recursive tool calls',
        permission: 'auto',
      ),
      CapabilityDeclaration(
        id: 'chaos.crash',
        name: 'Crash',
        description: 'Throws unhandled exception',
        permission: 'auto',
      ),
      CapabilityDeclaration(
        id: 'chaos.memory_pressure',
        name: 'Memory Pressure',
        description: 'Allocates large memory blocks',
        permission: 'confirm',
      ),
      CapabilityDeclaration(
        id: 'chaos.cancel_test',
        name: 'Cancel Test',
        description: 'Long operation that respects cancellation',
        permission: 'auto',
        timeoutMs: 5000,
      ),
    ],
  );
}
