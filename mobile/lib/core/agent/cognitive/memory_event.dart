import 'package:freezed_annotation/freezed_annotation.dart';
import 'cognitive_types.dart';

part 'memory_event.freezed.dart';

@freezed
class MemoryEvent with _$MemoryEvent {
  const MemoryEvent._();

  const factory MemoryEvent({
    required String id,
    required DateTime timestamp,
    required String eventType,
    required String summary,
    String? entityId,
    @Default(50) int importance,
    @Default(MemoryPersistence.shortTerm) MemoryPersistence persistence,
    @Default(80) double confidence,
    @Default(MemoryType.fact) MemoryType memoryType,
    @Default(IntentType.fact) IntentType intent,
    @Default(MemoryDomain.project) MemoryDomain domain,
    String? workspaceId,
    String? speakerId,
    @Default('conversation') String source,
    String? snapshotId,
    @Default(MemoryLifecycle.active) MemoryLifecycle lifecycle,
    String? reason,
    @Default(<String, dynamic>{}) Map<String, dynamic> properties,
  }) = _MemoryEvent;

  bool get shouldStore => importance >= 20;
  bool get isLongTerm => importance >= 60;
  bool get isCritical => importance >= 80;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'eventType': eventType,
    'summary': summary,
    'entityId': entityId,
    'importance': importance,
    'persistence': persistence.name,
    'confidence': confidence,
    'memoryType': memoryType.name,
    'intent': intent.name,
    'domain': domain.name,
    'workspaceId': workspaceId,
    'speakerId': speakerId,
    'source': source,
    'snapshotId': snapshotId,
    'lifecycle': lifecycle.name,
    'reason': reason,
    'properties': properties,
  };

  factory MemoryEvent.fromJson(Map<String, dynamic> json) => MemoryEvent(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    eventType: json['eventType'] as String,
    summary: json['summary'] as String,
    entityId: json['entityId'] as String?,
    importance: (json['importance'] as num?)?.toInt() ?? 50,
    persistence: MemoryPersistence.values.byName((json['persistence'] as String?) ?? 'shortTerm'),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 80,
    memoryType: MemoryType.values.byName((json['memoryType'] as String?) ?? 'fact'),
    intent: IntentType.values.byName((json['intent'] as String?) ?? 'fact'),
    domain: MemoryDomain.values.byName((json['domain'] as String?) ?? 'project'),
    workspaceId: json['workspaceId'] as String?,
    speakerId: json['speakerId'] as String?,
    source: (json['source'] as String?) ?? 'conversation',
    snapshotId: json['snapshotId'] as String?,
    lifecycle: MemoryLifecycle.values.byName((json['lifecycle'] as String?) ?? 'active'),
    reason: json['reason'] as String?,
    properties: (json['properties'] as Map<String, dynamic>?) ?? {},
  );
}

@freezed
class MemorySnapshot with _$MemorySnapshot {
  const MemorySnapshot._();

  const factory MemorySnapshot({
    required String id,
    required String eventId,
    required String rawMessage,
    @Default(<String>[]) List<String> contextBefore,
    @Default(<String>[]) List<String> contextAfter,
    required DateTime createdAt,
  }) = _MemorySnapshot;

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'rawMessage': rawMessage,
    'contextBefore': contextBefore,
    'contextAfter': contextAfter,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MemorySnapshot.fromJson(Map<String, dynamic> json) => MemorySnapshot(
    id: json['id'] as String,
    eventId: json['eventId'] as String,
    rawMessage: json['rawMessage'] as String,
    contextBefore: (json['contextBefore'] as List<dynamic>?)?.cast<String>() ?? [],
    contextAfter: (json['contextAfter'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
