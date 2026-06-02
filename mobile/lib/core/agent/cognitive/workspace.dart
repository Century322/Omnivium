import 'package:freezed_annotation/freezed_annotation.dart';
import 'cognitive_types.dart';

part 'workspace.freezed.dart';

@freezed
class MemoryTopic with _$MemoryTopic {
  const factory MemoryTopic({
    required String id,
    required String subspaceId,
    required String name,
    required DateTime lastActiveAt,
  }) = _MemoryTopic;

  Map<String, dynamic> toJson() => {
    'id': id,
    'subspaceId': subspaceId,
    'name': name,
    'lastActiveAt': lastActiveAt.toIso8601String(),
  };

  factory MemoryTopic.fromJson(Map<String, dynamic> json) => MemoryTopic(
    id: json['id'] as String,
    subspaceId: json['subspaceId'] as String,
    name: json['name'] as String,
    lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
  );
}

@freezed
class MemorySubspace with _$MemorySubspace {
  const factory MemorySubspace({
    required String id,
    required String workspaceId,
    required String name,
    required DateTime lastActiveAt,
  }) = _MemorySubspace;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'name': name,
    'lastActiveAt': lastActiveAt.toIso8601String(),
  };

  factory MemorySubspace.fromJson(Map<String, dynamic> json) => MemorySubspace(
    id: json['id'] as String,
    workspaceId: json['workspaceId'] as String,
    name: json['name'] as String,
    lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
  );
}

@freezed
class MemoryWorkspace with _$MemoryWorkspace {
  const MemoryWorkspace._();

  const factory MemoryWorkspace({
    required String id,
    required String name,
    @Default(MemoryDomain.project) MemoryDomain domain,
    @Default(MemoryLifecycle.active) MemoryLifecycle lifecycle,
    required DateTime lastActiveAt,
  }) = _MemoryWorkspace;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'domain': domain.name,
    'lifecycle': lifecycle.name,
    'lastActiveAt': lastActiveAt.toIso8601String(),
  };

  factory MemoryWorkspace.fromJson(Map<String, dynamic> json) => MemoryWorkspace(
    id: json['id'] as String,
    name: json['name'] as String,
    domain: MemoryDomain.values.byName((json['domain'] as String?) ?? 'project'),
    lifecycle: MemoryLifecycle.values.byName((json['lifecycle'] as String?) ?? 'active'),
    lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
  );
}
