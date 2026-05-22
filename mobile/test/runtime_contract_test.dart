import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/kernel/runtime_container.dart';
import 'package:omnivium/core/runtime/kernel/runtime_config.dart';
import 'package:omnivium/core/runtime/kernel/runtime_state.dart';
import 'package:omnivium/core/runtime/plugin/plugin_descriptor.dart';
import 'package:omnivium/core/runtime/plugin/plugin_handler.dart';
import 'package:omnivium/core/runtime/plugin/plugin_lifecycle.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_identity.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_permission.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_event.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_task.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_route.dart';
import 'package:omnivium/core/runtime/vocabulary/capability_context.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_message.dart';

class TestPluginHandler implements PluginHandler {
  final CapabilityResult Function(String, dynamic, CapabilityContext)?
  onCapability;
  final Future<HandlerResult> Function(RuntimeMessage, CapabilityContext)?
  onMessage;
  final Future<HandlerResult> Function(RuntimeEvent, CapabilityContext)?
  onEvent;

  TestPluginHandler({this.onCapability, this.onMessage, this.onEvent});

  @override
  Future<HandlerResult> handleMessage(
    RuntimeMessage message,
    CapabilityContext context,
  ) async {
    if (onMessage != null) return onMessage!(message, context);
    return HandlerResult.ok();
  }

  @override
  Future<HandlerResult> handleEvent(
    RuntimeEvent event,
    CapabilityContext context,
  ) async {
    if (onEvent != null) return onEvent!(event, context);
    return HandlerResult.ok();
  }

