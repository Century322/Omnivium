import '../vocabulary/runtime_event.dart';
import '../kernel/runtime_clock.dart';
import '../plugins/persistence_backend.dart';

class JournalEntry {
  final int sequence;
  final int timestamp;
  final String type;
  final Map<String, dynamic> data;

  const JournalEntry({
    required this.sequence,
    required this.timestamp,
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'sequence': sequence,
        'timestamp': timestamp,
        'type': type,
        'data': data,
      };
}

class EventJournal {
  final List<JournalEntry> _entries = [];
  final RuntimeClock _clock;
  final PersistenceBackend? _persistence;
  int _sequence = 0;
  final int _compactionThreshold;

  EventJournal({
    required RuntimeClock clock,
    int compactionThreshold = 10000,
    PersistenceBackend? persistence,
  })  : _clock = clock,
        _compactionThreshold = compactionThreshold,
        _persistence = persistence;

  int get length => _entries.length;
  int get currentSequence => _sequence;
  List<JournalEntry> get entries => List.unmodifiable(_entries);

  JournalEntry append(String type, Map<String, dynamic> data) {
    final entry = JournalEntry(
      sequence: _sequence++,
      timestamp: _clock.now(),
      type: type,
      data: data,
    );
    _entries.add(entry);
    _persistEntry(entry);

    if (_entries.length >= _compactionThreshold) {
      compact();
    }

    return entry;
  }

  void _persistEntry(JournalEntry entry) {
    _persistence?.write('journal_${entry.sequence}', entry.toJson());
  }

  JournalEntry appendEvent(RuntimeEvent event) {
    return append('event', {
      'id': event.id,
      'type': event.type,
      'source': event.source.toJson(),
      'phase': event.phase.name,
      'permission': event.permission.name,
      'scope': event.scope.name,
      'payload': event.payload,
    });
  }

  JournalEntry appendPluginTransition(String pluginId, String from, String to) {
    return append('plugin_transition', {
      'pluginId': pluginId,
      'from': from,
      'to': to,
    });
  }

  JournalEntry appendCapabilityInvoke(String capabilityId, String pluginId, String callerId, {String status = 'started'}) {
    return append('capability_invoke', {
      'capabilityId': capabilityId,
      'pluginId': pluginId,
      'callerId': callerId,
      'status': status,
    });
  }

  JournalEntry appendTaskSchedule(String taskId, String status) {
    return append('task_schedule', {
      'taskId': taskId,
      'status': status,
    });
  }

  JournalEntry appendSnapshot(Map<String, dynamic> snapshot) {
    return append('snapshot', snapshot);
  }

  List<JournalEntry> replay({int? fromSequence, int? toSequence, String? type}) {
    var filtered = _entries;

    if (fromSequence != null) {
      filtered = filtered.where((e) => e.sequence >= fromSequence).toList();
    }
    if (toSequence != null) {
      filtered = filtered.where((e) => e.sequence <= toSequence).toList();
    }
    if (type != null) {
      filtered = filtered.where((e) => e.type == type).toList();
    }

    return filtered;
  }

  List<JournalEntry> replayFrom(int sequence) => replay(fromSequence: sequence);

  List<JournalEntry> replayType(String type) => replay(type: type);

  void compact({int? keepLast}) {
    final keep = keepLast ?? (_compactionThreshold ~/ 2);
    if (_entries.length <= keep) return;

    final snapshot = _entries.last;
    _entries.removeRange(0, _entries.length - keep);

    final compactEntry = JournalEntry(
      sequence: _sequence++,
      timestamp: _clock.now(),
      type: 'compaction',
      data: {
        'compactedFrom': snapshot.sequence - keep,
        'compactedTo': snapshot.sequence,
        'entriesRemoved': _compactionThreshold - keep,
      },
    );
    _entries.insert(0, compactEntry);
  }

  void clear() {
    _entries.clear();
    _sequence = 0;
  }
}
