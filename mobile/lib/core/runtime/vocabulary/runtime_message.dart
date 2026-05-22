import 'runtime_metadata.dart';
import 'runtime_route.dart';
import 'runtime_event.dart';

class RuntimeMessage {
  final String id;
  final int version;
  final String type;
  final RuntimeRoute source;
  final RuntimeRoute target;
  final dynamic payload;
  final RuntimeMetadata metadata;
  final PropagationScope scope;
  final int timestamp;

  const RuntimeMessage({
    required this.id,
    this.version = 1,
    required this.type,
    required this.source,
    required this.target,
    this.payload,
    required this.metadata,
    this.scope = PropagationScope.local,
    required this.timestamp,
  });

  RuntimeMessage copyWith({
    String? id,
    int? version,
    String? type,
    RuntimeRoute? source,
    RuntimeRoute? target,
    dynamic payload,
    RuntimeMetadata? metadata,
    PropagationScope? scope,
    int? timestamp,
  }) => RuntimeMessage(
    id: id ?? this.id,
    version: version ?? this.version,
    type: type ?? this.type,
    source: source ?? this.source,
    target: target ?? this.target,
    payload: payload ?? this.payload,
    metadata: metadata ?? this.metadata,
    scope: scope ?? this.scope,
    timestamp: timestamp ?? this.timestamp,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'type': type,
    'source': source.toJson(),
    'target': target.toJson(),
    'payload': payload,
    'metadata': metadata.toJson(),
    'scope': scope.name,
    'timestamp': timestamp,
  };
}
