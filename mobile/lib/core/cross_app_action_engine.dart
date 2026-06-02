import 'dart:convert';
import 'app_logger.dart';
import 'database_service.dart';
import 'omni_model.dart';
import 'action_executor.dart';
import 'capability_system.dart';
import 'event_store.dart';
import 'di/app_di.dart';

enum ChainStepStatus {
  pending,
  running,
  completed,
  failed,
  skipped,
}

enum ChainStatus {
  draft,
  running,
  completed,
  failed,
  partiallyCompleted,
  cancelled,
}

class DataFlowMapping {
  final String sourceStepId;
  final String sourceOutputKey;
  final String targetParamKey;

  const DataFlowMapping({
    required this.sourceStepId,
    required this.sourceOutputKey,
    required this.targetParamKey,
  });

  Map<String, dynamic> toJson() => {
    'sourceStepId': sourceStepId,
    'sourceOutputKey': sourceOutputKey,
    'targetParamKey': targetParamKey,
  };

  factory DataFlowMapping.fromJson(Map<String, dynamic> json) => DataFlowMapping(
    sourceStepId: json['sourceStepId'] as String,
    sourceOutputKey: json['sourceOutputKey'] as String,
    targetParamKey: json['targetParamKey'] as String,
  );
}

class ChainStep {
  final String id;
  final String name;
  final String? capabilityId;
  final String? actionId;
  final String? objectTypeId;
  final String? objectId;
  final Map<String, dynamic> staticParams;
  final List<DataFlowMapping> inputMappings;
  ChainStepStatus status;
  Map<String, dynamic>? resultData;
  String? error;

  ChainStep({
    required this.id,
    required this.name,
    this.capabilityId,
    this.actionId,
    this.objectTypeId,
    this.objectId,
    this.staticParams = const {},
    this.inputMappings = const [],
    this.status = ChainStepStatus.pending,
    this.resultData,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (capabilityId != null) 'capabilityId': capabilityId,
    if (actionId != null) 'actionId': actionId,
    if (objectTypeId != null) 'objectTypeId': objectTypeId,
    if (objectId != null) 'objectId': objectId,
    'staticParams': staticParams,
    'inputMappings': inputMappings.map((e) => e.toJson()).toList(),
    'status': status.name,
    if (resultData != null) 'resultData': resultData,
    if (error != null) 'error': error,
  };

  factory ChainStep.fromJson(Map<String, dynamic> json) => ChainStep(
    id: json['id'] as String,
    name: json['name'] as String,
    capabilityId: json['capabilityId'] as String?,
    actionId: json['actionId'] as String?,
    objectTypeId: json['objectTypeId'] as String?,
    objectId: json['objectId'] as String?,
    staticParams: (json['staticParams'] as Map<String, dynamic>?) ?? {},
    inputMappings: (json['inputMappings'] as List<dynamic>?)
            ?.map((e) => DataFlowMapping.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    status: ChainStepStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ChainStepStatus.pending,
    ),
    resultData: json['resultData'] as Map<String, dynamic>?,
    error: json['error'] as String?,
  );
}

class ActionChain {
  final String id;
  final String title;
  final String description;
  final List<ChainStep> steps;
  ChainStatus status;
  final DateTime createdAt;
  DateTime? completedAt;
  final String? workspaceId;

  ActionChain({
    required this.id,
    required this.title,
    this.description = '',
    required this.steps,
    this.status = ChainStatus.draft,
    required this.createdAt,
    this.completedAt,
    this.workspaceId,
  });

  double get progress {
    if (steps.isEmpty) return 0;
    final completed = steps.where((s) => s.status == ChainStepStatus.completed).length;
    return completed / steps.length * 100;
  }

  ChainStep? get currentStep => steps.where((s) => s.status == ChainStepStatus.running).firstOrNull;

  List<ChainStep> get pendingSteps => steps.where((s) => s.status == ChainStepStatus.pending).toList();

