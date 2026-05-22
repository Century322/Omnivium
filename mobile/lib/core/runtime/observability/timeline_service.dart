import '../vocabulary/runtime_event.dart';
import '../kernel/runtime_clock.dart';

enum TimelineEntryType {
  event,
  pluginLifecycle,
  capabilityInvoke,
  taskSchedule,
  taskComplete,
  streamOpen,
  streamClose,
  traceStart,
  traceEnd,
}

class TimelineEntry {
  final int timestamp;
  final TimelineEntryType type;
  final String source;
  final Map<String, dynamic> data;

  const TimelineEntry({
    required this.timestamp,
    required this.type,
    required this.source,
    this.data = const {},
  });
}

class TimelineService {
  final List<TimelineEntry> _entries = [];
  final RuntimeClock _clock;

  TimelineService(this._clock);

  List<TimelineEntry> get entries => List.unmodifiable(_entries);
  int get entryCount => _entries.length;

  void record(
    TimelineEntryType type,
    String source, {
    Map<String, dynamic> data = const {},
  }) {
    _entries.add(
      TimelineEntry(
        timestamp: _clock.now(),
        type: type,
        source: source,
        data: data,
      ),
    );
  }

  void recordEvent(RuntimeEvent event) {
    record(
      TimelineEntryType.event,
      event.source.pluginId,
      data: {
        'eventType': event.type,
        'phase': event.phase.name,
        'scope': event.scope.name,
        'permission': event.permission.name,
      },
    );
  }

  void recordPluginLifecycle(
    String pluginId,
    String transition, {
    String from = '',
    String to = '',
  }) {
    record(
      TimelineEntryType.pluginLifecycle,
      pluginId,
      data: {'transition': transition, 'from': from, 'to': to},
    );
  }

  void recordCapabilityInvoke(
    String capabilityId,
    String pluginId, {
    String status = 'started',
  }) {
    record(
      TimelineEntryType.capabilityInvoke,
      pluginId,
      data: {'capabilityId': capabilityId, 'status': status},
    );
  }

  void recordTask(String taskId, {String status = 'scheduled'}) {
    record(
      TimelineEntryType.taskSchedule,
      'scheduler',
      data: {'taskId': taskId, 'status': status},
    );
  }

  List<TimelineEntry> replay({
    int? fromTimestamp,
    int? toTimestamp,
    TimelineEntryType? type,
    String? source,
  }) {
    var filtered = _entries;

    if (fromTimestamp != null) {
      filtered = filtered.where((e) => e.timestamp >= fromTimestamp).toList();
    }
    if (toTimestamp != null) {
      filtered = filtered.where((e) => e.timestamp <= toTimestamp).toList();
    }
    if (type != null) {
      filtered = filtered.where((e) => e.type == type).toList();
    }
    if (source != null) {
      filtered = filtered.where((e) => e.source == source).toList();
    }

    return filtered;
  }

  List<TimelineEntry> replayForPlugin(String pluginId) =>
      replay(source: pluginId);

  List<TimelineEntry> replayForCapability(String capabilityId) =>
      _entries.where((e) => e.data['capabilityId'] == capabilityId).toList();

  Map<String, dynamic> timelineSummary() {
    final byType = <String, int>{};
    for (final entry in _entries) {
      final key = entry.type.name;
      byType[key] = (byType[key] ?? 0) + 1;
    }

    final bySource = <String, int>{};
    for (final entry in _entries) {
      bySource[entry.source] = (bySource[entry.source] ?? 0) + 1;
    }

    return {
      'totalEntries': _entries.length,
      'byType': byType,
      'bySource': bySource,
      'timeRange': _entries.isEmpty
          ? null
          : {
              'start': _entries.first.timestamp,
              'end': _entries.last.timestamp,
              'durationMs': _entries.last.timestamp - _entries.first.timestamp,
            },
    };
  }

  void clear() => _entries.clear();
}
