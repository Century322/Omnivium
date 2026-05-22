import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/capability_context.dart';
import 'persistence_backend.dart';

class StoragePlugin implements PluginHandler {
  final Map<String, dynamic> _store = {};
  final PersistenceBackend? _persistence;
  bool _loaded = false;

  StoragePlugin({PersistenceBackend? persistence}) : _persistence = persistence;

  Future<void> loadFromPersistence() async {
    if (_persistence == null || _loaded) return;
    final keys = await _persistence.listKeys('store_');
    for (final key in keys) {
      final data = await _persistence.read(key);
      if (data != null) {
        _store[key.replaceFirst('store_', '')] = data['value'];
      }
    }
    _loaded = true;
  }

  @override
  Future<HandlerResult> handleMessage(RuntimeMessage message, CapabilityContext context) async {
    return HandlerResult.ok();
  }

  @override
  Future<HandlerResult> handleEvent(RuntimeEvent event, CapabilityContext context) async {
    return HandlerResult.ok();
  }

  @override
  Future<CapabilityResult> invokeCapability(String capabilityId, dynamic params, CapabilityContext context) async {
    if (!_loaded) await loadFromPersistence();
    switch (capabilityId) {
      case 'storage.read':
        final key = params is Map ? params['key'] as String : params as String;
        final value = _store[key];
        if (value == null) {
          return CapabilityResult.fail(
            RuntimeError(code: 'NOT_FOUND', message: 'Key not found: $key'),
          );
        }
        return CapabilityResult.ok(value);
      case 'storage.write':
        if (params is Map) {
          final key = params['key'] as String;
          final value = params['value'];
          _store[key] = value;
          if (_persistence != null) {
            await _persistence.write('store_$key', {'value': value});
          }
        }
        return CapabilityResult.ok(true);
      case 'storage.delete':
        final key = params is Map ? params['key'] as String : params as String;
        _store.remove(key);
        if (_persistence != null) {
          await _persistence.delete('store_$key');
        }
        return CapabilityResult.ok(true);
      case 'storage.list':
        return CapabilityResult.ok(_store.keys.toList());
      default:
        return CapabilityResult.fail(
          RuntimeError(code: 'UNKNOWN_CAPABILITY', message: 'Unknown capability: $capabilityId'),
        );
    }
  }

  static PluginDescriptor descriptor() => PluginDescriptor(
        id: 'storage',
        name: 'Storage Plugin',
        version: '1.0.0',
        description: 'Key-value storage',
        capabilities: const [
          CapabilityDeclaration(
            id: 'storage.read',
            name: 'Read',
            description: 'Read a value by key',
            permission: 'auto',
          ),
          CapabilityDeclaration(
            id: 'storage.write',
            name: 'Write',
            description: 'Write a key-value pair',
            permission: 'confirm',
          ),
          CapabilityDeclaration(
            id: 'storage.delete',
            name: 'Delete',
            description: 'Delete a key',
            permission: 'confirm',
            isDestructive: true,
          ),
          CapabilityDeclaration(
            id: 'storage.list',
            name: 'List',
            description: 'List all keys',
            permission: 'auto',
          ),
        ],
      );
}