  List<ChainStep> get completedSteps => steps.where((s) => s.status == ChainStepStatus.completed).toList();

  List<ChainStep> get failedSteps => steps.where((s) => s.status == ChainStepStatus.failed).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'steps': steps.map((e) => e.toJson()).toList(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    if (workspaceId != null) 'workspaceId': workspaceId,
  };

  factory ActionChain.fromJson(Map<String, dynamic> json) => ActionChain(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    steps: (json['steps'] as List<dynamic>)
        .map((e) => ChainStep.fromJson(e as Map<String, dynamic>))
        .toList(),
    status: ChainStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ChainStatus.draft,
    ),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    completedAt: json['completedAt'] != null
        ? DateTime.tryParse(json['completedAt'] as String)
        : null,
    workspaceId: json['workspaceId'] as String?,
  );
}

class ChainExecutionResult {
  final String chainId;
  final ChainStatus status;
  final List<Map<String, dynamic>?> stepResults;
  final int completedSteps;
  final int totalSteps;
  final String? error;

  const ChainExecutionResult({
    required this.chainId,
    required this.status,
    required this.stepResults,
    required this.completedSteps,
    required this.totalSteps,
    this.error,
  });

  bool get isSuccess => status == ChainStatus.completed;
  double get progress => totalSteps > 0 ? completedSteps / totalSteps * 100 : 0;
}

class CrossAppActionEngine {
  final DatabaseService _db;
  bool _isInitialized = false;

  static const _chainsKey = 'action_chains';
  static const _maxChains = 50;

  List<ActionChain> _chains = [];

  CrossAppActionEngine(this._db);

  bool get isInitialized => _isInitialized;
  int get chainCount => _chains.length;
  List<ActionChain> get chains => List.unmodifiable(_chains);

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final json = await _db.getCache(_chainsKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _chains = list
            .map((e) => ActionChain.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _isInitialized = true;
      AppLogger.instance.info('CrossAppActionEngine initialized: ${_chains.length} chains');
    } catch (e, st) {
      AppLogger.instance.error('CrossAppActionEngine init failed', error: e, stackTrace: st);
      _isInitialized = true;
    }
  }

  ActionChain createChain({
    required String title,
    String description = '',
    String? workspaceId,
  }) {
    final chain = ActionChain(
      id: 'chain_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      steps: [],
      createdAt: DateTime.now(),
      workspaceId: workspaceId,
    );
    _chains.add(chain);
    _persist();
    return chain;
  }

  ChainStep addStep(
    ActionChain chain, {
    required String name,
    String? capabilityId,
    String? actionId,
    String? objectTypeId,
    String? objectId,
    Map<String, dynamic> staticParams = const {},
    List<DataFlowMapping> inputMappings = const [],
  }) {
    final step = ChainStep(
      id: 'step_${chain.id}_${chain.steps.length}',
      name: name,
      capabilityId: capabilityId,
      actionId: actionId,
      objectTypeId: objectTypeId,
      objectId: objectId,
      staticParams: staticParams,
      inputMappings: inputMappings,
    );
    chain.steps.add(step);
    _persist();
    return step;
  }

  DataFlowMapping mapOutputToInput({
    required String sourceStepId,
    required String sourceOutputKey,
    required String targetParamKey,
  }) =>
      DataFlowMapping(
        sourceStepId: sourceStepId,
        sourceOutputKey: sourceOutputKey,
        targetParamKey: targetParamKey,
      );

