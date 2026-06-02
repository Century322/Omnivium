import 'dart:async';
import '../kernel/runtime_container.dart';
import '../vocabulary/runtime_task.dart';
import '../vocabulary/runtime_route.dart';
import '../vocabulary/runtime_identity.dart';
import '../vocabulary/runtime_permission.dart';
import '../plugin/plugin_descriptor.dart';
import '../plugins/fake_agent_plugin.dart';
import '../plugins/storage_plugin.dart';

class BenchmarkResult {
  final String name;
  final int iterations;
  final int totalMs;
  final double avgMs;
  final double minMs;
  final double maxMs;
  final double opsPerSec;
  final Map<String, dynamic> extra;

  const BenchmarkResult({
    required this.name,
    required this.iterations,
    required this.totalMs,
    required this.avgMs,
    required this.minMs,
    required this.maxMs,
    required this.opsPerSec,
    this.extra = const {},
  });

  @override
  String toString() =>
      '$name: ${opsPerSec.toStringAsFixed(1)} ops/s (avg=${avgMs.toStringAsFixed(2)}ms, min=${minMs.toStringAsFixed(2)}ms, max=${maxMs.toStringAsFixed(2)}ms)';
}

class RuntimeBenchmark {
  final RuntimeContainer _container;

  RuntimeBenchmark(this._container);

  Future<List<BenchmarkResult>> runAll() async {
    final results = <BenchmarkResult>[];
    results.add(await benchmarkTaskThroughput());
    results.add(await benchmarkEventLatency());
    results.add(await benchmarkPluginLoadTime());
    results.add(await benchmarkCapabilityInvoke());
    results.add(await benchmarkSchedulerDelay());
    return results;
  }

  Future<BenchmarkResult> benchmarkTaskThroughput({
    int iterations = 1000,
  }) async {
    final clock = _container.clock;
    final latencies = <int>[];

    for (var i = 0; i < iterations; i++) {
      final start = clock.now();
      final task = RuntimeTask(
        id: 'bench_task_$i',
        type: 'benchmark',
        source: RuntimeRoute(capability: 'benchmark', pluginId: 'bench'),
        priority: TaskPriority.normal,
        budget: const TaskBudget(maxDurationMs: 5000, maxRetries: 0),
        createdAt: start);

      await _container.scheduler.schedule(task, (token) async {
        return 'done';
      });

      latencies.add(clock.now() - start);
    }

    return _buildResult('task_throughput', iterations, latencies);
  }

  Future<BenchmarkResult> benchmarkEventLatency({int iterations = 1000}) async {
    final clock = _container.clock;
    final latencies = <int>[];
    final completer = Completer<void>();
    var received = 0;

    _container.eventBus.subscribe('bench.event', (event) async {
      latencies.add(clock.now() - event.timestamp);
      received++;
      if (received >= iterations && !completer.isCompleted) {
        completer.complete();
      }
    });

    for (var i = 0; i < iterations; i++) {
      _container.eventBus.publish(
        'bench.event',
        null,
        source: RuntimeIdentity.forPlugin('benchmark'));
    }

    await completer.future.timeout(const Duration(seconds: 30));

    return _buildResult('event_latency', iterations, latencies);
  }

  Future<BenchmarkResult> benchmarkPluginLoadTime({
    int iterations = 100,
  }) async {
    final clock = _container.clock;
    final latencies = <int>[];

    for (var i = 0; i < iterations; i++) {
      final start = clock.now();

      final descriptor = PluginDescriptor(
        id: 'bench_plugin_$i',
        name: 'Bench Plugin $i',
        version: '1.0.0',
        description: 'Benchmark plugin',
        lifecycle: const LifecycleConfig(autoActivate: true));
      final handler = FakeAgentPlugin();
      await _container.registerPlugin(descriptor, handler);

      latencies.add(clock.now() - start);

      await _container.unloadPlugin('bench_plugin_$i');
    }

    return _buildResult('plugin_load_time', iterations, latencies);
  }

  Future<BenchmarkResult> benchmarkCapabilityInvoke({
    int iterations = 500,
  }) async {
    final descriptor = StoragePlugin.descriptor();
    final handler = StoragePlugin();
    await _container.registerPlugin(descriptor, handler);

    final clock = _container.clock;
    final latencies = <int>[];
    const perm = RuntimePermission(
      capabilities: ['storage.write', 'storage.read']);

    for (var i = 0; i < iterations; i++) {
      final start = clock.now();

      await _container.capabilityRouter.invoke(
        i.isEven ? 'storage.write' : 'storage.read',
        i.isEven ? {'key': 'bench_$i', 'value': 'v_$i'} : 'bench_$i',
        caller: RuntimeIdentity.forPlugin('benchmark'),
        callerPermission: perm);

      latencies.add(clock.now() - start);
    }

    await _container.unloadPlugin('storage');

    return _buildResult('capability_invoke', iterations, latencies);
  }

  Future<BenchmarkResult> benchmarkSchedulerDelay({
    int iterations = 500,
  }) async {
    final clock = _container.clock;
    final latencies = <int>[];

    for (var i = 0; i < iterations; i++) {
      final scheduledAt = clock.now();
      final task = RuntimeTask(
        id: 'bench_delay_$i',
        type: 'benchmark',
        source: RuntimeRoute(capability: 'benchmark', pluginId: 'bench'),
        priority: TaskPriority.normal,
        budget: const TaskBudget(maxDurationMs: 5000, maxRetries: 0),
        createdAt: scheduledAt);

      await _container.scheduler.schedule(task, (token) async {
        latencies.add(clock.now() - scheduledAt);
        return 'done';
      });
    }

    return _buildResult('scheduler_delay', iterations, latencies);
  }

  BenchmarkResult _buildResult(
    String name,
    int iterations,
    List<int> latencies) {
    if (latencies.isEmpty) {
      return BenchmarkResult(
        name: name,
        iterations: 0,
        totalMs: 0,
        avgMs: 0,
        minMs: 0,
        maxMs: 0,
        opsPerSec: 0);
    }

    final totalMs = latencies.reduce((a, b) => a + b);
    final avgMs = totalMs / latencies.length;
    final minMs = latencies.reduce((a, b) => a < b ? a : b).toDouble();
    final maxMs = latencies.reduce((a, b) => a > b ? a : b).toDouble();
    final opsPerSec = totalMs > 0 ? (latencies.length / totalMs) * 1000 : 0.0;

    return BenchmarkResult(
      name: name,
      iterations: iterations,
      totalMs: totalMs,
      avgMs: avgMs,
      minMs: minMs,
      maxMs: maxMs,
      opsPerSec: opsPerSec);
  }
}
