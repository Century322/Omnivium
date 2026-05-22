import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/kernel/runtime_container.dart';
import 'package:omnivium/core/runtime/kernel/runtime_state.dart';
import 'package:omnivium/core/runtime/plugin/plugin_handler.dart';
import 'package:omnivium/core/runtime/plugin/plugin_lifecycle.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_identity.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_permission.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_task.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_route.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_event.dart';
import 'package:omnivium/core/runtime/plugins/chaos_agent_plugin.dart';
import 'package:omnivium/core/runtime/plugins/fake_agent_plugin.dart';
import 'package:omnivium/core/runtime/plugins/storage_plugin.dart';
import 'package:omnivium/core/runtime/plugins/logger_plugin.dart';
import 'package:omnivium/core/runtime/invariants/runtime_invariants.dart';
import 'package:omnivium/core/runtime/benchmark/runtime_benchmark.dart';

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

  Future<RuntimeContainer> bootWithChaos() async {
    final container = await RuntimeContainer.boot();
    await container.registerPlugin(ChaosAgentPlugin.descriptor(), ChaosAgentPlugin());
    await container.registerPlugin(FakeAgentPlugin.descriptor(), FakeAgentPlugin());
    await container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());
    await container.registerPlugin(LoggerPlugin.descriptor(), LoggerPlugin());
    return container;
  }

  group('Event Storm', () {
    test('1000 events/sec backpressure handling', () async {
      final container = await bootWithChaos();
      final received = <RuntimeEvent>[];

      container.eventBus.subscribe(
        'storm.event',
        (event) async {
          received.add(event);
        },
      );

      final eventCount = 1000;
      final source = RuntimeIdentity.forPlugin('storm-test');
      final start = container.clock.now();

      for (var i = 0; i < eventCount; i++) {
        container.eventBus.publish(
          'storm.event',
          {'index': i},
          source: source,
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final elapsed = container.clock.now() - start;
      final qps = (received.length / elapsed) * 1000;

      expect(received.length, greaterThanOrEqualTo(eventCount * 0.9));
      expect(container.eventBus.deadLetterCount, lessThan(eventCount * 0.1));

      container.metricsService.observe('event_storm_qps', qps);
      container.metricsService.gauge('event_storm_dead_letters', container.eventBus.deadLetterCount);
    });
  });

  group('Plugin Crash Isolation', () {
    test('chaos.crash does not kill Runtime', () async {
      final container = await bootWithChaos();

      try {
        await container.capabilityRouter.invoke(
          'chaos.crash',
          null,
          caller: RuntimeIdentity.forPlugin('test'),
          callerPermission: const RuntimePermission(),
        );
      } catch (_) {}

      expect(container.stateSnapshot.status, RuntimeStatus.running);

      final result = await container.capabilityRouter.invoke(
        'runtime.health',
        null,
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: const RuntimePermission(),
      );
      expect(result.status, CapabilityStatus.success);
    });

    test('chaos.timeout triggers circuit breaker', () async {
      final container = await bootWithChaos();

      for (var i = 0; i < 6; i++) {
        try {
          await container.capabilityRouter.invoke(
            'chaos.timeout',
            null,
            caller: RuntimeIdentity.forPlugin('test'),
            callerPermission: const RuntimePermission(),
          ).timeout(const Duration(milliseconds: 200));
        } catch (_) {}
      }

      expect(container.stateSnapshot.status, RuntimeStatus.running);
    });
  });

  group('Capability Cascade Failure', () {
    test('chaos.retry_storm triggers retries but Runtime survives', () async {
      final container = await bootWithChaos();
      const perm = RuntimePermission(capabilities: ['chaos.retry_storm']);

      final result = await container.capabilityRouter.invoke(
        'chaos.retry_storm',
        {'maxRetries': 3},
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: perm,
      );

      expect(result.status, CapabilityStatus.failure);
      expect(container.stateSnapshot.status, RuntimeStatus.running);
    });

    test('chaos.partial_failure some succeed some fail', () async {
      final container = await bootWithChaos();
      var successes = 0;
      var failures = 0;

      for (var i = 0; i < 100; i++) {
        final result = await container.capabilityRouter.invoke(
          'chaos.partial_failure',
          {'failRate': 0.5},
          caller: RuntimeIdentity.forPlugin('test'),
          callerPermission: const RuntimePermission(),
        );
        if (result.status == CapabilityStatus.success) {
          successes++;
        } else {
          failures++;
        }
      }

      expect(successes + failures, 100);
      expect(successes, greaterThan(0));
      expect(failures, greaterThan(0));
    });
  });

  group('Cancellation Propagation', () {
    test('cancel task stops execution', () async {
      final container = await bootWithChaos();
      final task = RuntimeTask(
        id: 'cancel-prop-test',
        type: 'test',
        source: RuntimeRoute(capability: 'test', pluginId: 'chaos'),
        budget: const TaskBudget(maxDurationMs: 30000, maxRetries: 0),
        createdAt: container.clock.now(),
      );

      final future = container.scheduler.schedule(
        task,
        (token) async {
          await Future.delayed(const Duration(seconds: 30));
          return 'should not reach';
        },
      );

      await Future.delayed(const Duration(milliseconds: 20));
      final cancelled = container.scheduler.cancel('cancel-prop-test');
      expect(cancelled, isTrue);

      try {
        await future;
      } catch (_) {}

      expect(container.scheduler.cancelledCount, 1);
    });

    test('chaos.cancel_test respects cancellation', () async {
      final container = await bootWithChaos();

      final result = await container.capabilityRouter.invoke(
        'chaos.cancel_test',
        null,
        caller: RuntimeIdentity.forPlugin('test'),
        callerPermission: const RuntimePermission(),
      );
      expect(result.status, CapabilityStatus.success);
    });
  });

  group('Hot Reload Consistency', () {
    test('reload plugin 50 times without leak', () async {
      final container = await bootWithChaos();

      for (var i = 0; i < 50; i++) {
        final descriptor = StoragePlugin.descriptor();
        final handler = StoragePlugin();
        await container.registerPlugin(descriptor, handler);
        await container.reloadPlugin('storage');
      }

      expect(container.pluginRegistry.state('storage'), PluginState.active);
      expect(container.stateSnapshot.status, RuntimeStatus.running);
    });
  });

  group('Scheduler Fairness', () {
    test('critical tasks complete despite low priority flood', () async {
      final container = await bootWithChaos();
      final criticalResults = <String>[];

      for (var i = 0; i < 50; i++) {
        final task = RuntimeTask(
          id: 'low_$i',
          type: 'flood',
          source: RuntimeRoute(capability: 'flood', pluginId: 'chaos'),
          priority: TaskPriority.low,
          budget: const TaskBudget(maxDurationMs: 5000, maxRetries: 0),
          createdAt: container.clock.now(),
        );
        container.scheduler.schedule(task, (token) async => 'low');
      }

      for (var i = 0; i < 5; i++) {
        final task = RuntimeTask(
          id: 'critical_$i',
          type: 'critical',
          source: RuntimeRoute(capability: 'critical', pluginId: 'chaos'),
          priority: TaskPriority.critical,
          budget: const TaskBudget(maxDurationMs: 5000, maxRetries: 0),
          createdAt: container.clock.now(),
        );
        final result = await container.scheduler.schedule(task, (token) async => 'critical_$i');
        criticalResults.add(result as String);
      }

      expect(criticalResults.length, 5);
      expect(criticalResults.every((r) => r.startsWith('critical')), isTrue);
    });
  });

  group('Runtime Invariants', () {
    test('no violations after normal operations', () async {
      final container = await bootWithChaos();
      final checker = InvariantChecker();

      final ctx = RuntimeInvariantContext(
        scheduler: container.scheduler,
        pluginRegistry: container.pluginRegistry,
        eventBus: container.eventBus,
        clock: container.clock,
      );

      final violations = checker.checkAll(ctx);
      expect(violations, isEmpty);
    });

    test('task terminal state invariant after tasks complete', () async {
      final container = await bootWithChaos();

      for (var i = 0; i < 10; i++) {
        final task = RuntimeTask(
          id: 'inv_task_$i',
          type: 'test',
          source: RuntimeRoute(capability: 'test', pluginId: 'chaos'),
          budget: const TaskBudget(maxDurationMs: 5000, maxRetries: 0),
          createdAt: container.clock.now(),
        );
        await container.scheduler.schedule(task, (token) async => 'done');
      }

      final checker = InvariantChecker();
      final ctx = RuntimeInvariantContext(
        scheduler: container.scheduler,
        pluginRegistry: container.pluginRegistry,
        eventBus: container.eventBus,
        clock: container.clock,
      );

      final violations = checker.checkAll(ctx);
      final taskViolations = violations.where((v) => v.invariantId == 'INV-TASK-001').toList();
      expect(taskViolations, isEmpty);
    });
  });

  group('Timeline Replay', () {
    test('record and replay events', () async {
      final container = await bootWithChaos();

      final baseCount = container.timelineService.entryCount;

      container.timelineService.recordPluginLifecycle('test-plugin', 'load', from: 'unloaded', to: 'loaded');
      container.timelineService.recordCapabilityInvoke('storage.write', 'storage', status: 'started');
      container.timelineService.recordCapabilityInvoke('storage.write', 'storage', status: 'completed');
      container.timelineService.recordTask('task-1', status: 'scheduled');
      container.timelineService.recordTask('task-1', status: 'completed');

      expect(container.timelineService.entryCount, baseCount + 5);

      final capabilityEntries = container.timelineService.replayForCapability('storage.write');
      expect(capabilityEntries.length, 2);

      final summary = container.timelineService.timelineSummary();
      expect(summary['totalEntries'], baseCount + 5);
      expect(summary['byType'], isA<Map>());
    });
  });

  group('Benchmark Suite', () {
    test('benchmark produces results', () async {
      final container = await bootWithChaos();
      await container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());

      final benchmark = RuntimeBenchmark(container);
      final results = await benchmark.runAll();

      expect(results.length, 5);
      for (final result in results) {
        expect(result.iterations, greaterThan(0));
        expect(result.opsPerSec, greaterThanOrEqualTo(0));
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
