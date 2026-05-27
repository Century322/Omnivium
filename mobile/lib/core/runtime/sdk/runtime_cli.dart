import '../../app_logger.dart';
import '../kernel/runtime_container.dart';
import '../distributed/distributed_runtime.dart';

class RuntimeCLI {
  final RuntimeContainer? _container;
  final DistributedRuntime? _distributed;

  RuntimeCLI({RuntimeContainer? container, DistributedRuntime? distributed})
    : _container = container,
      _distributed = distributed;

  String execute(String command, {List<String> args = const []}) {
    try {
      switch (command) {
        case 'inspect':
          return cmdInspect();
        case 'plugins':
          return cmdPlugins();
        case 'plugin':
          return cmdPlugin(args.firstOrNull ?? '');
        case 'capabilities':
          return cmdCapabilities();
        case 'journal':
          return cmdJournal(args.firstOrNull ?? '20');
        case 'traces':
          return cmdTraces(args.firstOrNull ?? '20');
        case 'nodes':
          return cmdNodes();
        case 'node':
          return cmdNode(args.firstOrNull ?? '');
        case 'status':
          return cmdStatus();
        case 'session':
          return cmdSession();
        case 'policy':
          return cmdPolicy();
        case 'resources':
          return cmdResources();
        case 'snapshot':
          return cmdSnapshot();
        case 'help':
          return cmdHelp();
        default:
          return 'Unknown command: $command\n${cmdHelp()}';
      }
    } catch (e, stackTrace) {
      AppLogger.instance.warning('CLI command failed: $command', error: e, stackTrace: stackTrace);
      return 'Error: $e';
    }
  }

  String cmdInspect() {
    final c = _container;
    if (c == null) return 'Runtime not initialized';

    final snap = c.stateSnapshot;
    return '''
Runtime Inspect
═══════════════
  Status:           ${snap.status.name}
  Active Sessions:  ${snap.activeSessionCount}
  Active Tasks:     ${snap.activeTaskCount}
  Loaded Plugins:   ${snap.loadedPluginCount}
  Active Plugins:   ${snap.activePluginCount}
  Capabilities:     ${snap.capabilityCount}
  Boot Time:        ${snap.bootTimeMs}ms
  Uptime:           ${snap.uptimeMs}ms
''';
  }

  String cmdPlugins() {
    final c = _container;
    if (c == null) return 'Runtime not initialized';

    final descriptors = c.pluginRegistry.loadedDescriptors;
    if (descriptors.isEmpty) return 'No plugins loaded';

    final buffer = StringBuffer('Plugins\n═══════\n');
    for (final d in descriptors) {
      final state = c.pluginRegistry.pluginStates[d.id]?.name ?? 'unknown';
      buffer.writeln(
        '  ${d.id.padRight(20)} ${d.version.padRight(8)} [$state] ${d.name}',
      );
    }
    return buffer.toString();
  }

  String cmdPlugin(String pluginId) {
    final c = _container;
    if (c == null) return 'Runtime not initialized';
    if (pluginId.isEmpty) return 'Usage: plugin <pluginId>';

    final d = c.pluginRegistry.descriptor(pluginId);
    if (d == null) return 'Plugin not found: $pluginId';

    final state = c.pluginRegistry.pluginStates[d.id]?.name ?? 'unknown';
    return '''
Plugin: ${d.name}
════════${'═' * d.name.length}
  ID:             ${d.id}
  Version:        ${d.version}
  Author:         ${d.author}
  Description:    ${d.description}
  State:          $state
  Isolation:      ${d.isolation.name}
  Auto Activate:  ${d.lifecycle.autoActivate}
  Capabilities:   ${d.capabilityIds.join(', ')}
''';
  }

  String cmdCapabilities() {
    final c = _container;
    if (c == null) return 'Runtime not initialized';

    final descriptors = c.pluginRegistry.loadedDescriptors;
    if (descriptors.isEmpty) return 'No capabilities registered';

    final buffer = StringBuffer('Capabilities\n════════════\n');
    for (final d in descriptors) {
      for (final cap in d.capabilities) {
        buffer.writeln(
          '  ${cap.id.padRight(25)} [${cap.channel.padRight(6)}] ${cap.name} (${d.id})',
        );
      }
    }
    return buffer.toString();
  }

  String cmdJournal(String limitStr) {
    final c = _container;
    if (c == null) return 'Runtime not initialized';

    final limit = int.tryParse(limitStr) ?? 20;
    final entries = c.eventJournal.replay();
    final limited = entries.length > limit
        ? entries.sublist(entries.length - limit)
        : entries;

    final buffer = StringBuffer(
      'Event Journal (last $limit)\n════════════════════════\n',
    );
    for (final e in limited) {
      buffer.writeln(
        '  #${e.sequence.toString().padRight(6)} ${e.type.padRight(25)} @${e.timestamp}',
      );
    }
    return buffer.toString();
  }

