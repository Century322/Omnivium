import 'dart:convert';
import 'database_service.dart';
import 'omni_model.dart';
import 'action_executor.dart';
import 'agent_service.dart';
import 'agent/cognitive/multi_agent_society.dart';
import 'event_store.dart';
import 'app_logger.dart';
import 'di/app_di.dart';

enum StepStatus {
  pending,
  ready,
  running,
  completed,
  failed,
  skipped,
}

enum PlanStatus {
  draft,
  approved,
  executing,
  completed,
  failed,
  cancelled,
}

class PlanStep {
  final String id;
  final String description;
  final List<String> dependencies;
  final String? actionId;
  final String? objectType;
  final String? objectId;
  final Map<String, dynamic> params;
  final String? assignedAgentId;
  StepStatus status;
  String? result;
  String? error;
  DateTime? startedAt;
  DateTime? completedAt;

  PlanStep({
    required this.id,
    required this.description,
    this.dependencies = const [],
    this.actionId,
    this.objectType,
    this.objectId,
    this.params = const {},
    this.assignedAgentId,
    this.status = StepStatus.pending,
    this.result,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  bool get isReady =>
      status == StepStatus.pending && dependencies.isEmpty;

  bool get isComplete => status == StepStatus.completed;

  bool get isFailed => status == StepStatus.failed;

  PlanStep copyWith({
    StepStatus? status,
    String? result,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) =>
      PlanStep(
        id: id,
        description: description,
        dependencies: dependencies,
        actionId: actionId,
        objectType: objectType,
        objectId: objectId,
        params: params,
        assignedAgentId: assignedAgentId,
        status: status ?? this.status,
        result: result ?? this.result,
        error: error ?? this.error,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'dependencies': dependencies,
        'actionId': actionId,
        'objectType': objectType,
        'objectId': objectId,
        'params': params,
        'assignedAgentId': assignedAgentId,
        'status': status.name,
        if (result != null) 'result': result,
        if (error != null) 'error': error,
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (completedAt != null)
          'completedAt': completedAt!.toIso8601String(),
      };

  factory PlanStep.fromJson(Map<String, dynamic> json) => PlanStep(
        id: json['id'] as String,
        description: json['description'] as String,
        dependencies: (json['dependencies'] as List<dynamic>?)
                ?.cast<String>() ??
            [],
        actionId: json['actionId'] as String?,
        objectType: json['objectType'] as String?,
        objectId: json['objectId'] as String?,
        params: (json['params'] as Map<String, dynamic>?) ?? {},
        assignedAgentId: json['assignedAgentId'] as String?,
        status: StepStatus.values.byName(
            (json['status'] as String?) ?? 'pending'),
        result: json['result'] as String?,
        error: json['error'] as String?,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}

class Plan {
  final String id;
  final String title;
  final String description;
  final String? projectId;
  PlanStatus status;
  final List<PlanStep> steps;
  final DateTime createdAt;
  DateTime? completedAt;
  Map<String, dynamic> metadata;

  Plan({
    required this.id,
    required this.title,
    this.description = '',
    this.projectId,
    this.status = PlanStatus.draft,
    this.steps = const [],
    DateTime? createdAt,
    this.completedAt,
    this.metadata = const {},
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (steps.isEmpty) return 0;
    final completed = steps.where((s) => s.isComplete).length;
    return completed / steps.length * 100;
  }

  List<PlanStep> get readySteps => steps
      .where((s) =>
          s.status == StepStatus.pending &&
          s.dependencies.every((depId) {
            final dep = steps.firstWhere(
              (s) => s.id == depId,
              orElse: () => PlanStep(id: '_none', description: ''),
            );
            return dep.isComplete;
          }))
      .toList();

  List<PlanStep> get runningSteps =>
      steps.where((s) => s.status == StepStatus.running).toList();

  bool get isComplete =>
      steps.isNotEmpty && steps.every((s) => s.isComplete || s.isFailed);

  Plan copyWith({
    PlanStatus? status,
    List<PlanStep>? steps,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) =>
      Plan(
        id: id,
        title: title,
        description: description,
        projectId: projectId,
        status: status ?? this.status,
        steps: steps ?? this.steps,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
        metadata: metadata ?? this.metadata,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'projectId': projectId,
        'status': status.name,
        'steps': steps.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        if (completedAt != null)
          'completedAt': completedAt!.toIso8601String(),
        'metadata': metadata,
      };

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'] as String,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        projectId: json['projectId'] as String?,
        status: PlanStatus.values.byName(
            (json['status'] as String?) ?? 'draft'),
        steps: (json['steps'] as List<dynamic>?)
                ?.map((s) => PlanStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );
}

class PlanningEngine {
  static const _plansKey = 'planning_plans';

  final DatabaseService _db;
  List<Plan> _plans = [];
  bool _initialized = false;

  PlanningEngine(this._db);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final json = await _db.getCache(_plansKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _plans =
            list.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('PlanningEngine init failed',
          error: e, stackTrace: st);
    }
  }

  bool get isInitialized => _initialized;

  Future<void> _persist() async {
    try {
      await _db.putCache(
          _plansKey, jsonEncode(_plans.map((p) => p.toJson()).toList()));
    } catch (e, st) {
      AppLogger.instance.error('PlanningEngine persist failed',
          error: e, stackTrace: st);
    }
  }

  List<Plan> get plans => List.unmodifiable(_plans);
  List<Plan> get activePlans =>
      _plans.where((p) => p.status == PlanStatus.executing).toList();

  Plan? getPlan(String id) {
    final idx = _plans.indexWhere((p) => p.id == id);
    return idx >= 0 ? _plans[idx] : null;
  }

  Future<Plan> createPlan({
    required String title,
    String description = '',
    String? projectId,
    required List<PlanStep> steps,
  }) async {
    final plan = Plan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}_${title.hashCode.abs()}',
      title: title,
      description: description,
      projectId: projectId,
      steps: steps,
      status: PlanStatus.draft,
    );
    _plans.add(plan);
    await _persist();
    _recordEvent(DomainEventType.planCreated, plan.id, 'plan', {
      'title': title,
      'stepCount': steps.length,
      if (projectId != null) 'projectId': projectId,
    });
    return plan;
  }

  Future<void> approvePlan(String planId) async {
    final idx = _plans.indexWhere((p) => p.id == planId);
    if (idx < 0) return;
    _plans[idx] = _plans[idx].copyWith(status: PlanStatus.approved);
    await _persist();
  }

  Future<Plan> createAndApprove({
    required String title,
    String description = '',
    String? projectId,
    required List<PlanStep> steps,
  }) async {
    final plan = await createPlan(
      title: title,
      description: description,
      projectId: projectId,
      steps: steps,
    );
    await approvePlan(plan.id);
    return plan;
  }

  Future<void> executePlan(String planId) async {
    final idx = _plans.indexWhere((p) => p.id == planId);
    if (idx < 0) return;

    _plans[idx] = _plans[idx].copyWith(status: PlanStatus.executing);
    await _persist();

    await _executeReadySteps(planId);
  }

  Future<void> _executeReadySteps(String planId) async {
    final plan = getPlan(planId);
    if (plan == null) return;

    final ready = plan.readySteps;
    if (ready.isEmpty && plan.runningSteps.isEmpty) {
      if (plan.isComplete) {
        final idx = _plans.indexWhere((p) => p.id == planId);
        _plans[idx] = _plans[idx].copyWith(
          status: PlanStatus.completed,
          completedAt: DateTime.now(),
        );
        await _persist();
      }
      return;
    }

    for (final step in ready) {
      await _executeStep(planId, step.id);
    }
  }

  Future<void> _executeStep(String planId, String stepId) async {
    final plan = getPlan(planId);
    if (plan == null) return;

    final stepIdx = plan.steps.indexWhere((s) => s.id == stepId);
    if (stepIdx < 0) return;

    final step = plan.steps[stepIdx];
    final updatedStep = step.copyWith(
      status: StepStatus.running,
      startedAt: DateTime.now(),
    );
    final updatedSteps = List<PlanStep>.from(plan.steps);
    updatedSteps[stepIdx] = updatedStep;

    final planIdx = _plans.indexWhere((p) => p.id == planId);
    _plans[planIdx] = _plans[planIdx].copyWith(steps: updatedSteps);
    await _persist();

    try {
      ActionResult? actionResult;

      if (step.actionId != null) {
        final registry = OmniObjectRegistry.instance;
        OmniObject? targetObj;
        if (step.objectId != null) {
          targetObj = registry.getObject(step.objectId!) ??
              registry.findObject(step.objectId!);
        }

        if (targetObj != null) {
          final actions = registry.getActionsForObject(targetObj);
          final action = actions.firstWhere(
            (a) => a.id == step.actionId,
            orElse: () => OmniAction(
              id: step.actionId!,
              name: step.actionId!,
              description: step.description,
              objectTypeId: step.objectType ?? '',
              capabilityId: step.actionId!,
            ),
          );
          actionResult =
              await ActionExecutor.instance.execute(action, targetObj, step.params);
        } else {
          actionResult = ActionResult.failure(
              step.actionId!, step.objectId ?? '', 'Object not found');
        }
      }

      final resultStep = updatedStep.copyWith(
        status: actionResult?.success ?? true
            ? StepStatus.completed
            : StepStatus.failed,
        result: actionResult?.data?.toString() ?? 'completed',
        error: actionResult?.error,
        completedAt: DateTime.now(),
      );
      updatedSteps[stepIdx] = resultStep;
      _plans[planIdx] = _plans[planIdx].copyWith(steps: updatedSteps);
      await _persist();

      await _executeReadySteps(planId);
    } catch (e) {
      final failedStep = updatedStep.copyWith(
        status: StepStatus.failed,
        error: e.toString(),
        completedAt: DateTime.now(),
      );
      updatedSteps[stepIdx] = failedStep;
      _plans[planIdx] = _plans[planIdx].copyWith(steps: updatedSteps);
      await _persist();
    }
  }

  Future<void> cancelPlan(String planId) async {
    final idx = _plans.indexWhere((p) => p.id == planId);
    if (idx < 0) return;
    _plans[idx] = _plans[idx].copyWith(status: PlanStatus.cancelled);
    await _persist();
  }

  Plan? parsePlanFromJson(Map<String, dynamic> json) {
    try {
      final stepsJson = json['steps'] as List<dynamic>?;
      if (stepsJson == null || stepsJson.isEmpty) return null;

      final steps = stepsJson.map((s) {
        final stepMap = s as Map<String, dynamic>;
        return PlanStep(
          id: stepMap['id'] as String? ??
              'step_${stepMap.hashCode.abs()}',
          description: stepMap['description'] as String? ?? '',
          dependencies: (stepMap['dependsOn'] as List<dynamic>?)
                  ?.cast<String>() ??
              [],
          actionId: stepMap['actionId'] as String?,
          objectType: stepMap['objectType'] as String?,
          objectId: stepMap['objectId'] as String?,
          params: (stepMap['params'] as Map<String, dynamic>?) ?? {},
          assignedAgentId: stepMap['agentId'] as String?,
        );
      }).toList();

      return Plan(
        id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] as String? ?? 'Untitled Plan',
        description: json['description'] as String? ?? '',
        projectId: json['projectId'] as String?,
        steps: steps,
        status: PlanStatus.draft,
      );
    } catch (e) {
      AppLogger.instance.warning('Failed to parse plan from JSON', error: e);
      return null;
    }
  }

  String buildPlanContext() {
    final active = activePlans;
    final recent = _plans
        .where((p) =>
            p.status == PlanStatus.completed ||
            p.status == PlanStatus.cancelled)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (active.isEmpty && recent.isEmpty) return '';

    final buffer = StringBuffer();

    if (active.isNotEmpty) {
      buffer.writeln('[Active Plans]');
      for (final plan in active) {
        buffer.writeln(
            '  - ${plan.title}: ${plan.progress.toStringAsFixed(0)}% (${plan.steps.where((s) => s.isComplete).length}/${plan.steps.length} steps)');
        for (final step in plan.steps.take(5)) {
          final marker = step.isComplete
              ? '✓'
              : step.status == StepStatus.running
                  ? '→'
                  : '○';
          buffer.writeln('    $marker ${step.description}');
        }
      }
    }

    if (recent.isNotEmpty) {
      buffer.writeln('[Recent Plans]');
      for (final plan in recent.take(3)) {
        buffer.writeln(
            '  - ${plan.title}: ${plan.status.name} (${plan.progress.toStringAsFixed(0)}%)');
      }
    }

    return buffer.toString();
  }

  void _recordEvent(DomainEventType type, String aggregateId, String aggregateType, Map<String, dynamic> payload) {
    try {
      final eventStore = getIt<EventStore>();
      if (eventStore.isInitialized) {
        final event = eventStore.createEvent(
          type: type,
          aggregateId: aggregateId,
          aggregateType: aggregateType,
          payload: payload,
        );
        eventStore.append(event);
      }
    } catch (_) {}
  }
}