  Future<ChainExecutionResult> executeChain(String chainId) async {
    final chainIndex = _chains.indexWhere((c) => c.id == chainId);
    if (chainIndex < 0) {
      return ChainExecutionResult(
        chainId: chainId,
        status: ChainStatus.failed,
        stepResults: [],
        completedSteps: 0,
        totalSteps: 0,
        error: 'Chain not found: $chainId',
      );
    }

    final chain = _chains[chainIndex];
    chain.status = ChainStatus.running;
    _recordEvent(DomainEventType.chainStarted, chainId, 'chain', {
      'title': chain.title,
      'stepCount': chain.steps.length,
    });
    final stepResults = <Map<String, dynamic>?>[];
    final stepOutputs = <String, Map<String, dynamic>>{};
    int completedCount = 0;

    for (final step in chain.steps) {
      if (step.status == ChainStepStatus.completed) {
        stepResults.add(step.resultData);
        if (step.resultData != null) stepOutputs[step.id] = step.resultData!;
        completedCount++;
        continue;
      }

      step.status = ChainStepStatus.running;
      _persist();

      final resolvedParams = _resolveParams(step, stepOutputs);

      ActionResult result;
      try {
        result = await _executeStep(step, resolvedParams);
      } catch (e) {
        result = ActionResult.failure(
          step.actionId ?? step.capabilityId ?? 'unknown',
          step.objectId ?? 'unknown',
          e.toString(),
        );
      }

      if (result.success) {
        step.status = ChainStepStatus.completed;
        step.resultData = result.data;
        if (result.data != null) stepOutputs[step.id] = result.data!;
        completedCount++;
      } else {
        step.status = ChainStepStatus.failed;
        step.error = result.error;
        chain.status = ChainStatus.failed;
        stepResults.add(result.data ?? {'error': result.error});
        _persist();

        return ChainExecutionResult(
          chainId: chainId,
          status: ChainStatus.failed,
          stepResults: stepResults,
          completedSteps: completedCount,
          totalSteps: chain.steps.length,
          error: 'Step "${step.name}" failed: ${result.error}',
        );
      }

      stepResults.add(result.data);
    }

    chain.status = ChainStatus.completed;
    chain.completedAt = DateTime.now();
    _persist();
    _recordEvent(DomainEventType.chainCompleted, chainId, 'chain', {
      'completedSteps': completedCount,
      'totalSteps': chain.steps.length,
    });

    return ChainExecutionResult(
      chainId: chainId,
      status: ChainStatus.completed,
      stepResults: stepResults,
      completedSteps: completedCount,
      totalSteps: chain.steps.length,
    );
  }

  Future<ActionResult> _executeStep(
    ChainStep step,
    Map<String, dynamic> params,
  ) async {
    if (step.capabilityId != null) {
      try {
        final capExecutor = getIt<CapabilityExecutor>();
        return capExecutor.executeCapability(
          step.capabilityId!,
          objectId: step.objectId,
          objectType: step.objectTypeId,
          params: params,
        );
      } catch (e) {
        AppLogger.instance.warning('CapabilityExecutor not available, falling back to ActionExecutor', error: e);
      }
    }

    if (step.actionId != null) {
      final registry = OmniObjectRegistry.instance;
      OmniObject? target;
      if (step.objectId != null) {
        target = registry.getObject(step.objectId!);
      }
      if (target == null && step.objectTypeId != null) {
        final type = OmniObjectType.values.firstWhere(
          (e) => e.name == step.objectTypeId,
          orElse: () => OmniObjectType.message,
        );
        final objects = registry.getObjectsByType(type);
        if (objects.isNotEmpty) target = objects.first;
      }

      if (target == null) {
        return ActionResult.failure(
          step.actionId!,
          step.objectId ?? 'unknown',
          'No target object found for step: ${step.name}',
        );
      }

      final action = registry
          .getActionsForObject(target)
          .where((a) => a.id == step.actionId)
          .firstOrNull;

      if (action == null) {
        return ActionResult.failure(
          step.actionId!,
          target.id,
          'Action ${step.actionId} not found for object ${target.id}',
        );
      }

      return ActionExecutor.instance.execute(action, target, params);
    }

    return ActionResult.failure('none', 'none', 'Step has neither capabilityId nor actionId: ${step.name}');
  }