  String cmdTraces(String limitStr) {
    final c = _container;
    if (c == null) return 'Runtime not initialized';

    final limit = int.tryParse(limitStr) ?? 20;
    final traces = c.traceService.recentTraces(limit: limit);

    if (traces.isEmpty) return 'No traces recorded';

    final buffer = StringBuffer('Traces (last $limit)\n════════════════════\n');
    for (final t in traces) {
      buffer.writeln(
        '  ${t.traceId.padRight(20)} spans:${t.spans.length.toString().padRight(4)} dur:${t.totalDurationMs}ms',
      );
    }
    return buffer.toString();
  }

  String cmdNodes() {
    final dist = _distributed;
    if (dist == null) return 'Distributed runtime not initialized';

    final nodes = dist.nodeDiscovery.allNodes;
    if (nodes.isEmpty) return 'No nodes discovered';

    final buffer = StringBuffer('Cluster Nodes\n══════════════\n');
    for (final n in nodes) {
      final marker = n.nodeId == dist.nodeId ? ' (self)' : '';
      buffer.writeln(
        '  ${n.nodeId.padRight(20)} ${n.role.name.padRight(8)} [${n.state.name.padRight(7)}] ${n.addressKey}$marker',
      );
    }
    return buffer.toString();
  }

  String cmdNode(String nodeId) {
    final dist = _distributed;
    if (dist == null) return 'Distributed runtime not initialized';
    if (nodeId.isEmpty) return 'Usage: node <nodeId>';

    final node = dist.nodeDiscovery.get(nodeId);
    if (node == null) return 'Node not found: $nodeId';

    return '''
Node: ${node.nodeId}
══════${'═' * node.nodeId.length}
  Address:      ${node.addressKey}
  Role:         ${node.role.name}
  State:        ${node.state.name}
  Incarnation:  ${node.incarnation}
  Joined:       ${node.joinedAt}
  Last HB:      ${node.lastHeartbeatAt}
  Metadata:     ${node.metadata}
''';
  }

  String cmdStatus() {
    final c = _container;
    if (c == null) return 'Runtime not initialized';

    final snap = c.stateSnapshot;
    final dist = _distributed;
    final distStatus = dist != null
        ? 'distributed (${dist.state.name})'
        : 'local only';

    return '''
Runtime Status
══════════════
  Mode:       $distStatus
  Status:     ${snap.status.name}
  Uptime:     ${snap.uptimeMs}ms
  Plugins:    ${snap.activePluginCount}/${snap.loadedPluginCount} active
  Sessions:   ${snap.activeSessionCount}
  Tasks:      ${snap.activeTaskCount}
  Caps:       ${snap.capabilityCount}
''';
  }

  String cmdSession() {
    final c = _container;
    if (c == null) return 'Runtime not initialized';

    final session = c.currentSession();
    return '''
Session: ${session.id}
════════${'═' * session.id.length}
  User:         ${session.userId}
  Created:      ${session.createdAt}
  Last Active:  ${session.lastActiveAt}
  Active:       ${session.isActive}
''';
  }

  String cmdPolicy() {
    final c = _container;
    if (c == null) return 'Runtime not initialized';

    final rules = c.policyEngine.rules;
    final buffer = StringBuffer('Policy Rules\n═════════════\n');
    for (final r in rules) {
      final effect = r.effect.name.toUpperCase().padRight(4);
      buffer.writeln(
        '  $effect ${r.callerPattern.padRight(15)} → ${r.targetPattern.padRight(20)} (priority: ${r.priority})',
      );
    }
    return buffer.toString();
  }

  String cmdResources() {
    final c = _container;
    if (c == null) return 'Runtime not initialized';

    final usage = c.resourceController.usage;
    final budget = c.resourceController.budget;
    final violations = c.resourceController.violations;

    return '''
Resource Usage
══════════════
  Tokens:      ${usage.tokensUsed}/${budget.maxTokens}
  Streams:     ${usage.activeStreams}/${budget.maxStreams}
  Memory:      ${usage.memoryUsedMb}/${budget.maxMemoryMb}MB
  Tasks:       ${usage.activeTasks}/${budget.maxTasks}
  Retries:     ${usage.totalRetries}/${budget.maxRetries}
  Violations:  ${violations.length}
''';
  }

  String cmdSnapshot() {
    final c = _container;
    if (c == null) return 'Runtime not initialized';

    final latest = c.snapshotService.latest;
    if (latest == null) return 'No snapshots available';

    return '''
Snapshot: #${latest.snapshotId}
══════════${'═' * latest.snapshotId.toString().length}
  Timestamp:     ${latest.timestamp}
  Status:        ${latest.status.name}
  Plugins:       ${latest.pluginStates.length}
  Sessions:      ${latest.sessions.length}
  Capabilities:  ${latest.capabilityCache.length}
''';
  }

  String cmdHelp() {
    return '''
Runtime CLI Commands
════════════════════
  inspect       Runtime state overview
  status        Quick status check
  plugins       List all plugins
  plugin <id>   Plugin details
  capabilities  List all capabilities
  journal [n]   Event journal (last n entries)
  traces [n]    Recent traces
  nodes         Cluster nodes
  node <id>     Node details
  session       Current session info
  policy        Policy rules
  resources     Resource usage
  snapshot      Latest snapshot
  help          This help message
''';
  }
}
