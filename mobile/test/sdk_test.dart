import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sdk/omnivium_sdk.dart';
import 'package:omnivium/core/runtime/sdk/runtime_cli.dart';
import 'package:omnivium/core/runtime/sdk/runtime_observatory.dart';
import 'package:omnivium/core/runtime/kernel/runtime_container.dart';
import 'package:omnivium/core/runtime/kernel/runtime_state.dart';
import 'package:omnivium/core/runtime/plugin/plugin_handler.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_message.dart';
import 'package:omnivium/core/runtime/vocabulary/runtime_event.dart';
import 'package:omnivium/core/runtime/vocabulary/capability_context.dart';
import 'package:omnivium/core/runtime/plugins/storage_plugin.dart';

class SdkTestPlugin extends PluginHandler {
  @override
  Future<HandlerResult> handleMessage(RuntimeMessage message, CapabilityContext context) async =>
      HandlerResult.ok('handled');

  @override
  Future<HandlerResult> handleEvent(RuntimeEvent event, CapabilityContext context) async =>
      HandlerResult.ok('event');

  @override
  Future<CapabilityResult> invokeCapability(
      String capabilityId, dynamic params, CapabilityContext context) async {
    if (capabilityId == 'test.echo') {
      return CapabilityResult.ok({'echo': params});
    }
    return CapabilityResult.fail(RuntimeError.notFound(message: 'Unknown: $capabilityId'));
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

  group('Omnivium SDK', () {
    test('init and shutdown lifecycle', () async {
      final sdk = await OmniviumSDK.init();
      expect(sdk.isInitialized, isTrue);

      await OmniviumSDK.shutdown();
      expect(sdk.isInitialized, isFalse);
    });

    test('create plugin with builder', () async {
      final sdk = await OmniviumSDK.init();

      final cap = CapabilityBuilder('test.echo')
          .name('Echo')
          .description('Echo capability')
          .channel('fast')
          .build();

      final descriptor = sdk
          .createPlugin('test-plugin')
          .name('Test Plugin')
          .version('1.0.0')
          .description('A test plugin')
          .addCapability(cap)
          .build();

      expect(descriptor.id, 'test-plugin');
      expect(descriptor.capabilities.length, 1);
      expect(descriptor.capabilities.first.id, 'test.echo');

      await OmniviumSDK.shutdown();
    });

    test('register plugin via builder', () async {
      final sdk = await OmniviumSDK.init();

      final registered = await sdk
          .createPlugin('test-plugin')
          .name('Test Plugin')
          .version('1.0.0')
          .description('Test')
          .addCapability(
            CapabilityBuilder('test.echo').name('Echo').description('Echo').permission('auto').build(),
          )
          .register(SdkTestPlugin());

      expect(registered, isTrue);

      await OmniviumSDK.shutdown();
    });

    test('invoke capability through SDK', () async {
      final sdk = await OmniviumSDK.init();

      await sdk
          .createPlugin('test-plugin')
          .name('Test Plugin')
          .version('1.0.0')
          .description('Test')
          .addCapability(
            CapabilityBuilder('test.echo').name('Echo').description('Echo').permission('auto').build(),
          )
          .register(SdkTestPlugin());

      final result = await sdk.invokeCapability('test.echo', params: 'hello');
      expect(result.status, CapabilityStatus.success);

      await OmniviumSDK.shutdown();
    });

    test('inspect returns runtime state', () async {
      final sdk = await OmniviumSDK.init();

      final RuntimeStateSnapshot snap = sdk.inspect();
      expect(snap.status, RuntimeStatus.running);

      await OmniviumSDK.shutdown();
    });

    test('list plugins', () async {
      final sdk = await OmniviumSDK.init();

      await sdk.container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());

      final plugins = sdk.listPlugins();
      expect(plugins, isNotEmpty);
      expect(plugins.any((p) => p['id'] == 'storage'), isTrue);

      await OmniviumSDK.shutdown();
    });

    test('list capabilities', () async {
      final sdk = await OmniviumSDK.init();

      await sdk.container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());

      final caps = sdk.listCapabilities();
      expect(caps, isNotEmpty);
      expect(caps.any((c) => c['id'] == 'storage.read'), isTrue);

      await OmniviumSDK.shutdown();
    });

    test('list journal entries', () async {
      final sdk = await OmniviumSDK.init();

      final entries = sdk.listJournalEntries();
      expect(entries, isNotEmpty);

      final limited = sdk.listJournalEntries(limit: 1);
      expect(limited.length, lessThanOrEqualTo(1));

      await OmniviumSDK.shutdown();
    });

    test('create session', () async {
      final sdk = await OmniviumSDK.init();

      final session = sdk.createSession(userId: 'test-user');
      expect(session.userId, 'test-user');
      expect(session.isActive, isTrue);

      await OmniviumSDK.shutdown();
    });

    test('invokeRemote without distributed returns error', () async {
      final sdk = await OmniviumSDK.init();

      final result = await sdk.invokeRemote('test.echo');
      expect(result.status, CapabilityStatus.failure);

      await OmniviumSDK.shutdown();
    });

    test('inspectDistributed without distributed returns false', () async {
      final sdk = await OmniviumSDK.init();

      final info = sdk.inspectDistributed();
      expect(info['initialized'], false);

      await OmniviumSDK.shutdown();
    });
  });

  group('Runtime CLI', () {
    test('help command', () {
      final cli = RuntimeCLI();
      final output = cli.execute('help');
      expect(output, contains('inspect'));
      expect(output, contains('plugins'));
      expect(output, contains('capabilities'));
      expect(output, contains('journal'));
    });

    test('unknown command returns help', () {
      final cli = RuntimeCLI();
      final output = cli.execute('nonexistent');
      expect(output, contains('Unknown command'));
    });

    test('inspect command with runtime', () async {
      final container = await RuntimeContainer.boot();
      final cli = RuntimeCLI(container: container);

      final output = cli.execute('inspect');
      expect(output, contains('running'));

      await RuntimeContainer.shutdown();
    });

    test('plugins command', () async {
      final container = await RuntimeContainer.boot();
      await container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());
      final cli = RuntimeCLI(container: container);

      final output = cli.execute('plugins');
      expect(output, contains('storage'));

      await RuntimeContainer.shutdown();
    });

    test('plugin detail command', () async {
      final container = await RuntimeContainer.boot();
      await container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());
      final cli = RuntimeCLI(container: container);

      final output = cli.execute('plugin', args: ['storage']);
      expect(output, contains('Storage'));
      expect(output, contains('storage.read'));

      await RuntimeContainer.shutdown();
    });

    test('capabilities command', () async {
      final container = await RuntimeContainer.boot();
      await container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());
      final cli = RuntimeCLI(container: container);

      final output = cli.execute('capabilities');
      expect(output, contains('storage.read'));

      await RuntimeContainer.shutdown();
    });

    test('journal command', () async {
      final container = await RuntimeContainer.boot();
      final cli = RuntimeCLI(container: container);

      final output = cli.execute('journal', args: ['5']);
      expect(output, contains('Event Journal'));

      await RuntimeContainer.shutdown();
    });

    test('status command', () async {
      final container = await RuntimeContainer.boot();
      final cli = RuntimeCLI(container: container);

      final output = cli.execute('status');
      expect(output, contains('local only'));
      expect(output, contains('running'));

      await RuntimeContainer.shutdown();
    });

    test('session command', () async {
      final container = await RuntimeContainer.boot();
      final cli = RuntimeCLI(container: container);

      final output = cli.execute('session');
      expect(output, contains('Session'));

      await RuntimeContainer.shutdown();
    });

    test('policy command', () async {
      final container = await RuntimeContainer.boot();
      final cli = RuntimeCLI(container: container);

      final output = cli.execute('policy');
      expect(output, contains('DENY'));

      await RuntimeContainer.shutdown();
    });

    test('resources command', () async {
      final container = await RuntimeContainer.boot();
      final cli = RuntimeCLI(container: container);

      final output = cli.execute('resources');
      expect(output, contains('Tokens'));

      await RuntimeContainer.shutdown();
    });

    test('snapshot command', () async {
      final container = await RuntimeContainer.boot();
      final cli = RuntimeCLI(container: container);

      container.snapshotService.take(
        status: RuntimeStatus.running,
        pluginStates: {},
        sessions: {},
        capabilityCache: [],
        resourceUsage: container.resourceController.usage,
      );

      final output = cli.execute('snapshot');
      expect(output, contains('Snapshot'));

      await RuntimeContainer.shutdown();
    });

    test('nodes command without distributed', () async {
      final container = await RuntimeContainer.boot();
      final cli = RuntimeCLI(container: container);

      final output = cli.execute('nodes');
      expect(output, contains('not initialized'));

      await RuntimeContainer.shutdown();
    });
  });

  group('Runtime Observatory', () {
    test('getDashboard returns runtime info', () async {
      final container = await RuntimeContainer.boot();
      final observatory = RuntimeObservatory(container: container);

      final dashboard = observatory.getDashboard();
      expect(dashboard['runtime'], isNotNull);
      expect((dashboard['runtime'] as Map)['status'], 'running');

      observatory.dispose();
      await RuntimeContainer.shutdown();
    });

    test('getPluginGraph returns nodes and edges', () async {
      final container = await RuntimeContainer.boot();
      await container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());
      final observatory = RuntimeObservatory(container: container);

      final graph = observatory.getPluginGraph();
      expect(graph['nodes'], isNotNull);
      expect((graph['nodes'] as List).length, greaterThanOrEqualTo(1));

      observatory.dispose();
      await RuntimeContainer.shutdown();
    });

    test('getEventTimeline returns entries', () async {
      final container = await RuntimeContainer.boot();
      final observatory = RuntimeObservatory(container: container);

      final timeline = observatory.getEventTimeline(lastN: 10);
      expect(timeline['entries'], isNotNull);

      observatory.dispose();
      await RuntimeContainer.shutdown();
    });

    test('getTraceFlamegraph returns traces', () async {
      final container = await RuntimeContainer.boot();
      final observatory = RuntimeObservatory(container: container);

      final flamegraph = observatory.getTraceFlamegraph();
      expect(flamegraph['traces'], isNotNull);

      observatory.dispose();
      await RuntimeContainer.shutdown();
    });

    test('getDistributedMap without distributed returns false', () async {
      final container = await RuntimeContainer.boot();
      final observatory = RuntimeObservatory(container: container);

      final map = observatory.getDistributedMap();
      expect(map['initialized'], false);

      observatory.dispose();
      await RuntimeContainer.shutdown();
    });

    test('notify events emit to stream', () async {
      final container = await RuntimeContainer.boot();
      final observatory = RuntimeObservatory(container: container);

      final events = <ObservatoryEvent>[];
      observatory.events.listen(events.add);

      observatory.notifyPluginStateChange('test-plugin', 'unloaded', 'active');
      observatory.notifyCapabilityInvoke('storage.read', 'storage', 'ok');
      observatory.notifyPolicyDecision('agent.main', 'storage.delete', false);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(events.length, 3);
      expect(events[0].type, ObservatoryEventType.pluginStateChange);
      expect(events[1].type, ObservatoryEventType.capabilityInvoke);
      expect(events[2].type, ObservatoryEventType.policyDecision);

      observatory.dispose();
      await RuntimeContainer.shutdown();
    });

    test('event buffer respects size limit', () async {
      final container = await RuntimeContainer.boot();
      final observatory = RuntimeObservatory(container: container, bufferSize: 5);

      for (var i = 0; i < 10; i++) {
        observatory.notifyPluginStateChange('p-$i', 'a', 'b');
      }

      expect(observatory.recentEvents.length, 5);

      observatory.dispose();
      await RuntimeContainer.shutdown();
    });

    test('start and stop polling', () async {
      final container = await RuntimeContainer.boot();
      final observatory = RuntimeObservatory(container: container);

      expect(observatory.isActive, isFalse);

      observatory.start(interval: const Duration(milliseconds: 100));
      expect(observatory.isActive, isTrue);

      observatory.stop();
      expect(observatory.isActive, isFalse);

      observatory.dispose();
      await RuntimeContainer.shutdown();
    });
  });
}
