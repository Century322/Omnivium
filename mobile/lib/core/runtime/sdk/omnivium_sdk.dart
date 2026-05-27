import '../kernel/runtime_container.dart';
import '../kernel/runtime_config.dart';
import '../kernel/runtime_state.dart';
import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../vocabulary/runtime_identity.dart';
import '../vocabulary/runtime_permission.dart';
import '../vocabulary/runtime_session.dart';
import '../distributed/distributed_runtime.dart';
import '../plugins/logger_plugin.dart';
import '../plugins/storage_plugin.dart';
import '../plugins/config_plugin.dart';
import '../plugins/metrics_plugin.dart';
import '../plugins/notification_plugin.dart';
import '../plugins/memory_plugin.dart';
import '../plugins/persistence_backend.dart';

class OmniviumSDK {
  static OmniviumSDK? _instance;

  RuntimeContainer? _container;
  DistributedRuntime? _distributed;

  OmniviumSDK._();

  static OmniviumSDK get instance {
    var inst = _instance;
    if (inst == null) {
      inst = OmniviumSDK._();
      _instance = inst;
    }
    return inst;
  }

  bool get isInitialized => _container != null && RuntimeContainer.isBooted;
  RuntimeContainer get container {
    final c = _container;
    if (c == null)
      throw StateError('OmniviumSDK not initialized. Call init() first.');
    return c;
  }

  DistributedRuntime? get distributed => _distributed;

  static Future<OmniviumSDK> init({
    RuntimeConfig? config,
    PersistenceBackend? persistence,
  }) async {
    final sdk = OmniviumSDK.instance;
    sdk._container = await RuntimeContainer.boot(config);
    await sdk._registerBuiltinPlugins(persistence ?? InMemoryPersistence());
    return sdk;
  }

  Future<void> _registerBuiltinPlugins(PersistenceBackend persistence) async {
    final container = _container;
    if (container == null) return;
    final plugins = <(PluginDescriptor, PluginHandler)>[
      (LoggerPlugin.descriptor(), LoggerPlugin()),
      (StoragePlugin.descriptor(), StoragePlugin(persistence: persistence)),
      (ConfigPlugin.descriptor(), ConfigPlugin(persistence: persistence)),
      (MetricsPlugin.descriptor(), MetricsPlugin()),
      (NotificationPlugin.descriptor(), NotificationPlugin()),
      (MemoryPlugin.descriptor(), MemoryPlugin(persistence: persistence)),
    ];
    for (final (descriptor, handler) in plugins) {
      await container.registerPlugin(descriptor, handler);
      await container.activatePlugin(descriptor.id);
    }
  }

  static Future<OmniviumSDK> initDistributed(
    DistributedRuntimeConfig config,
  ) async {
    final sdk = OmniviumSDK.instance;
    sdk._container = await RuntimeContainer.boot();
    final distributed = DistributedRuntime(config);
    sdk._distributed = distributed;
    await distributed.start();
    return sdk;
  }

  static Future<void> shutdown() async {
    final sdk = OmniviumSDK.instance;
    final distributed = sdk._distributed;
    if (distributed != null) {
      await distributed.stop();
      distributed.dispose();
      sdk._distributed = null;
    }
    await RuntimeContainer.shutdown();
    sdk._container = null;
  }

  PluginBuilder createPlugin(String id) => PluginBuilder(id, this);

  CapabilityBuilder defineCapability(String id) => CapabilityBuilder(id);

  Future<CapabilityResult> invokeCapability(
    String capabilityId, {
    dynamic params,
    int timeoutMs = 30000,
  }) async {
    final container = this.container;
    final identity = RuntimeIdentity.forPlugin('sdk-caller');
    final permission = const RuntimePermission();

    final decision = container.policyEngine.evaluate(
      callerId: identity.identity,
      targetCapability: capabilityId,
    );

    if (!decision.allowed) {
      return CapabilityResult.fail(
        RuntimeError.permissionDenied(
          message: 'Policy denied: ${decision.matchedRuleId}',
        ),
      );
    }

    if (!container.resourceController.tryAcquireTokens(1)) {
      return CapabilityResult.fail(
        RuntimeError.unavailable(message: 'Token budget exceeded'),
      );
    }

    return container.capabilityRouter.invoke(
      capabilityId,
      params,
      caller: identity,
      callerPermission: permission,
    );
  }

  Future<CapabilityResult> invokeRemote(
    String capabilityId, {
    dynamic params,
    int timeoutMs = 30000,
  }) async {
    final dist = _distributed;
    if (dist == null) {
      return CapabilityResult.fail(
        RuntimeError.unavailable(
          message: 'Distributed runtime not initialized',
        ),
      );
    }

    final route = dist.capabilityRouter.route(capabilityId);
    if (!route.isAvailable) {
      return CapabilityResult.fail(
        RuntimeError.notFound(
          message: 'Capability not available: $capabilityId (${route.reason})',
        ),
      );
    }

    if (route.isLocal) {
      return invokeCapability(
        capabilityId,
        params: params,
        timeoutMs: timeoutMs,
      );
    }

    final lease = dist.leaseManager.tryAcquire('remote_$capabilityId');
    if (lease == null) {
      return CapabilityResult.fail(
        RuntimeError.unavailable(
          message: 'Could not acquire lease for $capabilityId',
        ),
      );
    }

    try {
      final result = await dist.sendAndReceive(
        capabilityId: capabilityId,
        targetNodeId: route.targetNodeId!,
        params: params,
        timeout: Duration(milliseconds: timeoutMs),
      );
      return result;
    } finally {
      dist.leaseManager.release(lease.sessionId);
    }
  }

