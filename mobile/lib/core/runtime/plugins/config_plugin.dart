import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/capability_context.dart';
import 'persistence_backend.dart';

class ConfigPlugin implements PluginHandler {
  final Map<String, dynamic> _config = {};
  final Map<String, List<void Function(String key, dynamic value)>> _watchers =
      {};
  final PersistenceBackend? _persistence;
  bool _loaded = false;

  ConfigPlugin({PersistenceBackend? persistence}) : _persistence = persistence;

  Future<void> loadFromPersistence() async {
    if (_persistence == null || _loaded) return;
    final keys = await _persistence.listKeys('cfg_');
    for (final key in keys) {
      final data = await _persistence.read(key);
      if (data != null) {
        _config[key.replaceFirst('cfg_', '')] = data['value'];
      }
    }
    _loaded = true;
  }

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
    if (!_loaded) await loadFromPersistence();
    switch (capabilityId) {
      case 'config.get':
        final key = params is Map ? params['key'] as String : params as String;
        return CapabilityResult.ok(_config[key]);
      case 'config.set':
        if (params is Map) {
          final key = params['key'] as String;
          final value = params['value'];
          _config[key] = value;
          if (_persistence != null) {
            await _persistence.write('cfg_$key', {'value': value});
          }
          for (final watcher in _watchers[key] ?? []) {
            watcher(key, value);
          }
        }
        return CapabilityResult.ok(true);
      case 'config.watch':
        if (params is Map) {
          final key = params['key'] as String;
          _watchers.putIfAbsent(key, () => []);
        }
        return CapabilityResult.ok(true);
      default:
        return CapabilityResult.fail(
          RuntimeError(
            code: 'UNKNOWN_CAPABILITY',
            message: 'Unknown capability: $capabilityId',
          ),
        );
    }
  }

  static PluginDescriptor descriptor() => PluginDescriptor(
    id: 'config',
    name: 'Config Plugin',
    version: '1.0.0',
    description: 'Runtime configuration management',
    capabilities: const [
      CapabilityDeclaration(
        id: 'config.get',
        name: 'Get Config',
        description: 'Get a config value',
        permission: 'auto',
      ),
      CapabilityDeclaration(
        id: 'config.set',
        name: 'Set Config',
        description: 'Set a config value',
        permission: 'confirm',
      ),
      CapabilityDeclaration(
        id: 'config.watch',
        name: 'Watch Config',
        description: 'Watch a config key for changes',
        permission: 'auto',
      ),
    ],
  );
}
