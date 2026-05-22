import 'dart:async';
import 'plugin/plugin_registry.dart';
import 'plugin/plugin_descriptor.dart';
import 'plugin/plugin_handler.dart'
    show PluginHandler, CapabilityResult, RuntimeError;
import 'vocabulary/runtime_route.dart';
import 'vocabulary/runtime_identity.dart';
import 'vocabulary/runtime_permission.dart';
import 'vocabulary/runtime_session.dart';
import 'vocabulary/capability_context.dart';
import 'vocabulary/failure_policy.dart';
import 'kernel/runtime_clock.dart';
import 'kernel/runtime_config.dart';
import '../app_logger.dart';

class CapabilityBinding {
  final String capabilityId;
  final String pluginId;
  final PluginHandler handler;
  final CapabilityDeclaration declaration;
  final RuntimeRoute route;
  final IsolationLevel isolation;
  final int discoveredAt;

  const CapabilityBinding({
    required this.capabilityId,
    required this.pluginId,
    required this.handler,
    required this.declaration,
    required this.route,
    required this.isolation,
    required this.discoveredAt,
  });

  int get timeoutMs => declaration.timeoutMs;
  int get maxRetries => declaration.maxRetries;
  bool get isDestructive => declaration.isDestructive;
  String get permission => declaration.permission;
}

class CapabilityRouter {
  final PluginRegistry _registry;
  final RuntimeClock _clock;
  final Map<String, Completer<CapabilityBinding>> _pendingDiscovery = {};
  final Map<String, CapabilityBinding> _bindingCache = {};
  final Map<String, int> _circuitBreakerFailures = {};
  final Map<String, DateTime> _circuitBreakerOpenUntil = {};
  final Set<String> _routedInvocations = {};

  CapabilityRouter({
    required PluginRegistry registry,
    required RuntimeClock clock,
    required RuntimeConfig config,
  }) : _registry = registry,
       _clock = clock;

  bool wasRoutedThroughRouter(String capabilityId, String callerId) {
    return _routedInvocations.contains('$callerId:$capabilityId');
  }

  int get cachedBindingCount => _bindingCache.length;

  List<CapabilityBinding> get allBindings =>
      List.unmodifiable(_bindingCache.values);

  Future<CapabilityBinding> discover(String capabilityId) async {
    final cached = _bindingCache[capabilityId];
    if (cached != null) return cached;

    final pending = _pendingDiscovery[capabilityId];
    if (pending != null) return pending.future;

    final completer = Completer<CapabilityBinding>();
    _pendingDiscovery[capabilityId] = completer;

    try {
      final binding = await _resolveBinding(capabilityId);
      _bindingCache[capabilityId] = binding;
      completer.complete(binding);
    } catch (e) {
      completer.completeError(e);
    } finally {
      _pendingDiscovery.remove(capabilityId);
    }

    return completer.future;
  }

  Future<CapabilityResult> invoke(
    String capabilityId,
    dynamic params, {
    required RuntimeIdentity caller,
    required RuntimePermission callerPermission,
    RuntimeSession? session,
  }) async {
    if (_isCircuitBreakerOpen(capabilityId)) {
      AppLogger.instance.warning('Circuit breaker open for "$capabilityId"');
      return CapabilityResult.fail(
        const RuntimeError(
          code: 'UNAVAILABLE',
          message: 'Circuit breaker open',
        ),
      );
    }

    final binding = await discover(capabilityId);

    if (!_checkPermission(binding, callerPermission)) {
      return CapabilityResult.fail(
        RuntimeError(
          code: 'PERMISSION_DENIED',
          message:
              'Caller "${caller.identity}" lacks permission for "$capabilityId"',
        ),
      );
    }

    final effectiveSession =
        session ??
        RuntimeSession(
          id: 'session_${_clock.now()}',
          userId: caller.identity,
          createdAt: _clock.now(),
          lastActiveAt: _clock.now(),
        );

    final context = CapabilityContext.create(
      caller: caller,
      permission: callerPermission,
      session: effectiveSession,
      route: binding.route,
      timeoutMs: binding.timeoutMs,
    );

    try {
      _routedInvocations.add('${caller.identity}:$capabilityId');
      final result = await binding.handler
          .invokeCapability(capabilityId, params, context)
          .timeout(
            Duration(milliseconds: binding.timeoutMs),
            onTimeout: () => throw TimeoutException(
              'Capability $capabilityId timed out after ${binding.timeoutMs}ms',
            ),
          );
      _resetCircuitBreaker(capabilityId);
      return result;
    } catch (e) {
      _recordCircuitBreakerFailure(capabilityId);
      if (binding.declaration.maxRetries > 0) {
        return _retryInvoke(
          capabilityId,
          params,
          binding,
          context,
          binding.maxRetries,
        );
      }
      return CapabilityResult.fail(
        RuntimeError(code: 'INVOKE_FAILED', message: e.toString()),
      );
    }
  }