  Map<String, dynamic> _resolveParams(
    ChainStep step,
    Map<String, Map<String, dynamic>> stepOutputs,
  ) {
    final params = Map<String, dynamic>.from(step.staticParams);

    for (final mapping in step.inputMappings) {
      final sourceOutput = stepOutputs[mapping.sourceStepId];
      if (sourceOutput != null && sourceOutput.containsKey(mapping.sourceOutputKey)) {
        params[mapping.targetParamKey] = sourceOutput[mapping.sourceOutputKey];
      }
    }

    return params;
  }

  ActionChain? parseChainFromAIOutput(String aiOutput, {String? workspaceId}) {
    final chainRegex = RegExp(r'<<<CHAIN>>>([\s\S]*?)<<<\/CHAIN>>>', multiLine: true);
    final match = chainRegex.firstMatch(aiOutput);
    if (match == null) return null;

    try {
      final jsonStr = match.group(1)!.trim();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final chain = ActionChain(
        id: 'chain_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] as String? ?? 'Untitled Chain',
        description: json['description'] as String? ?? '',
        steps: (json['steps'] as List<dynamic>)
            .map((e) => ChainStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.now(),
        workspaceId: workspaceId,
      );

      _chains.add(chain);
      _persist();
      return chain;
    } catch (e) {
      AppLogger.instance.warning('Failed to parse chain from AI output', error: e);
      return null;
    }
  }

  Future<void> cancelChain(String chainId) async {
    final chain = _chains.where((c) => c.id == chainId).firstOrNull;
    if (chain == null) return;
    chain.status = ChainStatus.cancelled;
    for (final step in chain.steps) {
      if (step.status == ChainStepStatus.pending || step.status == ChainStepStatus.running) {
        step.status = ChainStepStatus.skipped;
      }
    }
    await _persist();
  }

  String buildChainContext({String? workspaceId}) {
    final buffer = StringBuffer();
    buffer.writeln('[Cross-App Actions]');

    final activeChains = _chains.where((c) =>
        c.status == ChainStatus.running || c.status == ChainStatus.draft);
    final recentChains = _chains
        .where((c) => c.status == ChainStatus.completed || c.status == ChainStatus.failed)
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));

    if (activeChains.isNotEmpty) {
      buffer.writeln('\nActive Chains:');
      for (final chain in activeChains) {
        buffer.writeln('  ${chain.title} [${chain.status.name}] ${chain.progress.toStringAsFixed(0)}%');
        for (final step in chain.steps) {
          final icon = step.status == ChainStepStatus.completed ? '✓'
              : step.status == ChainStepStatus.running ? '→'
              : step.status == ChainStepStatus.failed ? '✗'
              : '○';
          buffer.writeln('    $icon ${step.name}');
        }
      }
    }

    if (recentChains.isNotEmpty) {
      buffer.writeln('\nRecent Chains:');
      for (final chain in recentChains.take(3)) {
        final icon = chain.status == ChainStatus.completed ? '✓' : '✗';
        buffer.writeln('  $icon ${chain.title} (${chain.steps.where((s) => s.status == ChainStepStatus.completed).length}/${chain.steps.length})');
      }
    }

    buffer.writeln('\nUsage: Use <<<CHAIN>>>...<<<\/CHAIN>>> to define cross-app action chains.');
    buffer.writeln('Each step can reference a capabilityId or actionId, and map outputs from previous steps.');

    return buffer.toString();
  }

  Future<void> _persist() async {
    try {
      if (_chains.length > _maxChains) {
        _chains = _chains.sublist(_chains.length - _maxChains);
      }
      await _db.putCache(
        _chainsKey,
        jsonEncode(_chains.map((e) => e.toJson()).toList()),
      );
    } catch (e, st) {
      AppLogger.instance.error('CrossAppActionEngine persist failed', error: e, stackTrace: st);
    }
  }

  Future<void> clear() async {
    _chains.clear();
    await _persist();
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
