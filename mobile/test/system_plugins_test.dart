import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/kernel/runtime_container.dart';
import 'package:omnivium/core/runtime/plugin/plugin_handler.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_identity.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_permission.dart';
import 'package:omnivium/core/runtime/plugins/logger_plugin.dart';
import 'package:omnivium/core/runtime/plugins/storage_plugin.dart';
import 'package:omnivium/core/runtime/plugins/config_plugin.dart';
import 'package:omnivium/core/runtime/plugins/metrics_plugin.dart';
import 'package:omnivium/core/runtime/plugins/notification_plugin.dart';
import 'package:omnivium/core/runtime/plugins/fake_agent_plugin.dart';
import 'package:omnivium/core/runtime/plugins/memory_plugin.dart';

void main() {
  setUp(() async {
    if (RuntimeContainer.isBooted) {
      await RuntimeContainer.shutdown();
    }
  });

  tearDown(() async {
    if (RuntimeContainer.isBooted) {
      await RuntimeContainer.shutdown();
    }
  });

  Future<void> bootWithSystemPlugins() async {
    final container = await RuntimeContainer.boot();
    await container.registerPlugin(LoggerPlugin.descriptor(), LoggerPlugin());
    await container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());
    await container.registerPlugin(ConfigPlugin.descriptor(), ConfigPlugin());
    await container.registerPlugin(MetricsPlugin.descriptor(), MetricsPlugin());
    await container.registerPlugin(
      NotificationPlugin.descriptor(),
      NotificationPlugin(),
    );
    await container.registerPlugin(
      FakeAgentPlugin.descriptor(),
      FakeAgentPlugin(),
    );
    await container.registerPlugin(MemoryPlugin.descriptor(), MemoryPlugin());
  }

  group('LoggerPlugin', () {
    test('runtime.info returns version and uptime', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;

      final result = await container.capabilityRouter.invoke(
        'runtime.info',
        null,
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: const RuntimePermission(),
      );
      expect(result.status, CapabilityStatus.success);
      expect(result.data, isA<Map>());
      expect((result.data as Map<String, dynamic>)['version'], '1.0.0');
    });

    test('runtime.health returns healthy', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;

      final result = await container.capabilityRouter.invoke(
        'runtime.health',
        null,
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: const RuntimePermission(),
      );
      expect(result.status, CapabilityStatus.success);
      expect((result.data as Map<String, dynamic>)['status'], 'healthy');
    });
  });

  group('StoragePlugin', () {
    test('write and read', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;
      const perm = RuntimePermission(
        capabilities: ['storage.write', 'storage.read'],
      );

      await container.capabilityRouter.invoke(
        'storage.write',
        {'key': 'test_key', 'value': 'test_value'},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );

      final result = await container.capabilityRouter.invoke(
        'storage.read',
        'test_key',
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      expect(result.status, CapabilityStatus.success);
      expect(result.data, 'test_value');
    });

    test('read non-existent key fails', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;

      final result = await container.capabilityRouter.invoke(
        'storage.read',
        'non_existent',
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: const RuntimePermission(),
      );
      expect(result.status, CapabilityStatus.failure);
    });

    test('list keys after writes', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;
      const perm = RuntimePermission(
        capabilities: ['storage.write', 'storage.list'],
      );

      await container.capabilityRouter.invoke(
        'storage.write',
        {'key': 'k1', 'value': 'v1'},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      await container.capabilityRouter.invoke(
        'storage.write',
        {'key': 'k2', 'value': 'v2'},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );

      final result = await container.capabilityRouter.invoke(
        'storage.list',
        null,
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      expect(result.status, CapabilityStatus.success);
      expect(result.data, containsAll(['k1', 'k2']));
    });
  });

  group('ConfigPlugin', () {
    test('set and get', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;
      const perm = RuntimePermission(
        capabilities: ['config.set', 'config.get'],
      );

      await container.capabilityRouter.invoke(
        'config.set',
        {'key': 'theme', 'value': 'dark'},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );

      final result = await container.capabilityRouter.invoke(
        'config.get',
        'theme',
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      expect(result.status, CapabilityStatus.success);
      expect(result.data, 'dark');
    });
  });

  group('MetricsPlugin', () {
    test('counter increments', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;

      await container.capabilityRouter.invoke(
        'metrics.counter',
        {'name': 'requests', 'delta': 1},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: const RuntimePermission(),
      );
      await container.capabilityRouter.invoke(
        'metrics.counter',
        {'name': 'requests', 'delta': 5},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: const RuntimePermission(),
      );

      final result = await container.capabilityRouter.invoke(
        'metrics.trace',
        null,
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: const RuntimePermission(),
      );
      expect(result.status, CapabilityStatus.success);
      expect(((result.data as Map<String, dynamic>)['counters'] as Map<String, dynamic>)['requests'], 6);
    });
  });

  group('FakeAgentPlugin', () {
    test('agent.chat returns fake response', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;

      final result = await container.capabilityRouter.invoke(
        'agent.chat',
        {'message': 'Hello'},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: const RuntimePermission(),
      );
      expect(result.status, CapabilityStatus.success);
      expect((result.data as Map<String, dynamic>)['response'], contains('Hello'));
      expect((result.data as Map<String, dynamic>)['model'], 'fake-agent-v1');
    });

    test('agent.execute with parallel tasks', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;
      const perm = RuntimePermission(capabilities: ['agent.execute']);

      final result = await container.capabilityRouter.invoke(
        'agent.execute',
        {'tool': 'parallel'},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      expect(result.status, CapabilityStatus.success);
      expect((result.data as Map<String, dynamic>)['results'], hasLength(3));
    });

    test('agent.execute with fail tool returns error', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;
      const perm = RuntimePermission(capabilities: ['agent.execute']);

      final result = await container.capabilityRouter.invoke(
        'agent.execute',
        {'tool': 'fail'},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      expect(result.status, CapabilityStatus.failure);
    });

    test('agent.cancel returns cancelled', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;

      final result = await container.capabilityRouter.invoke(
        'agent.cancel',
        null,
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: const RuntimePermission(),
      );
      expect(result.status, CapabilityStatus.success);
      expect((result.data as Map<String, dynamic>)['cancelled'], true);
    });
  });

  group('MemoryPlugin', () {
    test('write, read, and search', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;
      const perm = RuntimePermission(
        capabilities: ['memory.write', 'memory.read', 'memory.search'],
      );

      final writeResult = await container.capabilityRouter.invoke(
        'memory.write',
        {
          'content': 'Omnivium is an AI super platform',
          'category': 'project',
          'importance': 0.9,
        },
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      expect(writeResult.status, CapabilityStatus.success);
      expect((writeResult.data as Map<String, dynamic>)['created'], true);

      final memId = (writeResult.data as Map<String, dynamic>)['id'] as String;

      final readResult = await container.capabilityRouter.invoke(
        'memory.read',
        memId,
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      expect(readResult.status, CapabilityStatus.success);
      expect((readResult.data as Map<String, dynamic>)['content'], contains('Omnivium'));

      final searchResult = await container.capabilityRouter.invoke(
        'memory.search',
        {'query': 'AI'},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      expect(searchResult.status, CapabilityStatus.success);
      expect((searchResult.data as Map<String, dynamic>)['count'], greaterThan(0));
    });

    test('embed returns vector', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;
      const perm = RuntimePermission(
        capabilities: ['memory.write', 'memory.embed'],
      );

      final writeResult = await container.capabilityRouter.invoke(
        'memory.write',
        {'content': 'test embedding'},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      final memId = (writeResult.data as Map<String, dynamic>)['id'] as String;

      final embedResult = await container.capabilityRouter.invoke(
        'memory.embed',
        memId,
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );
      expect(embedResult.status, CapabilityStatus.success);
      expect((embedResult.data as Map<String, dynamic>)['dimensions'], 8);
      expect((embedResult.data as Map<String, dynamic>)['embedding'], isA<List>());
    });
  });

  group('Observability', () {
    test('TraceService creates and finishes spans', () async {
      final container = await RuntimeContainer.boot();
      final trace = container.traceService.startTrace();
      final span = container.traceService.startSpan(
        traceId: trace.traceId,
        operation: 'test.op',
        pluginId: 'test-plugin',
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      container.traceService.finishSpan(span);

      expect(span.endTimeMs, isNotNull);
      expect(span.durationMs, greaterThan(0));
      expect(span.status, 'ok');

      final retrieved = container.traceService.getTrace(trace.traceId);
      expect(retrieved, isNotNull);
      expect(retrieved!.spans.length, 1);
    });

    test('MetricsService counters and gauges', () async {
      final container = await RuntimeContainer.boot();
      container.metricsService.increment('test.counter');
      container.metricsService.increment('test.counter', delta: 4);
      container.metricsService.gauge('test.gauge', 42.5);

      expect(container.metricsService.getCounter('test.counter'), 5);
      expect(container.metricsService.getGauge('test.gauge'), 42.5);
    });

    test('MetricsService histogram', () async {
      final container = await RuntimeContainer.boot();
      container.metricsService.observe('latency', 100);
      container.metricsService.observe('latency', 200);
      container.metricsService.observe('latency', 300);

      final summary = container.metricsService.getHistogram('latency');
      expect(summary, isNotNull);
      expect(summary!['count'], 3);
      expect(summary['min'], 100);
      expect(summary['max'], 300);
    });
  });

  group('Capability Taxonomy', () {
    test('all system plugins follow domain.action naming', () async {
      await bootWithSystemPlugins();
      final container = RuntimeContainer.instance;
      final descriptors = container.pluginRegistry.loadedDescriptors;

      for (final desc in descriptors) {
        for (final cap in desc.capabilities) {
          final parts = cap.id.split('.');
          expect(
            parts.length,
            greaterThanOrEqualTo(2),
            reason: '${cap.id} must follow domain.action format',
          );
          expect(
            parts[0],
            matches(r'^[a-z]+$'),
            reason: '${cap.id} domain must be lowercase',
          );
        }
      }
    });
  });
}
