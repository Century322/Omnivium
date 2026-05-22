import 'dart:async';
import '../kernel/runtime_container.dart';
import '../kernel/runtime_state.dart';
import '../distributed/distributed_runtime.dart';

enum ObservatoryEventType {
  runtimeStatus,
  pluginStateChange,
  capabilityInvoke,
  taskSchedule,
  resourceViolation,
  policyDecision,
  journalEntry,
  distributedEvent,
  traceSpan,
  snapshotTaken,
}

class ObservatoryEvent {
  final ObservatoryEventType type;
  final int timestamp;
  final Map<String, dynamic> data;

  const ObservatoryEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'timestamp': timestamp,
    'data': data,
  };
}

class RuntimeObservatory {
  final RuntimeContainer _container;
  final DistributedRuntime? _distributed;

  final StreamController<ObservatoryEvent> _eventController =
      StreamController<ObservatoryEvent>.broadcast();
  final List<ObservatoryEvent> _eventBuffer = [];
  final int _bufferSize;

  Timer? _pollTimer;
  RuntimeStatus? _lastStatus;
  int _lastJournalSeq = 0;

  RuntimeObservatory({
    required RuntimeContainer container,
    DistributedRuntime? distributed,
    int bufferSize = 1000,
  }) : _container = container,
       _distributed = distributed,
       _bufferSize = bufferSize;

  Stream<ObservatoryEvent> get events => _eventController.stream;
  List<ObservatoryEvent> get recentEvents => List.unmodifiable(_eventBuffer);
  bool get isActive => _pollTimer != null;

