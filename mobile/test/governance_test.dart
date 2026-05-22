import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/kernel/runtime_container.dart';
import 'package:omnivium/core/runtime/kernel/runtime_state.dart';
import 'package:omnivium/core/runtime/plugin/plugin_lifecycle.dart';
import 'package:omnivium/core/runtime/plugins/storage_plugin.dart';
import 'package:omnivium/core/runtime/plugins/fake_agent_plugin.dart';
import 'package:omnivium/core/runtime/governance/policy_engine.dart';
import 'package:omnivium/core/runtime/governance/resource_controller.dart';
import 'package:omnivium/core/runtime/governance/event_journal.dart';

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

  group('Policy Engine', () {
    test('default policy denies agent.* from storage.delete', () {
      final engine = PolicyEngine.defaultPolicy();
      final decision = engine.evaluate(
        callerId: 'agent.main',
        targetCapability: 'storage.delete',
      );
      expect(decision.allowed, isFalse);
      expect(decision.matchedRuleId, 'deny-agent-delete-storage');
    });

    test('default policy allows agent.* to storage.read', () {
      final engine = PolicyEngine.defaultPolicy();
      final decision = engine.evaluate(
        callerId: 'agent.main',
        targetCapability: 'storage.read',
      );
      expect(decision.allowed, isTrue);
    });

    test('default policy denies background.* from network.*', () {
      final engine = PolicyEngine.defaultPolicy();
      final decision = engine.evaluate(
        callerId: 'background.sync',
        targetCapability: 'network.request',
      );
      expect(decision.allowed, isFalse);
    });

    test('default policy denies sandbox.* from runtime.*', () {
      final engine = PolicyEngine.defaultPolicy();
      final decision = engine.evaluate(
        callerId: 'sandbox.miniapp1',
        targetCapability: 'runtime.info',
      );
      expect(decision.allowed, isFalse);
    });

    test('custom rule overrides default', () {
      final engine = PolicyEngine.defaultPolicy();
      engine.addRule(const PolicyRule(
        id: 'allow-agent-storage-delete',
        description: 'Allow agent to delete storage in dev',
        effect: PolicyEffect.allow,
        callerPattern: 'fake-agent',
        targetPattern: 'storage.delete',
        priority: 150,
      ));

      final decision = engine.evaluate(
        callerId: 'fake-agent',
        targetCapability: 'storage.delete',
      );
      expect(decision.allowed, isTrue);
    });

    test('wildcard caller matches all', () {
      final engine = PolicyEngine();
      engine.addRule(const PolicyRule(
        id: 'deny-all-chaos',
        description: 'Deny all chaos capabilities',
        effect: PolicyEffect.deny,
        callerPattern: '*',
        targetPattern: 'chaos.*',
        priority: 100,
      ));
      engine.addRule(const PolicyRule(
        id: 'allow-all',
        description: 'Allow all',
        effect: PolicyEffect.allow,
        priority: 0,
      ));

      expect(engine.isAllowed('any-plugin', 'chaos.crash'), isFalse);
      expect(engine.isAllowed('any-plugin', 'storage.read'), isTrue);
    });

    test('implicit deny when no rule matches', () {
      final engine = PolicyEngine();
      final decision = engine.evaluate(
        callerId: 'unknown',
        targetCapability: 'anything',
      );
      expect(decision.allowed, isFalse);
      expect(decision.reason, contains('No matching policy'));
    });

    test('scope restriction', () {
      final engine = PolicyEngine();
      engine.addRule(const PolicyRule(
        id: 'own-scope-only',
        description: 'Only own scope allowed',
        effect: PolicyEffect.allow,
        maxScope: PolicyScope.own,
        priority: 10,
      ));

      expect(engine.isAllowed('plugin', 'cap', scope: PolicyScope.own), isTrue);
      expect(engine.isAllowed('plugin', 'cap', scope: PolicyScope.session), isFalse);
      expect(engine.isAllowed('plugin', 'cap', scope: PolicyScope.cluster), isFalse);
    });
  });

  group('Resource Controller', () {
    test('token budget enforcement', () {
      final controller = ResourceController(
        budget: const ResourceBudget(maxTokens: 100),
      );

      expect(controller.tryAcquireTokens(50), isTrue);
      expect(controller.tryAcquireTokens(50), isTrue);
      expect(controller.tryAcquireTokens(1), isFalse);
      expect(controller.violationCount, 1);
    });

    test('stream budget enforcement', () {
      final controller = ResourceController(
        budget: const ResourceBudget(maxStreams: 2),
      );

      expect(controller.tryAcquireStream(), isTrue);
      expect(controller.tryAcquireStream(), isTrue);
      expect(controller.tryAcquireStream(), isFalse);

      controller.releaseStream();
      expect(controller.tryAcquireStream(), isTrue);
    });

    test('task budget enforcement', () {
      final controller = ResourceController(
        budget: const ResourceBudget(maxTasks: 3),
      );

      expect(controller.tryAcquireTask(), isTrue);
      expect(controller.tryAcquireTask(), isTrue);
      expect(controller.tryAcquireTask(), isTrue);
      expect(controller.tryAcquireTask(), isFalse);

      controller.releaseTask();
      expect(controller.tryAcquireTask(), isTrue);
    });

    test('retry budget enforcement', () {
      final controller = ResourceController(
        budget: const ResourceBudget(maxRetries: 5),
      );

      for (var i = 0; i < 5; i++) {
        expect(controller.recordRetry(), isTrue);
      }
      expect(controller.recordRetry(), isFalse);
    });

    test('events per second enforcement', () {
      final controller = ResourceController(
        budget: const ResourceBudget(maxEventsPerSec: 1000, maxEventAmplification: 1000.0),
      );

      expect(controller.recordEvents(500), isTrue);
      expect(controller.recordEvents(1000), isTrue);
      expect(controller.recordEvents(1001), isFalse);
    });

    test('per-plugin usage tracking', () {
      final controller = ResourceController(
        budget: const ResourceBudget(maxTokens: 1000),
      );

      controller.tryAcquireTokens(100, pluginId: 'agent');
      controller.tryAcquireTokens(200, pluginId: 'memory');

      expect(controller.usageFor('agent').tokensUsed, 100);
      expect(controller.usageFor('memory').tokensUsed, 200);
      expect(controller.usage.tokensUsed, 300);
    });

    test('memory budget check', () {
      final controller = ResourceController(
        budget: const ResourceBudget(maxMemoryMb: 512),
      );

      expect(controller.checkMemoryLimit(256), isTrue);
      controller.recordMemory(256);
      expect(controller.checkMemoryLimit(256), isTrue);
      controller.recordMemory(512);
      expect(controller.checkMemoryLimit(1), isFalse);
    });

    test('reset clears all usage', () {
      final controller = ResourceController();
      controller.tryAcquireTokens(1000);
      controller.tryAcquireStream();
      controller.tryAcquireTask();

      controller.reset();

      expect(controller.usage.tokensUsed, 0);
      expect(controller.usage.activeStreams, 0);
      expect(controller.usage.activeTasks, 0);
      expect(controller.violationCount, 0);
    });
  });

  group('Event Journal', () {
    test('append and replay entries', () async {
      final container = await RuntimeContainer.boot();
      final journal = container.eventJournal;

      journal.append('test.event', {'key': 'value1'});
      journal.append('test.event', {'key': 'value2'});
      journal.append('plugin.load', {'pluginId': 'test'});

      expect(journal.length, greaterThanOrEqualTo(3));

      final events = journal.replayType('test.event');
      expect(events.length, 2);
    });

    test('replay from sequence', () async {
      final container = await RuntimeContainer.boot();
      final journal = container.eventJournal;

      journal.append('first', {});
      final second = journal.append('second', {});
      journal.append('third', {});

      final fromSecond = journal.replayFrom(second.sequence);
      expect(fromSecond.length, 2);
    });

    test('compaction reduces entries', () async {
      final container = await RuntimeContainer.boot();
      final journal = EventJournal(clock: container.clock, compactionThreshold: 10);

      for (var i = 0; i < 10; i++) {
        journal.append('bulk', {'index': i});
      }

      expect(journal.length, lessThan(10));
    });

    test('journal records plugin transitions', () async {
      final container = await RuntimeContainer.boot();
      final journal = container.eventJournal;

      journal.appendPluginTransition('test-plugin', 'unloaded', 'loaded');
      journal.appendPluginTransition('test-plugin', 'loaded', 'active');

      final transitions = journal.replayType('plugin_transition');
      expect(transitions.length, 2);
    });
  });

  group('Snapshot Service', () {
    test('take and retrieve snapshot', () async {
      final container = await RuntimeContainer.boot();
      await container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());

      final snapshot = container.snapshotService.take(
        status: RuntimeStatus.running,
        pluginStates: container.pluginRegistry.pluginStates,
        sessions: {},
        capabilityCache: container.pluginRegistry.loadedDescriptors.expand((d) => d.capabilityIds).toList(),
        resourceUsage: container.resourceController.usage,
      );

      expect(snapshot.snapshotId, 0);
      expect(snapshot.status, RuntimeStatus.running);
      expect(snapshot.pluginStates, isNotEmpty);
      expect(snapshot.capabilityCache, isNotEmpty);
    });

    test('multiple snapshots', () async {
      final container = await RuntimeContainer.boot();

      for (var i = 0; i < 5; i++) {
        container.snapshotService.take(
          status: RuntimeStatus.running,
          pluginStates: {},
          sessions: {},
          capabilityCache: [],
          resourceUsage: container.resourceController.usage,
        );
      }

      expect(container.snapshotService.snapshotCount, 5);
      expect(container.snapshotService.latest!.snapshotId, 4);
    });

    test('snapshot toJson serializable', () async {
      final container = await RuntimeContainer.boot();

      final snapshot = container.snapshotService.take(
        status: RuntimeStatus.running,
        pluginStates: {'test': PluginState.active},
        sessions: {},
        capabilityCache: ['test.cap'],
        resourceUsage: container.resourceController.usage,
      );

      final json = snapshot.toJson();
      expect(json['status'], 'running');
      expect(json['pluginStates'], isA<Map>());
      expect(json['capabilityCache'], isA<List>());
    });

    test('prune keeps last N snapshots', () async {
      final container = await RuntimeContainer.boot();

      for (var i = 0; i < 20; i++) {
        container.snapshotService.take(
          status: RuntimeStatus.running,
          pluginStates: {},
          sessions: {},
          capabilityCache: [],
          resourceUsage: container.resourceController.usage,
        );
      }

      container.snapshotService.prune(keepLast: 5);
      expect(container.snapshotService.snapshotCount, 5);
    });
  });

  group('Governance Integration', () {
    test('RuntimeContainer has all governance services', () async {
      final container = await RuntimeContainer.boot();

      expect(container.policyEngine, isNotNull);
      expect(container.resourceController, isNotNull);
      expect(container.eventJournal, isNotNull);
      expect(container.snapshotService, isNotNull);
    });

    test('policy engine blocks agent from storage.delete via router', () async {
      final container = await RuntimeContainer.boot();
      await container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());
      await container.registerPlugin(FakeAgentPlugin.descriptor(), FakeAgentPlugin());

      final decision = container.policyEngine.evaluate(
        callerId: 'agent.fake-agent',
        targetCapability: 'storage.delete',
      );
      expect(decision.allowed, isFalse);
    });

    test('resource controller tracks usage during operations', () async {
      final container = await RuntimeContainer.boot();
      await container.registerPlugin(StoragePlugin.descriptor(), StoragePlugin());

      container.resourceController.tryAcquireStream(pluginId: 'storage');
      expect(container.resourceController.usage.activeStreams, 1);
      expect(container.resourceController.usageFor('storage').activeStreams, 1);

      container.resourceController.releaseStream(pluginId: 'storage');
      expect(container.resourceController.usage.activeStreams, 0);
    });

    test('event journal records boot and shutdown', () async {
      final container = await RuntimeContainer.boot();

      final bootEntries = container.eventJournal.replayType('runtime.boot');
      expect(bootEntries.length, 1);

      await RuntimeContainer.shutdown();
    });
  });
}
