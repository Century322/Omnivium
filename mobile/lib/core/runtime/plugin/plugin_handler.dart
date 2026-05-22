import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/runtime_stream.dart';
import '../vocabulary/capability_context.dart';

enum HandlerStatus {
  success,
  failure,
  deferred,
}

enum CapabilityStatus {
  success,
  failure,
  partial,
  streaming,
}

class RuntimeError {
  final String code;
  final String message;
  final bool recoverable;
  final int? retryAfterMs;
  final dynamic details;

  const RuntimeError({
    required this.code,
    required this.message,
    this.recoverable = true,
    this.retryAfterMs,
    this.details,
  });

  factory RuntimeError.timeout({String? message}) =>
      RuntimeError(code: 'TIMEOUT', message: message ?? 'Operation timed out', recoverable: true);

  factory RuntimeError.cancelled({String? message}) =>
      RuntimeError(code: 'CANCELLED', message: message ?? 'Operation cancelled', recoverable: false);

  factory RuntimeError.permissionDenied({String? message}) =>
      RuntimeError(code: 'PERMISSION_DENIED', message: message ?? 'Permission denied', recoverable: false);

  factory RuntimeError.notFound({String? message}) =>
      RuntimeError(code: 'NOT_FOUND', message: message ?? 'Capability not found', recoverable: true);

  factory RuntimeError.unavailable({String? message}) =>
      RuntimeError(code: 'UNAVAILABLE', message: message ?? 'Service unavailable', recoverable: true);
}

class HandlerResult {
  final HandlerStatus status;
  final dynamic payload;
  final RuntimeError? error;

  const HandlerResult({
    required this.status,
    this.payload,
    this.error,
  });

  factory HandlerResult.ok([dynamic payload]) =>
      HandlerResult(status: HandlerStatus.success, payload: payload);

  factory HandlerResult.fail(RuntimeError error) =>
      HandlerResult(status: HandlerStatus.failure, error: error);

  factory HandlerResult.deferred() =>
      const HandlerResult(status: HandlerStatus.deferred);
}

class CapabilityResult {
  final CapabilityStatus status;
  final dynamic data;
  final RuntimeStream? stream;
  final RuntimeError? error;

  const CapabilityResult({
    required this.status,
    this.data,
    this.stream,
    this.error,
  });

  factory CapabilityResult.ok([dynamic data]) =>
      CapabilityResult(status: CapabilityStatus.success, data: data);

  factory CapabilityResult.fail(RuntimeError error) =>
      CapabilityResult(status: CapabilityStatus.failure, error: error);

  factory CapabilityResult.streaming(RuntimeStream stream) =>
      CapabilityResult(status: CapabilityStatus.streaming, stream: stream);

  factory CapabilityResult.partial(dynamic data) =>
      CapabilityResult(status: CapabilityStatus.partial, data: data);
}

abstract class PluginHandler {
  Future<HandlerResult> handleMessage(RuntimeMessage message, CapabilityContext context);
  Future<HandlerResult> handleEvent(RuntimeEvent event, CapabilityContext context);
  Future<CapabilityResult> invokeCapability(String capabilityId, dynamic params, CapabilityContext context);
}
