import 'package:freezed_annotation/freezed_annotation.dart';
import 'cognitive_types.dart';

part 'goal_runtime.freezed.dart';

@freezed
class GoalNode with _$GoalNode {
  const GoalNode._();

  const factory GoalNode({
    required String id,
    required String title,
    @Default(GoalStatus.planned) GoalStatus status,
    String? parentGoalId,
    String? workspaceId,
    @Default(50) int priority,
    required DateTime createdAt,
    DateTime? completedAt,
    @Default(<String>[]) List<String> successConditions,
    @Default(<String>[]) List<String> failureConditions,
    DateTime? deadline,
    @Default(0) int progress,
    @Default(<String>[]) List<String> dependencies,
    @Default(<String>[]) List<String> blockers,
    @Default(<String>[]) List<String> relatedEntityIds,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _GoalNode;

  bool get isOverdue => deadline != null && DateTime.now().isAfter(deadline!) && status != GoalStatus.completed;
  bool get isBlocked => blockers.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status.name,
    'parentGoalId': parentGoalId,
    'workspaceId': workspaceId,
    'priority': priority,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'successConditions': successConditions,
    'failureConditions': failureConditions,
    'deadline': deadline?.toIso8601String(),
    'progress': progress,
    'dependencies': dependencies,
    'blockers': blockers,
    'relatedEntityIds': relatedEntityIds,
    'metadata': metadata,
  };

  factory GoalNode.fromJson(Map<String, dynamic> json) => GoalNode(
    id: json['id'] as String,
    title: json['title'] as String,
    status: GoalStatus.values.byName((json['status'] as String?) ?? 'planned'),
    parentGoalId: json['parentGoalId'] as String?,
    workspaceId: json['workspaceId'] as String?,
    priority: (json['priority'] as num?)?.toInt() ?? 50,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    successConditions: (json['successConditions'] as List<dynamic>?)?.cast<String>() ?? [],
    failureConditions: (json['failureConditions'] as List<dynamic>?)?.cast<String>() ?? [],
    deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    dependencies: (json['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
    blockers: (json['blockers'] as List<dynamic>?)?.cast<String>() ?? [],
    relatedEntityIds: (json['relatedEntityIds'] as List<dynamic>?)?.cast<String>() ?? [],
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );
}
