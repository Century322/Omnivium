import '../plugin/plugin_registry.dart';
import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import 'runtime_clock.dart';
import 'runtime_config.dart';
import 'runtime_state.dart';
import '../vocabulary/runtime_identity.dart';
import '../vocabulary/runtime_session.dart';

abstract class RuntimeContext {
  RuntimeClock get clock;
  RuntimeConfig get config;
  RuntimeIdentity get identity;
  RuntimeStateSnapshot get stateSnapshot;
  PluginRegistry get pluginRegistry;

  RuntimeSession currentSession();
  Future<bool> registerPlugin(
    PluginDescriptor descriptor,
    PluginHandler handler);
  Future<bool> activatePlugin(String pluginId);
  Future<bool> suspendPlugin(String pluginId);
  Future<bool> unloadPlugin(String pluginId);
  Future<bool> reloadPlugin(String pluginId);
}