  RuntimeSession createSession({String? userId}) {
    final container = this.container;
    return RuntimeSession(
      id: 'sdk_session_${container.clock.now()}',
      userId: userId ?? 'sdk-user',
      createdAt: container.clock.now(),
      lastActiveAt: container.clock.now(),
    );
  }

  RuntimeStateSnapshot inspect() => container.stateSnapshot;

  Map<String, dynamic> inspectDistributed() {
    final dist = _distributed;
    if (dist == null) return {'initialized': false};

    return {
      'initialized': true,
      'nodeId': dist.nodeId,
      'state': dist.state.name,
      'aliveNodes': dist.nodeDiscovery.aliveCount,
      'localCapabilities': dist.capabilityRouter.localCapabilityCount,
      'remoteCapabilities': dist.capabilityRouter.remoteCapabilityCount,
      'activeLeases': dist.leaseManager.activeLeaseCount,
    };
  }

  List<Map<String, dynamic>> listPlugins() {
    final container = this.container;
    return container.pluginRegistry.loadedDescriptors
        .map(
          (d) => {
            'id': d.id,
            'name': d.name,
            'version': d.version,
            'capabilities': d.capabilityIds,
            'state':
                container.pluginRegistry.pluginStates[d.id]?.name ?? 'unknown',
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> listCapabilities() {
    final container = this.container;
    final descriptors = container.pluginRegistry.loadedDescriptors;
    final caps = <Map<String, dynamic>>[];
    for (final d in descriptors) {
      for (final c in d.capabilities) {
        caps.add({
          'id': c.id,
          'name': c.name,
          'pluginId': d.id,
          'channel': c.channel,
          'permission': c.permission,
        });
      }
    }
    return caps;
  }

  List<Map<String, dynamic>> listJournalEntries({int? limit}) {
    final container = this.container;
    final entries = container.eventJournal.replay();
    final limited = limit != null ? entries.take(limit).toList() : entries;
    return limited
        .map(
          (e) => {
            'sequence': e.sequence,
            'type': e.type,
            'timestamp': e.timestamp,
            'data': e.data,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> listTraces({int? limit}) {
    final container = this.container;
    final traces = container.traceService.recentTraces(limit: limit ?? 50);
    return traces
        .map(
          (t) => {
            'traceId': t.traceId,
            'createdAt': t.createdAt,
            'spanCount': t.spans.length,
            'totalDurationMs': t.totalDurationMs,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> listNodes() {
    final dist = _distributed;
    if (dist == null) return [];

    return dist.nodeDiscovery.allNodes
        .map(
          (n) => {
            'nodeId': n.nodeId,
            'address': n.addressKey,
            'role': n.role.name,
            'state': n.state.name,
            'incarnation': n.incarnation,
          },
        )
        .toList();
  }
}

class PluginBuilder {
  final String _id;
  final OmniviumSDK _sdk;
  String _name = '';
  String _version = '1.0.0';
  String _description = '';
  String _author = '';
  final List<CapabilityDeclaration> _capabilities = [];
  RuntimePermission _permissions = const RuntimePermission();
  IsolationLevel _isolation = IsolationLevel.level0InProcess;

  PluginBuilder(this._id, this._sdk);

  PluginBuilder name(String n) {
    _name = n;
    return this;
  }

  PluginBuilder version(String v) {
    _version = v;
    return this;
  }

  PluginBuilder description(String d) {
    _description = d;
    return this;
  }

  PluginBuilder author(String a) {
    _author = a;
    return this;
  }

  PluginBuilder addCapability(CapabilityDeclaration cap) {
    _capabilities.add(cap);
    return this;
  }

  PluginBuilder permissions(RuntimePermission p) {
    _permissions = p;
    return this;
  }

  PluginBuilder isolation(IsolationLevel level) {
    _isolation = level;
    return this;
  }

  PluginDescriptor build() => PluginDescriptor(
    id: _id,
    name: _name,
    version: _version,
    description: _description,
    author: _author,
    capabilities: _capabilities,
    permissions: _permissions,
    isolation: _isolation,
  );

  Future<bool> register(PluginHandler handler) async {
    final descriptor = build();
    return _sdk.container.registerPlugin(descriptor, handler);
  }
}

class CapabilityBuilder {
  final String _id;
  String _name = '';
  String _description = '';
  String _channel = 'slow';
  String _permission = 'confirm';
  bool _isDestructive = false;
  int _timeoutMs = 30000;
  int _maxRetries = 3;

  CapabilityBuilder(this._id);

  CapabilityBuilder name(String n) {
    _name = n;
    return this;
  }

  CapabilityBuilder description(String d) {
    _description = d;
    return this;
  }

  CapabilityBuilder channel(String c) {
    _channel = c;
    return this;
  }

  CapabilityBuilder permission(String p) {
    _permission = p;
    return this;
  }

  CapabilityBuilder destructive(bool d) {
    _isDestructive = d;
    return this;
  }

  CapabilityBuilder timeout(int ms) {
    _timeoutMs = ms;
    return this;
  }

  CapabilityBuilder maxRetries(int r) {
    _maxRetries = r;
    return this;
  }

  CapabilityDeclaration build() => CapabilityDeclaration(
    id: _id,
    name: _name,
    description: _description,
    channel: _channel,
    permission: _permission,
    isDestructive: _isDestructive,
    timeoutMs: _timeoutMs,
    maxRetries: _maxRetries,
  );
}
