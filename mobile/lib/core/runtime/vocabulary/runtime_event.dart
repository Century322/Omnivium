import 'runtime_metadata.dart';
import 'runtime_route.dart';

enum EventPhase { before, during, after }

enum EventPermission { observe, intercept, mutate }

enum PropagationScope { local, session, node, cluster }

class RuntimeEvent {
  final String id;
  final int version;
  final String type;
  final RuntimeRoute source;
  final EventPhase phase;
  final dynamic payload;
  final RuntimeMetadata metadata;
  final EventPermission permission;
  final PropagationScope scope;
  final int timestamp;

  const RuntimeEvent({
    required this.id,
    this.version = 1,
    required this.type,
    required this.source,
    this.phase = EventPhase.during,
    this.payload,
    required this.metadata,
    this.permission = EventPermission.observe,
    this.scope = PropagationScope.local,
    required this.timestamp,
  });

  RuntimeEvent copyWith({
    String? id,
    int? version,
    String? type,
    RuntimeRoute? source,
    EventPhase? phase,
    dynamic payload,
    RuntimeMetadata? metadata,
    EventPermission? permission,
    PropagationScope? scope,
    int? timestamp,
  }) => RuntimeEvent(
    id: id ?? this.id,
    version: version ?? this.version,
    type: type ?? this.type,
    source: source ?? this.source,
    phase: phase ?? this.phase,
    payload: payload ?? this.payload,
    metadata: metadata ?? this.metadata,
    permission: permission ?? this.permission,
    scope: scope ?? this.scope,
    timestamp: timestamp ?? this.timestamp,
  );
}