  void start({Duration interval = const Duration(milliseconds: 500)}) {
    if (_pollTimer != null) return;

    _lastJournalSeq =
        _container.eventJournal.replay().lastOrNull?.sequence ?? 0;
    _lastStatus = _container.stateSnapshot.status;

    _pollTimer = Timer.periodic(interval, (_) => _poll());
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _poll() {
    _checkRuntimeStatus();
    _checkJournal();
    _checkResources();
  }

  void _checkRuntimeStatus() {
    final snap = _container.stateSnapshot;
    if (_lastStatus != null && snap.status != _lastStatus) {
      _emit(ObservatoryEventType.runtimeStatus, {
        'from': _lastStatus!.name,
        'to': snap.status.name,
        'activePlugins': snap.activePluginCount,
        'activeTasks': snap.activeTaskCount,
      });
    }
    _lastStatus = snap.status;
  }

  void _checkJournal() {
    final entries = _container.eventJournal.replayFrom(_lastJournalSeq + 1);
    for (final entry in entries) {
      _emit(ObservatoryEventType.journalEntry, {
        'sequence': entry.sequence,
        'type': entry.type,
        'timestamp': entry.timestamp,
        'data': entry.data,
      });
    }
    if (entries.isNotEmpty) {
      _lastJournalSeq = entries.last.sequence;
    }
  }

  void _checkResources() {
    final violations = _container.resourceController.violations;
    if (violations.isNotEmpty) {
      final latest = violations.last;
      _emit(ObservatoryEventType.resourceViolation, {
        'type': latest.type.name,
        'current': latest.current,
        'limit': latest.limit,
        'message': latest.message,
      });
    }
  }

  void notifyPluginStateChange(String pluginId, String from, String to) {
    _emit(ObservatoryEventType.pluginStateChange, {
      'pluginId': pluginId,
      'from': from,
      'to': to,
    });
  }

  void notifyCapabilityInvoke(
    String capabilityId,
    String pluginId,
    String status,
  ) {
    _emit(ObservatoryEventType.capabilityInvoke, {
      'capabilityId': capabilityId,
      'pluginId': pluginId,
      'status': status,
    });
  }

  void notifyPolicyDecision(
    String callerId,
    String targetCapability,
    bool allowed,
  ) {
    _emit(ObservatoryEventType.policyDecision, {
      'callerId': callerId,
      'targetCapability': targetCapability,
      'allowed': allowed,
    });
  }

  void notifyDistributedEvent(String type, Map<String, dynamic> data) {
    _emit(ObservatoryEventType.distributedEvent, {'eventType': type, ...data});
  }

  void _emit(ObservatoryEventType type, Map<String, dynamic> data) {
    final event = ObservatoryEvent(
      type: type,
      timestamp: _container.clock.now(),
      data: data,
    );

    _eventBuffer.add(event);
    if (_eventBuffer.length > _bufferSize) {
      _eventBuffer.removeRange(0, _eventBuffer.length - _bufferSize);
    }

    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  Map<String, dynamic> getDashboard() {
    final snap = _container.stateSnapshot;
    return {
      'runtime': {
        'status': snap.status.name,
        'uptime': snap.uptimeMs,
        'bootTime': snap.bootTimeMs,
      },
      'plugins': {
        'loaded': snap.loadedPluginCount,
        'active': snap.activePluginCount,
      },
      'tasks': {'active': snap.activeTaskCount},
      'sessions': {'active': snap.activeSessionCount},
      'capabilities': {'total': snap.capabilityCount},
      'resources': {
        'tokens':
            '${_container.resourceController.usage.tokensUsed}/${_container.resourceController.budget.maxTokens}',
        'streams':
            '${_container.resourceController.usage.activeStreams}/${_container.resourceController.budget.maxStreams}',
        'violations': _container.resourceController.violations.length,
      },
      'journal': {'entries': _container.eventJournal.replay().length},
      'distributed': _distributed != null
          ? {
              'nodeId': _distributed.nodeId,
              'state': _distributed.state.name,
              'aliveNodes': _distributed.nodeDiscovery.aliveCount,
              'localCaps': _distributed.capabilityRouter.localCapabilityCount,
              'remoteCaps': _distributed.capabilityRouter.remoteCapabilityCount,
            }
          : null,
    };
  }

  Map<String, dynamic> getPluginGraph() {
    final descriptors = _container.pluginRegistry.loadedDescriptors;
    final nodes = <Map<String, dynamic>>[];
    final edges = <Map<String, dynamic>>[];

    for (final d in descriptors) {
      final state =
          _container.pluginRegistry.pluginStates[d.id]?.name ?? 'unknown';
      nodes.add({
        'id': d.id,
        'name': d.name,
        'version': d.version,
        'state': state,
        'capabilityCount': d.capabilities.length,
      });

      for (final dep in d.dependencies) {
        edges.add({
          'from': d.id,
          'to': dep.capabilityId,
          'optional': dep.optional,
        });
      }
    }

    return {'nodes': nodes, 'edges': edges};
  }

  Map<String, dynamic> getEventTimeline({int? lastN}) {
    final entries = _container.eventJournal.replay();
    final limited = lastN != null && entries.length > lastN
        ? entries.sublist(entries.length - lastN)
        : entries;

    return {
      'entries': limited
          .map(
            (e) => {
              'seq': e.sequence,
              'type': e.type,
              'ts': e.timestamp,
              'data': e.data,
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> getTraceFlamegraph() {
    final traces = _container.traceService.recentTraces(limit: 100);
    return {
      'traces': traces
          .map(
            (t) => {
              'traceId': t.traceId,
              'createdAt': t.createdAt,
              'totalDurationMs': t.totalDurationMs,
              'spanCount': t.spans.length,
              'spans': t.spans
                  .map(
                    (s) => {
                      'spanId': s.spanId,
                      'operation': s.operation,
                      'startTimeMs': s.startTimeMs,
                      'durationMs': s.durationMs,
                      'status': s.status,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> getDistributedMap() {
    final dist = _distributed;
    if (dist == null) return {'initialized': false};

    final nodes = dist.nodeDiscovery.allNodes;
    final bindings = dist.capabilityRouter.remoteBindings;

    return {
      'initialized': true,
      'localNodeId': dist.nodeId,
      'nodes': nodes
          .map(
            (n) => {
              'id': n.nodeId,
              'address': n.addressKey,
              'role': n.role.name,
              'state': n.state.name,
            },
          )
          .toList(),
      'remoteCapabilities': bindings
          .map(
            (b) => {
              'capabilityId': b.capabilityId,
              'providerNodeId': b.providerNodeId,
              'state': b.state.name,
            },
          )
          .toList(),
    };
  }

  void dispose() {
    _pollTimer?.cancel();
    _eventController.close();
  }
}
