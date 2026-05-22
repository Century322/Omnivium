import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/capability_context.dart';

class MetricsPlugin implements PluginHandler {
  final Map<String, int> _counters = {};
  final Map<String, num> _gauges = {};
  final Map<String, List<num>> _histograms = {};

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
    switch (capabilityId) {
      case 'metrics.counter':
        if (params is Map) {
          final name = params['name'] as String;
          final delta = params['delta'] as int? ?? 1;
          _counters[name] = (_counters[name] ?? 0) + delta;
          return CapabilityResult.ok(_counters[name]);
        }
        return CapabilityResult.fail(
          const RuntimeError(
            code: 'INVALID_PARAMS',
            message: 'Expected {name, delta}',
          ),
        );
      case 'metrics.histogram':
        if (params is Map) {
          final name = params['name'] as String;
          final value = params['value'] as num;
          _histograms.putIfAbsent(name, () => []);
          _histograms[name]!.add(value);
          return CapabilityResult.ok(_histograms[name]!.length);
        }
        return CapabilityResult.fail(
          const RuntimeError(
            code: 'INVALID_PARAMS',
            message: 'Expected {name, value}',
          ),
        );
      case 'metrics.trace':
        return CapabilityResult.ok({
          'counters': Map<String, int>.from(_counters),
          'gauges': Map<String, num>.from(_gauges),
          'histograms': _histograms.map((k, v) {
            if (v.isEmpty) return MapEntry(k, <String, dynamic>{});
            final sorted = v.toList()..sort();
            return MapEntry(k, {
              'count': sorted.length,
              'min': sorted.first,
              'max': sorted.last,
              'avg': sorted.reduce((a, b) => a + b) / sorted.length,
            });
          }),
        });
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
    id: 'metrics',
    name: 'Metrics Plugin',
    version: '1.0.0',
    description: 'Runtime metrics collection',
    capabilities: const [
      CapabilityDeclaration(
        id: 'metrics.counter',
        name: 'Counter',
        description: 'Increment a counter metric',
        permission: 'auto',
      ),
      CapabilityDeclaration(
        id: 'metrics.histogram',
        name: 'Histogram',
        description: 'Record a histogram observation',
        permission: 'auto',
      ),
      CapabilityDeclaration(
        id: 'metrics.trace',
        name: 'Trace',
        description: 'Get all metrics snapshot',
        permission: 'auto',
      ),
    ],
  );
}
