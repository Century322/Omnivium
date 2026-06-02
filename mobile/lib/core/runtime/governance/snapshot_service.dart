import '../plugin/plugin_lifecycle.dart';
import '../vocabulary/runtime_session.dart';
import '../kernel/runtime_clock.dart';
import '../kernel/runtime_state.dart';
import '../plugins/persistence_backend.dart';
import 'resource_controller.dart';

class RuntimeSnapshot {
  final int snapshotId;
  final int timestamp;
  final RuntimeStatus status;
  final Map<String, String> pluginStates;
  final List<SessionSnapshot> sessions;
  final List<String> capabilityCache;
  final ResourceUsage resourceUsage;
  final Map<String, dynamic> extra;

  RuntimeSnapshot({
    required this.snapshotId,
    required this.timestamp,
    required this.status,
    this.pluginStates = const {},
    this.sessions = const [],
    this.capabilityCache = const [],
    ResourceUsage? resourceUsage,
    this.extra = const {},
  }) : resourceUsage = resourceUsage ?? ResourceUsage();

  Map<String, dynamic> toJson() => {
    'snapshotId': snapshotId,
    'timestamp': timestamp,
    'status': status.name,
    'pluginStates': pluginStates,
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'capabilityCache': capabilityCache,
    'resourceUsage': resourceUsage.toJson(),
    'extra': extra,
  };
}

class SessionSnapshot {
  final String id;
  final String userId;
  final String state;
  final int createdAt;
  final int lastActiveAt;

  const SessionSnapshot({
    required this.id,
    required this.userId,
    required this.state,
    required this.createdAt,
    required this.lastActiveAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'state': state,
    'createdAt': createdAt,
    'lastActiveAt': lastActiveAt,
  };
}

class SnapshotService {
  final RuntimeClock _clock;
  final PersistenceBackend? _persistence;
  final List<RuntimeSnapshot> _snapshots = [];
  int _snapshotId = 0;

  SnapshotService(this._clock, {PersistenceBackend? persistence})
    : _persistence = persistence;

  List<RuntimeSnapshot> get snapshots => List.unmodifiable(_snapshots);
  int get snapshotCount => _snapshots.length;
  RuntimeSnapshot? get latest => _snapshots.isNotEmpty ? _snapshots.last : null;

  RuntimeSnapshot take({
    required RuntimeStatus status,
    required Map<String, PluginState> pluginStates,
    required Map<String, RuntimeSession> sessions,
    required List<String> capabilityCache,
    required ResourceUsage resourceUsage,
    Map<String, dynamic> extra = const {},
  }) {
    final snapshot = RuntimeSnapshot(
      snapshotId: _snapshotId++,
      timestamp: _clock.now(),
      status: status,
      pluginStates: pluginStates.map((k, v) => MapEntry(k, v.name)),
      sessions: sessions.values
          .map(
            (s) => SessionSnapshot(
              id: s.id,
              userId: s.userId,
              state: s.state.name,
              createdAt: s.createdAt,
              lastActiveAt: s.lastActiveAt))
          .toList(),
      capabilityCache: capabilityCache,
      resourceUsage: resourceUsage,
      extra: extra);

    _snapshots.add(snapshot);
    _persistSnapshot(snapshot);
    return snapshot;
  }

  void _persistSnapshot(RuntimeSnapshot snapshot) {
    _persistence?.write('snapshot_${snapshot.snapshotId}', snapshot.toJson());
  }

  RuntimeSnapshot? getSnapshot(int id) {
    for (final s in _snapshots) {
      if (s.snapshotId == id) return s;
    }
    return null;
  }

  List<RuntimeSnapshot> snapshotsInRange(int fromTimestamp, int toTimestamp) {
    return _snapshots
        .where(
          (s) => s.timestamp >= fromTimestamp && s.timestamp <= toTimestamp)
        .toList();
  }

  void prune({int? keepLast}) {
    final keep = keepLast ?? 10;
    if (_snapshots.length <= keep) return;
    _snapshots.removeRange(0, _snapshots.length - keep);
  }

  void clear() {
    _snapshots.clear();
    _snapshotId = 0;
  }
}
