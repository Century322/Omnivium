import 'runtime_context.dart';
import 'runtime_clock.dart';
import 'runtime_config.dart';
import 'runtime_state.dart';
import '../plugin/plugin_registry.dart';
import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../capability_router.dart';
import '../event_bus.dart';
import '../scheduler.dart' as rt;
import '../observability/trace_service.dart';
import '../observability/metrics_service.dart';
import '../observability/timeline_service.dart';
import '../governance/policy_engine.dart';
import '../governance/resource_controller.dart';
import '../governance/event_journal.dart';
import '../governance/snapshot_service.dart';
import '../vocabulary/runtime_identity.dart';
import '../vocabulary/runtime_session.dart';
import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/runtime_permission.dart';
import '../../app_logger.dart';

class RuntimeContainer implements RuntimeContext {
  @override
  final RuntimeClock clock;

  @override
  final RuntimeConfig config;

  @override
  RuntimeIdentity identity;

  @override
  final PluginRegistry pluginRegistry;

  late final CapabilityRouter capabilityRouter;
  late final EventBus eventBus;
  late final rt.Scheduler scheduler;
  late final TraceService traceService;
  late final MetricsService metricsService;
  late final TimelineService timelineService;
  late final PolicyEngine policyEngine;
  late final ResourceController resourceController;
  late final EventJournal eventJournal;
  late final SnapshotService snapshotService;

  RuntimeStatus _status = RuntimeStatus.booting;
  RuntimeStatus get status => _status;
  final Map<String, RuntimeSession> _sessions = {};

  static RuntimeContainer? _instance;

  RuntimeContainer._({required this.clock, required this.config})
    : identity = RuntimeIdentity.forRuntime(config.nodeId),
      pluginRegistry = PluginRegistry(clock: clock, config: config) {
    capabilityRouter = CapabilityRouter(
      registry: pluginRegistry,
      clock: clock,
      config: config);
    eventBus = EventBus(clock: clock, config: config);
    scheduler = rt.Scheduler(config: config);
    traceService = TraceService();
    metricsService = MetricsService();
    timelineService = TimelineService(clock);
    policyEngine = PolicyEngine.defaultPolicy();
    resourceController = ResourceController();
    eventJournal = EventJournal(clock: clock);
    snapshotService = SnapshotService(clock);
  }

  static RuntimeContainer get instance {
    final inst = _instance;
    if (inst == null) {
      throw StateError(
        'RuntimeContainer not initialized. Call RuntimeContainer.boot() first.');
    }
    return inst;
  }

  static bool get isBooted {
    final inst = _instance;
    return inst != null && inst._status == RuntimeStatus.running;
  }

  static Future<RuntimeContainer> boot([RuntimeConfig? config]) async {
    final existing = _instance;
    if (existing != null && existing._status == RuntimeStatus.running) {
      AppLogger.instance.warning('RuntimeContainer already booted');
      return existing;
    }

    final effectiveConfig = config ?? const RuntimeConfig();
    final container = RuntimeContainer._(
      clock: RuntimeClock(),
      config: effectiveConfig);

    _instance = container;
    container._status = RuntimeStatus.running;

    container.metricsService.gauge(
      'runtime.boot_time_ms',
      container.clock.now());
    container.metricsService.increment('runtime.boot');
    container.eventJournal.append('runtime.boot', {
      'nodeId': effectiveConfig.nodeId,
      'version': effectiveConfig.runtimeVersion,
    });

    AppLogger.instance.info(
      'RuntimeContainer booted: nodeId=${effectiveConfig.nodeId}, version=${effectiveConfig.runtimeVersion}');

    return container;
  }

  void updateIdentity(RuntimeIdentity newIdentity) {
    identity = newIdentity;
    metricsService.increment('runtime.identity.updated');
    eventJournal.append('identity.updated', {'nodeId': newIdentity.identity});
  }

