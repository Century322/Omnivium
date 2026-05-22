import 'plugin_descriptor.dart';
import 'plugin_lifecycle.dart';
import 'plugin_handler.dart';
import '../vocabulary/runtime_permission.dart';
import '../kernel/runtime_clock.dart';
import '../kernel/runtime_config.dart';
import '../../app_logger.dart';

class PluginEntry {
  final PluginDescriptor descriptor;
  final PluginHandler handler;
  final PluginLifecycle lifecycle;
  final TransportType transport;
  final int registeredAt;

  PluginEntry({
    required this.descriptor,
    required this.handler,
    required this.lifecycle,
    required this.transport,
    required this.registeredAt,
  });
}

class PluginRegistry {
  final Map<String, PluginEntry> _plugins = {};
  final Map<String, String> _capabilityToPlugin = {};
  final RuntimeClock _clock;
  final RuntimeConfig _config;
  final int _maxPlugins;

  PluginRegistry({required RuntimeClock clock, required RuntimeConfig config})
    : _clock = clock,
      _config = config,
      _maxPlugins = config.maxPlugins;

  Map<String, PluginState> get pluginStates =>
      _plugins.map((id, entry) => MapEntry(id, entry.lifecycle.state));

  List<PluginDescriptor> get loadedDescriptors =>
      _plugins.values.map((e) => e.descriptor).toList();

  int get pluginCount => _plugins.length;
  int get activeCount => _plugins.values
      .where((e) => e.lifecycle.state == PluginState.active)
      .length;
  int get capabilityCount => _capabilityToPlugin.length;

  PluginDescriptor? descriptor(String pluginId) =>
      _plugins[pluginId]?.descriptor;

  PluginState? state(String pluginId) => _plugins[pluginId]?.lifecycle.state;

  PluginHandler? handler(String pluginId) => _plugins[pluginId]?.handler;

  String? pluginForCapability(String capabilityId) =>
      _capabilityToPlugin[capabilityId];

  List<String> capabilitiesOf(String pluginId) {
    final entry = _plugins[pluginId];
    if (entry == null) return [];
    return entry.descriptor.capabilityIds;
  }

  Future<bool> register(
    PluginDescriptor descriptor,
    PluginHandler handler,
  ) async {
    if (_plugins.containsKey(descriptor.id)) {
      AppLogger.instance.warning(
        'Plugin "${descriptor.id}" already registered, unloading previous',
      );
      await unload(descriptor.id);
    }

    if (_plugins.length >= _maxPlugins) {
      AppLogger.instance.error(
        'Plugin limit reached ($_maxPlugins), cannot register "${descriptor.id}"',
      );
      return false;
    }

    final transport = _transportForIsolation(descriptor.isolation);
    final entry = PluginEntry(
      descriptor: descriptor,
      handler: handler,
      lifecycle: PluginLifecycle(),
      transport: transport,
      registeredAt: _clock.now(),
    );

    if (!entry.lifecycle.transitionTo(
      PluginState.loaded,
      reason: 'registered',
    )) {
      return false;
    }

    _plugins[descriptor.id] = entry;

    for (final cap in descriptor.capabilities) {
      _capabilityToPlugin[cap.id] = descriptor.id;
    }

    AppLogger.instance.info(
      'Plugin "${descriptor.id}" registered with ${descriptor.capabilities.length} capabilities',
    );

    if (descriptor.lifecycle.autoActivate) {
      await activate(descriptor.id);
    }

    return true;
  }

  Future<bool> activate(String pluginId) async {
    final entry = _plugins[pluginId];
    if (entry == null) return false;

    if (!entry.lifecycle.canTransitionTo(PluginState.active)) {
      AppLogger.instance.warning(
        'Plugin "$pluginId" cannot activate from ${entry.lifecycle.state}',
      );
      return false;
    }

    try {
      entry.lifecycle.transitionTo(PluginState.active, reason: 'activated');
      AppLogger.instance.info('Plugin "$pluginId" activated');
      return true;
    } catch (e) {
      entry.lifecycle.transitionTo(
        PluginState.failed,
        reason: 'activate error: $e',
      );
      AppLogger.instance.error('Plugin "$pluginId" activation failed: $e');
      return false;
    }
  }

  Future<bool> suspend(String pluginId) async {
    final entry = _plugins[pluginId];
    if (entry == null) return false;

    if (!entry.lifecycle.transitionTo(
      PluginState.suspended,
      reason: 'suspended',
    )) {
      return false;
    }

    AppLogger.instance.info('Plugin "$pluginId" suspended');
    return true;
  }

  Future<bool> unload(String pluginId) async {
    final entry = _plugins[pluginId];
    if (entry == null) return false;

    for (final cap in entry.descriptor.capabilities) {
      final owner = _capabilityToPlugin[cap.id];
      if (owner == pluginId) {
        _capabilityToPlugin.remove(cap.id);
      }
    }

    entry.lifecycle.transitionTo(PluginState.unloaded, reason: 'unloaded');
    _plugins.remove(pluginId);

    AppLogger.instance.info('Plugin "$pluginId" unloaded');
    return true;
  }

  Future<bool> reload(String pluginId) async {
    final entry = _plugins[pluginId];
    if (entry == null) return false;

    if (!_config.enableHotReload) {
      AppLogger.instance.warning(
        'Hot reload disabled, cannot reload "$pluginId"',
      );
      return false;
    }

    final descriptor = entry.descriptor;
    final handler = entry.handler;

    await unload(pluginId);
    return register(descriptor, handler);
  }

  void clear() {
    _capabilityToPlugin.clear();
    _plugins.clear();
  }

  TransportType _transportForIsolation(IsolationLevel level) {
    switch (level) {
      case IsolationLevel.level0InProcess:
        return TransportType.inProcess;
      case IsolationLevel.level1IsolatedWorker:
        return TransportType.isolate;
      case IsolationLevel.level2SandboxRuntime:
        return TransportType.wasm;
      case IsolationLevel.level3RemoteNode:
        return TransportType.http;
    }
  }
}