  Future<CapabilityResult> _retryInvoke(
    String capabilityId,
    dynamic params,
    CapabilityBinding binding,
    CapabilityContext context,
    int remainingRetries,
  ) async {
    if (remainingRetries <= 0 || context.shouldAbort) {
      return CapabilityResult.fail(
        const RuntimeError(
          code: 'RETRY_EXHAUSTED',
          message: 'Max retries exhausted',
        ),
      );
    }

    final policy = const FailurePolicy();
    final delay = policy.retry.delayForAttempt(
      binding.maxRetries - remainingRetries,
    );
    await Future.delayed(delay);

    try {
      final result = await binding.handler.invokeCapability(
        capabilityId,
        params,
        context,
      );
      _resetCircuitBreaker(capabilityId);
      return result;
    } catch (e) {
      _recordCircuitBreakerFailure(capabilityId);
      return _retryInvoke(
        capabilityId,
        params,
        binding,
        context,
        remainingRetries - 1,
      );
    }
  }

  void invalidateCache(String capabilityId) {
    _bindingCache.remove(capabilityId);
  }

  void invalidateAll() {
    _bindingCache.clear();
  }

  Future<CapabilityBinding> _resolveBinding(String capabilityId) async {
    final pluginId = _registry.pluginForCapability(capabilityId);
    if (pluginId == null) {
      throw const RuntimeError(
        code: 'NOT_FOUND',
        message: 'No plugin provides this capability',
      );
    }

    final descriptor = _registry.descriptor(pluginId);
    if (descriptor == null) {
      throw const RuntimeError(code: 'NOT_FOUND', message: 'Plugin not found');
    }

    final handler = _registry.handler(pluginId);
    if (handler == null) {
      throw const RuntimeError(code: 'NOT_FOUND', message: 'Handler not found');
    }

    final declaration = descriptor.capability(capabilityId);
    if (declaration == null) {
      throw const RuntimeError(
        code: 'NOT_FOUND',
        message: 'Capability not declared',
      );
    }

    return CapabilityBinding(
      capabilityId: capabilityId,
      pluginId: pluginId,
      handler: handler,
      declaration: declaration,
      route: RuntimeRoute.local(capability: capabilityId, pluginId: pluginId),
      isolation: descriptor.isolation,
      discoveredAt: _clock.now(),
    );
  }

  bool _checkPermission(
    CapabilityBinding binding,
    RuntimePermission callerPermission,
  ) {
    if (binding.permission == 'auto') return true;
    if (binding.permission == 'deny') return false;
    if (binding.permission == 'confirm')
      return callerPermission.hasCapability(binding.capabilityId);
    return callerPermission.hasCapability(binding.capabilityId);
  }

  bool _isCircuitBreakerOpen(String capabilityId) {
    final openUntil = _circuitBreakerOpenUntil[capabilityId];
    if (openUntil == null) return false;
    if (DateTime.now().isAfter(openUntil)) {
      _circuitBreakerOpenUntil.remove(capabilityId);
      return false;
    }
    return true;
  }

  void _recordCircuitBreakerFailure(String capabilityId) {
    _circuitBreakerFailures[capabilityId] =
        (_circuitBreakerFailures[capabilityId] ?? 0) + 1;
    final failures = _circuitBreakerFailures[capabilityId]!;
    if (failures >= 5) {
      _circuitBreakerOpenUntil[capabilityId] = DateTime.now().add(
        const Duration(seconds: 30),
      );
      AppLogger.instance.warning(
        'Circuit breaker opened for "$capabilityId" after $failures failures',
      );
    }
  }

  void _resetCircuitBreaker(String capabilityId) {
    _circuitBreakerFailures.remove(capabilityId);
    _circuitBreakerOpenUntil.remove(capabilityId);
  }
}
