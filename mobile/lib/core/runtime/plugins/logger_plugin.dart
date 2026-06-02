import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/capability_context.dart';
import '../../app_logger.dart';
import '../vocabulary/capability_params.dart';

class LoggerPlugin implements PluginHandler {
  @override
  Future<HandlerResult> handleMessage(
    RuntimeMessage message,
    CapabilityContext context) async {
    AppLogger.instance.info(
      '[LoggerPlugin] message: ${message.type} from ${message.source.pluginId}');
    return HandlerResult.ok();
  }

  @override
  Future<HandlerResult> handleEvent(
    RuntimeEvent event,
    CapabilityContext context) async {
    AppLogger.instance.info(
      '[LoggerPlugin] event: ${event.type} phase=${event.phase.name}');
    return HandlerResult.ok();
  }

  @override
  Future<CapabilityResult> invokeCapability(
    String capabilityId,
    CapabilityParams params,
    CapabilityContext context) async {
    switch (capabilityId) {
      case 'runtime.info':
        return CapabilityResult.ok({
          'version': '1.0.0',
          'uptime': context.session.lastActiveAt - context.session.createdAt,
          'pluginId': context.route.pluginId,
        });
      case 'runtime.health':
        return CapabilityResult.ok({
          'status': 'healthy',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      default:
        return CapabilityResult.fail(
          RuntimeError(
            code: 'UNKNOWN_CAPABILITY',
            message: 'Unknown capability: $capabilityId'));
    }
  }

  static PluginDescriptor descriptor() => PluginDescriptor(
    id: 'logger',
    name: 'Logger Plugin',
    version: '1.0.0',
    description: 'Runtime logging and health check',
    capabilities: const [
      CapabilityDeclaration(
        id: 'runtime.info',
        name: 'Runtime Info',
        description: 'Get runtime information',
        permission: 'auto'),
      CapabilityDeclaration(
        id: 'runtime.health',
        name: 'Health Check',
        description: 'Check runtime health',
        permission: 'auto'),
    ]);
}
