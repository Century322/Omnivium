import 'dart:async';
import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/runtime_stream.dart';
import '../vocabulary/runtime_route.dart';
import '../vocabulary/runtime_metadata.dart';
import '../vocabulary/capability_context.dart';

class FakeAgentPlugin implements PluginHandler {
  int _chatCount = 0;
  int _streamCount = 0;
  int _executeCount = 0;
  int _cancelCount = 0;

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
      case 'agent.chat':
        return _handleChat(params, context);
      case 'agent.stream':
        return _handleStream(params, context);
      case 'agent.cancel':
        return _handleCancel(params, context);
      case 'agent.execute':
        return _handleExecute(params, context);
      default:
        return CapabilityResult.fail(
          RuntimeError(
            code: 'UNKNOWN_CAPABILITY',
            message: 'Unknown capability: $capabilityId',
          ),
        );
    }
  }

  Future<CapabilityResult> _handleChat(
    dynamic params,
    CapabilityContext context,
  ) async {
    _chatCount++;
    final message = params is Map
        ? params['message'] as String?
        : params?.toString() ?? '';

    await Future.delayed(const Duration(milliseconds: 100));

    if (context.shouldAbort) {
      return CapabilityResult.fail(
        const RuntimeError(
          code: 'CANCELLED',
          message: 'Chat cancelled',
          recoverable: false,
        ),
      );
    }

    return CapabilityResult.ok({
      'response': 'Fake response to: $message',
      'chatCount': _chatCount,
      'model': 'fake-agent-v1',
    });
  }

  CapabilityResult _handleStream(dynamic params, CapabilityContext context) {
    _streamCount++;
    final message = params is Map
        ? params['message'] as String?
        : params?.toString() ?? '';
    final words = 'Streaming fake response to: $message'.split(' ');
    final meta = RuntimeMetadata(
      traceId: 'fake',
      spanId: 'stream_$_streamCount',
    );

    final (stream, controller) = RuntimeStream.create(
      id: 'stream_$_streamCount',
      type: 'agent.stream',
      source: RuntimeRoute(capability: 'agent.stream', pluginId: 'fake-agent'),
      backpressure: BackpressureStrategy.buffer,
    );

    () async {
      for (var i = 0; i < words.length; i++) {
        if (context.shouldAbort) {
          controller.add(
            StreamChunk(
              index: i,
              data: '[CANCELLED]',
              metadata: meta,
              isFinal: true,
            ),
          );
          await controller.close();
          return;
        }
        controller.add(
          StreamChunk(
            index: i,
            data: '${words[i]} ',
            metadata: meta,
            isFinal: i == words.length - 1,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await controller.close();
    }();

    return CapabilityResult.streaming(stream);
  }

  Future<CapabilityResult> _handleCancel(
    dynamic params,
    CapabilityContext context,
  ) async {
    _cancelCount++;
    return CapabilityResult.ok({
      'cancelled': true,
      'cancelCount': _cancelCount,
    });
  }

  Future<CapabilityResult> _handleExecute(
    dynamic params,
    CapabilityContext context,
  ) async {
    _executeCount++;
    final toolName = params is Map ? params['tool'] as String? : 'unknown';
    final toolParams = params is Map ? params['params'] : null;

    await Future.delayed(const Duration(milliseconds: 50));

    if (context.shouldAbort) {
      return CapabilityResult.fail(
        const RuntimeError(
          code: 'CANCELLED',
          message: 'Execute cancelled',
          recoverable: false,
        ),
      );
    }

    if (toolName == 'fail') {
      return CapabilityResult.fail(
        const RuntimeError(
          code: 'TOOL_FAILED',
          message: 'Tool execution failed',
          recoverable: true,
        ),
      );
    }

    if (toolName == 'timeout') {
      await Future.delayed(const Duration(seconds: 30));
      return CapabilityResult.ok({'result': 'should not reach'});
    }

    if (toolName == 'parallel') {
      final results = await Future.wait([
        Future.delayed(const Duration(milliseconds: 100)).then((_) => 'task1'),
        Future.delayed(const Duration(milliseconds: 150)).then((_) => 'task2'),
        Future.delayed(const Duration(milliseconds: 50)).then((_) => 'task3'),
      ]);
      return CapabilityResult.ok({
        'results': results,
        'executeCount': _executeCount,
      });
    }

    return CapabilityResult.ok({
      'tool': toolName,
      'params': toolParams,
      'result': 'fake_result',
      'executeCount': _executeCount,
    });
  }

  static PluginDescriptor descriptor() => PluginDescriptor(
    id: 'fake-agent',
    name: 'Fake Agent Plugin',
    version: '1.0.0',
    description:
        'Fake agent for Runtime testing - simulates streaming, timeout, cancellation, retry, tool call, parallel task',
    capabilities: const [
      CapabilityDeclaration(
        id: 'agent.chat',
        name: 'Chat',
        description: 'Simulate agent chat',
        permission: 'auto',
        timeoutMs: 5000,
      ),
      CapabilityDeclaration(
        id: 'agent.stream',
        name: 'Stream',
        description: 'Simulate streaming response',
        permission: 'auto',
        timeoutMs: 10000,
      ),
      CapabilityDeclaration(
        id: 'agent.cancel',
        name: 'Cancel',
        description: 'Cancel ongoing operation',
        permission: 'auto',
      ),
      CapabilityDeclaration(
        id: 'agent.execute',
        name: 'Execute',
        description:
            'Simulate tool execution (use tool=fail/timeout/parallel for testing)',
        permission: 'confirm',
        timeoutMs: 5000,
        maxRetries: 2,
      ),
    ],
  );
}