  Future<dynamic> sendMessage(RuntimeMessage message) async {
    eventJournal.append('message.sent', {
      'messageId': message.id,
      'type': message.type,
      'source': message.source.pluginId,
      'target': message.target.pluginId,
    });

    if (message.type == 'capability.invoke') {
      return capabilityRouter.invoke(
        message.target.capability,
        message.payload,
        caller: RuntimeIdentity.forPlugin(message.source.pluginId),
        callerPermission: RuntimePermission());
    }

    if (message.type == 'event.emit') {
      final payload = message.payload as Map<String, dynamic>;
      eventBus.publish(
        payload['eventType'] ?? message.type,
        payload,
        source: RuntimeIdentity.forPlugin(message.source.pluginId),
        scope: PropagationScope.local);
      return null;
    }

    eventJournal.append('message.unknown_type', {'type': message.type});
    return null;
  }

  static Future<void> shutdown() async {
    final inst = _instance;
    if (inst == null) return;

    inst._status = RuntimeStatus.shuttingDown;
    inst.metricsService.increment('runtime.shutdown');

    inst.snapshotService.take(
      status: RuntimeStatus.shuttingDown,
      pluginStates: inst.pluginRegistry.pluginStates.map(
        (k, v) => MapEntry(k, v)),
      sessions: inst._sessions,
      capabilityCache: inst.pluginRegistry.loadedDescriptors
          .expand((d) => d.capabilityIds)
          .toList(),
      resourceUsage: inst.resourceController.usage);

    inst.eventJournal.append('runtime.shutdown', {
      'snapshotId': inst.snapshotService.latest?.snapshotId,
    });

    inst.scheduler.cancelAll();

    final pluginIds = inst.pluginRegistry.loadedDescriptors
        .map((d) => d.id)
        .toList();
    for (final id in pluginIds) {
      await inst.pluginRegistry.unload(id);
    }

    inst._sessions.clear();
    inst.capabilityRouter.invalidateAll();

    _instance = null;
    AppLogger.instance.info('RuntimeContainer shutdown complete');
  }

  @override
  RuntimeStateSnapshot get stateSnapshot => RuntimeStateSnapshot(
    status: _status,
    activeSessionCount: _sessions.values.where((s) => s.isActive).length,
    activeTaskCount: scheduler.runningCount,
    loadedPluginCount: pluginRegistry.pluginCount,
    activePluginCount: pluginRegistry.activeCount,
    capabilityCount: pluginRegistry.capabilityCount,
    bootTimeMs: clock.bootTimeMs,
    uptimeMs: clock.uptimeMs);

  @override
  RuntimeSession currentSession() {
    final activeSession = _sessions.values.where((s) => s.isActive).firstOrNull;
    if (activeSession != null) return activeSession;

    final session = RuntimeSession(
      id: 'session_${clock.now()}',
      userId: 'default',
      createdAt: clock.now(),
      lastActiveAt: clock.now());
    _sessions[session.id] = session;
    return session;
  }

  @override
  Future<bool> registerPlugin(
    PluginDescriptor descriptor,
    PluginHandler handler) async {
    final trace = traceService.startTrace();
    final span = traceService.startSpan(
      traceId: trace.traceId,
      operation: 'plugin.register',
      pluginId: descriptor.id);

    final result = await pluginRegistry.register(descriptor, handler);

    span.finish(status: result ? 'ok' : 'error');
    metricsService.increment(
      'plugin.register',
      labels: {'pluginId': descriptor.id, 'result': result ? 'ok' : 'error'});

    if (result) {
      eventJournal.appendPluginTransition(descriptor.id, 'unloaded', 'active');
      timelineService.recordPluginLifecycle(
        descriptor.id,
        'register',
        from: 'unloaded',
        to: 'active');
    }

    return result;
  }

  @override
  Future<bool> activatePlugin(String pluginId) =>
      pluginRegistry.activate(pluginId);

  @override
  Future<bool> suspendPlugin(String pluginId) =>
      pluginRegistry.suspend(pluginId);

  @override
  Future<bool> unloadPlugin(String pluginId) => pluginRegistry.unload(pluginId);

  @override
  Future<bool> reloadPlugin(String pluginId) => pluginRegistry.reload(pluginId);
}