  @override
  Future<CapabilityResult> invokeCapability(
    String capabilityId,
    dynamic params,
    CapabilityContext context,
  ) async {
    if (onCapability != null) {
      return onCapability!(capabilityId, params, context);
    }
    return CapabilityResult.ok();
  }
}

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

  group('RuntimeKernel', () {
    test('boot creates running container', () async {
      final container = await RuntimeContainer.boot();
      expect(RuntimeContainer.isBooted, isTrue);
      expect(container.stateSnapshot.status, RuntimeStatus.running);
    });

    test('boot with custom config', () async {
      final config = RuntimeConfig(
        nodeId: 'test-node',
        runtimeVersion: '2.0.0',
      );
      final container = await RuntimeContainer.boot(config);
      expect(container.config.nodeId, 'test-node');
      expect(container.config.runtimeVersion, '2.0.0');
      expect(container.identity.node, 'test-node');
    });

    test('shutdown clears state', () async {
      await RuntimeContainer.boot();
      await RuntimeContainer.shutdown();
      expect(RuntimeContainer.isBooted, isFalse);
    });

    test('stateSnapshot reflects runtime state', () async {
      final container = await RuntimeContainer.boot();
      final snapshot = container.stateSnapshot;
      expect(snapshot.status, RuntimeStatus.running);
      expect(snapshot.bootTimeMs, greaterThan(0));
      expect(snapshot.uptimeMs, greaterThanOrEqualTo(0));
    });
  });

  group('Plugin Lifecycle', () {
    late RuntimeContainer container;

    setUp(() async {
      container = await RuntimeContainer.boot();
    });

    test('register and activate plugin', () async {
      final descriptor = PluginDescriptor(
        id: 'test-plugin',
        name: 'Test Plugin',
        version: '1.0.0',
        description: 'A test plugin',
        capabilities: [
          const CapabilityDeclaration(
            id: 'test.echo',
            name: 'Echo',
            description: 'Echoes input',
            permission: 'auto',
          ),
        ],
      );

      final handler = TestPluginHandler();
      final result = await container.registerPlugin(descriptor, handler);
      expect(result, isTrue);
      expect(container.pluginRegistry.state('test-plugin'), PluginState.active);
    });

    test('unload plugin', () async {
      final descriptor = PluginDescriptor(
        id: 'unload-test',
        name: 'Unload Test',
        version: '1.0.0',
        description: 'Test unload',
      );
      final handler = TestPluginHandler();
      await container.registerPlugin(descriptor, handler);
      expect(container.pluginRegistry.state('unload-test'), PluginState.active);

      final unloaded = await container.unloadPlugin('unload-test');
      expect(unloaded, isTrue);
      expect(container.pluginRegistry.state('unload-test'), isNull);
    });

    test('hot reload plugin', () async {
      final descriptor = PluginDescriptor(
        id: 'reload-test',
        name: 'Reload Test',
        version: '1.0.0',
        description: 'Test reload',
      );
      final handler = TestPluginHandler();
      await container.registerPlugin(descriptor, handler);

      final reloaded = await container.reloadPlugin('reload-test');
      expect(reloaded, isTrue);
      expect(container.pluginRegistry.state('reload-test'), PluginState.active);
    });

    test('suspend and reactivate plugin', () async {
      final descriptor = PluginDescriptor(
        id: 'suspend-test',
        name: 'Suspend Test',
        version: '1.0.0',
        description: 'Test suspend',
        lifecycle: const LifecycleConfig(autoActivate: false),
      );
      final handler = TestPluginHandler();
      await container.registerPlugin(descriptor, handler);
      await container.activatePlugin('suspend-test');

      final suspended = await container.suspendPlugin('suspend-test');
      expect(suspended, isTrue);
      expect(
        container.pluginRegistry.state('suspend-test'),
        PluginState.suspended,
      );

      final reactivated = await container.activatePlugin('suspend-test');
      expect(reactivated, isTrue);
      expect(
        container.pluginRegistry.state('suspend-test'),
        PluginState.active,
      );
    });
  });

  group('Capability Router', () {
    late RuntimeContainer container;

    setUp(() async {
      container = await RuntimeContainer.boot();
    });

    test('discover capability returns binding', () async {
      final descriptor = PluginDescriptor(
        id: 'cap-plugin',
        name: 'Cap Plugin',
        version: '1.0.0',
        description: 'Test capability',
        capabilities: [
          const CapabilityDeclaration(
            id: 'cap.echo',
            name: 'Echo',
            description: 'Echoes',
            permission: 'auto',
          ),
        ],
      );
      final handler = TestPluginHandler(
        onCapability: (id, params, ctx) =>
            CapabilityResult.ok({'echo': params}),
      );
      await container.registerPlugin(descriptor, handler);

      final binding = await container.capabilityRouter.discover('cap.echo');
      expect(binding.capabilityId, 'cap.echo');
      expect(binding.pluginId, 'cap-plugin');
    });

    test('invoke capability with auto permission', () async {
      final descriptor = PluginDescriptor(
        id: 'invoke-plugin',
        name: 'Invoke Plugin',
        version: '1.0.0',
        description: 'Test invoke',
        capabilities: [
          const CapabilityDeclaration(
            id: 'invoke.hello',
            name: 'Hello',
            description: 'Says hello',
            permission: 'auto',
          ),
        ],
      );
      final handler = TestPluginHandler(
        onCapability: (id, params, ctx) =>
            CapabilityResult.ok('Hello, $params!'),
      );
      await container.registerPlugin(descriptor, handler);

      final result = await container.capabilityRouter.invoke(
        'invoke.hello',
        'World',
        caller: RuntimeIdentity.forPlugin('test-caller'),
        callerPermission: const RuntimePermission(),
      );
      expect(result.status, CapabilityStatus.success);
    });

    test('permission deny blocks capability', () async {
      final descriptor = PluginDescriptor(
        id: 'deny-plugin',
        name: 'Deny Plugin',
        version: '1.0.0',
        description: 'Test deny',
        capabilities: [
          const CapabilityDeclaration(
            id: 'deny.secret',
            name: 'Secret',
            description: 'Secret capability',
            permission: 'deny',
          ),
        ],
      );
      final handler = TestPluginHandler();
      await container.registerPlugin(descriptor, handler);

      final result = await container.capabilityRouter.invoke(
        'deny.secret',
        null,
        caller: RuntimeIdentity.forPlugin('test-caller'),
        callerPermission: const RuntimePermission(),
      );
      expect(result.status, CapabilityStatus.failure);
    });

    test('discover non-existent capability throws', () async {
      expect(
        () => container.capabilityRouter.discover('non.existent'),
        throwsA(isA<RuntimeError>()),
      );
    });
  });

  group('Event Bus', () {
    late RuntimeContainer container;

    setUp(() async {
      container = await RuntimeContainer.boot();
    });

    test('publish and subscribe', () async {
      final received = <RuntimeEvent>[];
      container.eventBus.subscribe('test.event', (event) async {
        received.add(event);
      });

      container.eventBus.publish('test.event', {
        'key': 'value',
      }, source: RuntimeIdentity.forPlugin('test-source'));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(received.length, 1);
      expect(received.first.payload, {'key': 'value'});
    });

    test('unsubscribe stops receiving', () async {
      final received = <RuntimeEvent>[];
      final sub = container.eventBus.subscribe('test.unsub', (event) async {
        received.add(event);
      });

      container.eventBus.publish(
        'test.unsub',
        'first',
        source: RuntimeIdentity.forPlugin('test-source'),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      sub.cancel();

      container.eventBus.publish(
        'test.unsub',
        'second',
        source: RuntimeIdentity.forPlugin('test-source'),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(received.length, 1);
      expect(received.first.payload, 'first');
    });

    test('priority ordering', () async {
      final order = <String>[];
      container.eventBus.subscribe(
        'priority.test',
        (event) async => order.add('low'),
        priority: 0,
      );
      container.eventBus.subscribe(
        'priority.test',
        (event) async => order.add('high'),
        priority: 10,
      );

      container.eventBus.publish(
        'priority.test',
        null,
        source: RuntimeIdentity.forPlugin('test-source'),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(order, ['high', 'low']);
    });
  });

  group('Scheduler', () {
    late RuntimeContainer container;

    setUp(() async {
      container = await RuntimeContainer.boot();
    });

    test('schedule and complete task', () async {
      final task = RuntimeTask(
        id: 'task-1',
        type: 'test',
        source: RuntimeRoute(capability: 'test', pluginId: 'test'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await container.scheduler.schedule(
        task,
        (token) async => 42,
      );
      expect(result, 42);
      expect(container.scheduler.completedCount, 1);
    });

    test('cancel task', () async {
      final task = RuntimeTask(
        id: 'task-cancel',
        type: 'test',
        source: RuntimeRoute(capability: 'test', pluginId: 'test'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final future = container.scheduler.schedule(task, (token) async {
        await Future.delayed(const Duration(seconds: 10));
        return 'should not reach';
      });

      await Future.delayed(const Duration(milliseconds: 10));
      final cancelled = container.scheduler.cancel('task-cancel');
      expect(cancelled, isTrue);
      expect(container.scheduler.cancelledCount, 1);

      try {
        await future;
      } catch (_) {}
    });

    test('task timeout triggers failure', () async {
      final task = RuntimeTask(
        id: 'task-timeout',
        type: 'test',
        source: RuntimeRoute(capability: 'test', pluginId: 'test'),
        budget: const TaskBudget(maxDurationMs: 50),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      try {
        await container.scheduler.schedule(task, (token) async {
          await Future.delayed(const Duration(seconds: 10));
          return 'should not reach';
        });
        fail('Should have thrown');
      } catch (e) {
        expect(e, isNotNull);
      }
      expect(container.scheduler.failedCount, 1);
    });
  });

  group('Runtime Clock', () {
    test('deadline and expiry', () async {
      final container = await RuntimeContainer.boot();
      final clock = container.clock;

      final deadline = clock.deadline(1000);
      expect(clock.isExpired(deadline), isFalse);

      final pastDeadline = clock.now() - 1;
      expect(clock.isExpired(pastDeadline), isTrue);
    });

    test('monotonic time advances', () async {
      final container = await RuntimeContainer.boot();
      final t1 = container.clock.monotonicMs();
      await Future.delayed(const Duration(milliseconds: 10));
      final t2 = container.clock.monotonicMs();
      expect(t2, greaterThanOrEqualTo(t1));
    });
  });
}
