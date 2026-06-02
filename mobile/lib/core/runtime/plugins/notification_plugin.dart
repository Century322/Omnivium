import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/capability_context.dart';
import '../vocabulary/capability_params.dart';

class NotificationPlugin implements PluginHandler {
  final List<Map<String, dynamic>> _notifications = [];

  @override
  Future<HandlerResult> handleMessage(
    RuntimeMessage message,
    CapabilityContext context) async {
    return HandlerResult.ok();
  }

  @override
  Future<HandlerResult> handleEvent(
    RuntimeEvent event,
    CapabilityContext context) async {
    if (event.type == 'notification.push') {
      _notifications.add({
        'payload': event.payload,
        'timestamp': event.timestamp,
      });
    }
    return HandlerResult.ok();
  }

  @override
  Future<CapabilityResult> invokeCapability(
    String capabilityId,
    CapabilityParams params,
    CapabilityContext context) async {
    switch (capabilityId) {
      case 'notification.push':
        _notifications.add({
          'payload': params,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        return CapabilityResult.ok(true);
      case 'notification.local':
        final count = _notifications.length;
        return CapabilityResult.ok({
          'count': count,
          'recent': _notifications.reversed.take(10).toList(),
        });
      default:
        return CapabilityResult.fail(
          RuntimeError(
            code: 'UNKNOWN_CAPABILITY',
            message: 'Unknown capability: $capabilityId'));
    }
  }

  static PluginDescriptor descriptor() => PluginDescriptor(
    id: 'notification',
    name: 'Notification Plugin',
    version: '1.0.0',
    description: 'Runtime notification management',
    capabilities: const [
      CapabilityDeclaration(
        id: 'notification.push',
        name: 'Push',
        description: 'Push a notification',
        permission: 'auto'),
      CapabilityDeclaration(
        id: 'notification.local',
        name: 'Local',
        description: 'Get local notifications',
        permission: 'auto'),
    ]);
}
