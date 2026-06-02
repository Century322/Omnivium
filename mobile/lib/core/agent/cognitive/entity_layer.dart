import 'package:freezed_annotation/freezed_annotation.dart';
import 'cognitive_types.dart';

part 'entity_layer.freezed.dart';

@freezed
class EntityState with _$EntityState {
  const EntityState._();

  const factory EntityState({
    required String id,
    required String entityId,
    required String state,
    required DateTime since,
    String? sourceEventId,
    @Default(<String, dynamic>{}) Map<String, dynamic> context,
  }) = _EntityState;

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityId': entityId,
    'state': state,
    'since': since.toIso8601String(),
    'sourceEventId': sourceEventId,
    'context': context,
  };

  factory EntityState.fromJson(Map<String, dynamic> json) => EntityState(
    id: json['id'] as String,
    entityId: json['entityId'] as String,
    state: json['state'] as String,
    since: DateTime.parse(json['since'] as String),
    sourceEventId: json['sourceEventId'] as String?,
    context: (json['context'] as Map<String, dynamic>?) ?? {},
  );
}

@freezed
class MemoryEntity with _$MemoryEntity {
  const MemoryEntity._();

  const factory MemoryEntity({
    required String id,
    required String name,
    required EntityType type,
    @Default(MemoryDomain.project) MemoryDomain domain,
    String? workspaceId,
    @Default(MemoryLifecycle.active) MemoryLifecycle lifecycle,
    @Default('unknown') String currentState,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime lastAccessedAt,
    @Default(<String, dynamic>{}) Map<String, dynamic> properties,
  }) = _MemoryEntity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'domain': domain.name,
    'workspaceId': workspaceId,
    'lifecycle': lifecycle.name,
    'currentState': currentState,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
    'properties': properties,
  };

  factory MemoryEntity.fromJson(Map<String, dynamic> json) => MemoryEntity(
    id: json['id'] as String,
    name: json['name'] as String,
    type: EntityType.values.byName(json['type'] as String),
    domain: MemoryDomain.values.byName((json['domain'] as String?) ?? 'project'),
    workspaceId: json['workspaceId'] as String?,
    lifecycle: MemoryLifecycle.values.byName((json['lifecycle'] as String?) ?? 'active'),
    currentState: (json['currentState'] as String?) ?? 'unknown',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    lastAccessedAt: DateTime.parse((json['lastAccessedAt'] as String?) ?? json['updatedAt'] as String),
    properties: (json['properties'] as Map<String, dynamic>?) ?? {},
  );
}

@freezed
class EntityRelation with _$EntityRelation {
  const EntityRelation._();

  const factory EntityRelation({
    required String id,
    required String fromEntityId,
    required String toEntityId,
    required RelationType type,
    @Default(1.0) double strength,
    required DateTime since,
    String? sourceEventId,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _EntityRelation;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromEntityId': fromEntityId,
    'toEntityId': toEntityId,
    'type': type.name,
    'strength': strength,
    'since': since.toIso8601String(),
    'sourceEventId': sourceEventId,
    'metadata': metadata,
  };

  factory EntityRelation.fromJson(Map<String, dynamic> json) => EntityRelation(
    id: json['id'] as String,
    fromEntityId: json['fromEntityId'] as String,
    toEntityId: json['toEntityId'] as String,
    type: RelationType.values.byName(json['type'] as String),
    strength: (json['strength'] as num?)?.toDouble() ?? 1.0,
    since: DateTime.parse(json['since'] as String),
    sourceEventId: json['sourceEventId'] as String?,
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );
}

class SubGraph {
  final List<MemoryEntity> entities;
  final List<EntityRelation> relations;

  const SubGraph({required this.entities, required this.relations});

  String toDescription() {
    final buffer = StringBuffer();
    for (final e in entities) {
      buffer.writeln('- ${e.name} (${e.type.name}): ${e.currentState}');
    }
    for (final r in relations) {
      final from = entities.where((e) => e.id == r.fromEntityId).firstOrNull;
      final to = entities.where((e) => e.id == r.toEntityId).firstOrNull;
      if (from != null && to != null) {
        buffer.writeln('- ${from.name} ─${r.type.name}→ ${to.name}');
      }
    }
    return buffer.toString();
  }
}
