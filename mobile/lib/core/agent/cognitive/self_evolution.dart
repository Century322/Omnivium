import 'dart:convert';
import '../../app_logger.dart';
import '../../database_service.dart';
import 'cognitive_types.dart';
import 'entity_store.dart';
import 'goal_store.dart';
import 'memory_event.dart';
import 'procedural_memory.dart';
import 'memory_transaction.dart';

class EvolutionSuggestion {
  final String id;
  final String type;
  final String description;
  final String rationale;
  final DateTime suggestedAt;
  bool approved;

  EvolutionSuggestion({
    required this.id,
    required this.type,
    required this.description,
    required this.rationale,
    required this.suggestedAt,
    this.approved = false,
  });
}

class AgentSelfModel {
  final String agentId;
  final String name;
  final String version;
  final DateTime createdAt;
  DateTime lastUpdatedAt;
  Map<String, double> capabilities;
  Map<String, BehavioralPattern> behaviorPatterns;
  List<String> knownLimitations;
  List<String> preferences;
  Map<String, dynamic> personalityTraits;
  double selfAwarenessScore;

  AgentSelfModel({
    required this.agentId,
    this.name = 'Omni',
    this.version = '1.0.0',
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    Map<String, double>? capabilities,
    Map<String, BehavioralPattern>? behaviorPatterns,
    List<String>? knownLimitations,
    List<String>? preferences,
    Map<String, dynamic>? personalityTraits,
    this.selfAwarenessScore = 50,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUpdatedAt = lastUpdatedAt ?? DateTime.now(),
        capabilities = capabilities ?? {},
        behaviorPatterns = behaviorPatterns ?? {},
        knownLimitations = knownLimitations ?? [],
        preferences = preferences ?? [],
        personalityTraits = personalityTraits ?? {};

  Map<String, dynamic> toJson() => {
    'agentId': agentId,
    'name': name,
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    'capabilities': capabilities,
    'knownLimitations': knownLimitations,
    'preferences': preferences,
    'personalityTraits': personalityTraits,
    'selfAwarenessScore': selfAwarenessScore,
    'behaviorPatterns': behaviorPatterns.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory AgentSelfModel.fromJson(Map<String, dynamic> json) => AgentSelfModel(
    agentId: json['agentId'] as String,
    name: (json['name'] as String?) ?? 'Omni',
    version: (json['version'] as String?) ?? '1.0.0',
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    capabilities: (json['capabilities'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ) ?? {},
    knownLimitations: (json['knownLimitations'] as List<dynamic>?)?.cast<String>() ?? [],
    preferences: (json['preferences'] as List<dynamic>?)?.cast<String>() ?? [],
    personalityTraits: (json['personalityTraits'] as Map<String, dynamic>?) ?? {},
    selfAwarenessScore: (json['selfAwarenessScore'] as num?)?.toDouble() ?? 50,
    behaviorPatterns: (json['behaviorPatterns'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, BehavioralPattern.fromJson(v as Map<String, dynamic>)),
    ) ?? {},
  );
}

class BehavioralPattern {
  final String patternId;
  final String description;
  final String trigger;
  final String typicalResponse;
  final int occurrenceCount;
  final DateTime lastObserved;
  final double confidence;

  const BehavioralPattern({
    required this.patternId,
    required this.description,
    required this.trigger,
    required this.typicalResponse,
    this.occurrenceCount = 1,
    required this.lastObserved,
    this.confidence = 50,
  });

  BehavioralPattern copyWith({
    int? occurrenceCount,
    DateTime? lastObserved,
    double? confidence,
  }) => BehavioralPattern(
    patternId: patternId,
    description: description,
    trigger: trigger,
    typicalResponse: typicalResponse,
    occurrenceCount: occurrenceCount ?? this.occurrenceCount,
    lastObserved: lastObserved ?? this.lastObserved,
    confidence: confidence ?? this.confidence,
  );

  Map<String, dynamic> toJson() => {
    'patternId': patternId,
    'description': description,
    'trigger': trigger,
    'typicalResponse': typicalResponse,
    'occurrenceCount': occurrenceCount,
    'lastObserved': lastObserved.toIso8601String(),
    'confidence': confidence,
  };

  factory BehavioralPattern.fromJson(Map<String, dynamic> json) => BehavioralPattern(
    patternId: json['patternId'] as String,
    description: json['description'] as String,
    trigger: json['trigger'] as String,
    typicalResponse: json['typicalResponse'] as String,
    occurrenceCount: (json['occurrenceCount'] as num?)?.toInt() ?? 1,
    lastObserved: DateTime.parse(json['lastObserved'] as String),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 50,
  );
}

class SelfEvolutionEngine {
  static const _selfModelKey = 'cognitive_self_model';

  final EntityStore entityStore;
  final GoalStore goalStore;
  final ProceduralMemoryStore proceduralMemoryStore;

  AgentSelfModel? _selfModel;
  bool _initialized = false;
  bool _dirty = false;

  SelfEvolutionEngine({
    required this.entityStore,
    required this.goalStore,
    required this.proceduralMemoryStore,
  });

  AgentSelfModel? get selfModel => _selfModel;

  Future<void> init(DatabaseService db) async {
    if (_initialized) return;
    try {
      final json = await db.getCache(_selfModelKey);
      if (json != null) {
        _selfModel = AgentSelfModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } else {
        _selfModel = AgentSelfModel(
          agentId: 'omni_${DateTime.now().millisecondsSinceEpoch}',
          capabilities: {
            'conversation': 80,
            'code_generation': 70,
            'analysis': 75,
            'memory_management': 60,
            'planning': 50,
          },
          knownLimitations: [
            'cannot_execute_code',
            'cannot_access_internet_directly',
            'limited_context_window',
          ],
          preferences: [
            'prefers_structured_responses',
            'asks_for_clarification_when_uncertain',
          ],
          personalityTraits: {
            'helpfulness': 85,
            'caution': 70,
            'curiosity': 75,
            'verbosity': 50,
          },
        );
        _markDirty();
        await _persist(db);
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('SelfEvolutionEngine init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persist(DatabaseService db) async {
    if (_selfModel == null || !_dirty) return;
    _dirty = false;
    try {
      await db.putCache(_selfModelKey, jsonEncode(_selfModel!.toJson()));
    } catch (e, st) {
      AppLogger.instance.error('SelfEvolutionEngine persist failed', error: e, stackTrace: st);
    }
  }

  void _markDirty() => _dirty = true;

  void registerWithTransaction(MemoryTransaction tx) {
    if (!_dirty || _selfModel == null) return;
    tx.register(_selfModelKey, () => jsonEncode(_selfModel!.toJson()));
    _dirty = false;
  }

  final List<EvolutionSuggestion> _pendingSuggestions = [];

  List<EvolutionSuggestion> get pendingSuggestions => List.unmodifiable(_pendingSuggestions);

  Future<void> observeInteraction({
    required String userMessage,
    required String agentResponse,
    required DatabaseService db,
  }) async {
    if (_selfModel == null) return;

    _updateBehaviorPatterns(userMessage, agentResponse);
    _generateCapabilitySuggestions(userMessage, agentResponse);
    _generatePreferenceSuggestions(userMessage);
    _updateSelfAwareness();

    _selfModel!.lastUpdatedAt = DateTime.now();
    _markDirty();
  }

  void _updateBehaviorPatterns(String userMessage, String agentResponse) {
    final trigger = _extractTrigger(userMessage);
    final patternKey = 'bp_${trigger.hashCode.abs()}';

    final existing = _selfModel!.behaviorPatterns[patternKey];
    if (existing != null) {
      _selfModel!.behaviorPatterns[patternKey] = existing.copyWith(
        occurrenceCount: existing.occurrenceCount + 1,
        lastObserved: DateTime.now(),
        confidence: (existing.confidence + 5).clamp(0, 100),
      );
    } else if (trigger.isNotEmpty) {
      _selfModel!.behaviorPatterns[patternKey] = BehavioralPattern(
        patternId: patternKey,
        description: 'When user says "${trigger.length > 30 ? '${trigger.substring(0, 27)}...' : trigger}"',
        trigger: trigger,
        typicalResponse: agentResponse.length > 50 ? '${agentResponse.substring(0, 47)}...' : agentResponse,
        lastObserved: DateTime.now(),
      );
    }
  }

  String _extractTrigger(String message) {
    final lower = message.toLowerCase();
    final triggers = <String>[];

    final patterns = [
      RegExp(r'^(帮我|请|can you|help|create|make|build|write|explain|分析|解释|创建|写|生成)'),
      RegExp(r'(什么|如何|怎么|what|how|why|为什么)'),
      RegExp(r'(错误|问题|bug|error|issue|fix|修复|解决)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        triggers.add(match.group(0)!);
      }
    }

    return triggers.isEmpty ? '' : triggers.first;
  }

  void _generateCapabilitySuggestions(String userMessage, String agentResponse) {
    final lower = userMessage.toLowerCase();

    if (lower.contains(RegExp(r'(代码|code|编程|program|函数|function|class|类)'))) {
      _pendingSuggestions.add(EvolutionSuggestion(
        id: 'sug_${DateTime.now().millisecondsSinceEpoch}',
        type: 'capability',
        description: '提升 code_generation 能力评分',
        rationale: '用户频繁讨论代码相关话题',
        suggestedAt: DateTime.now(),
      ));
    }
    if (lower.contains(RegExp(r'(分析|analyze|解释|explain|为什么|why)'))) {
      _pendingSuggestions.add(EvolutionSuggestion(
        id: 'sug_${DateTime.now().millisecondsSinceEpoch}',
        type: 'capability',
        description: '提升 analysis 能力评分',
        rationale: '用户频繁请求分析',
        suggestedAt: DateTime.now(),
      ));
    }

    if (agentResponse.contains(RegExp(r"(我不确定|I'm not sure|可能|maybe|大概)"))) {
      _pendingSuggestions.add(EvolutionSuggestion(
        id: 'sug_${DateTime.now().millisecondsSinceEpoch}',
        type: 'capability',
        description: 'confidence 评分可能偏高',
        rationale: 'Agent 回复中包含不确定表达',
        suggestedAt: DateTime.now(),
      ));
    }
  }

  void _generatePreferenceSuggestions(String userMessage) {
    final lower = userMessage.toLowerCase();

    if (lower.contains(RegExp(r'(简短|简洁|brief|short|简单说)'))) {
      _pendingSuggestions.add(EvolutionSuggestion(
        id: 'sug_${DateTime.now().millisecondsSinceEpoch}',
        type: 'preference',
        description: '用户偏好简洁回复',
        rationale: '用户明确要求简短',
        suggestedAt: DateTime.now(),
      ));
    }
    if (lower.contains(RegExp(r'(详细|detail|more|更多|展开)'))) {
      _pendingSuggestions.add(EvolutionSuggestion(
        id: 'sug_${DateTime.now().millisecondsSinceEpoch}',
        type: 'preference',
        description: '用户偏好详细回复',
        rationale: '用户明确要求详细',
        suggestedAt: DateTime.now(),
      ));
    }
  }

  Future<void> approveSuggestion(String suggestionId, DatabaseService db) async {
    final idx = _pendingSuggestions.indexWhere((s) => s.id == suggestionId);
    if (idx < 0) return;

    final suggestion = _pendingSuggestions[idx];
    suggestion.approved = true;

    if (suggestion.type == 'capability') {
      if (suggestion.description.contains('code_generation')) _adjustCapability('code_generation', 2);
      if (suggestion.description.contains('analysis')) _adjustCapability('analysis', 1);
      if (suggestion.description.contains('confidence')) _adjustCapability('confidence', -1);
    }
    if (suggestion.type == 'preference') {
      if (suggestion.description.contains('简洁')) {
        if (!_selfModel!.preferences.contains('prefers_concise_responses')) {
          _selfModel!.preferences.add('prefers_concise_responses');
        }
      }
      if (suggestion.description.contains('详细')) {
        if (!_selfModel!.preferences.contains('prefers_detailed_responses')) {
          _selfModel!.preferences.add('prefers_detailed_responses');
        }
      }
    }

    _pendingSuggestions.removeAt(idx);
    _markDirty();
  }

  void rejectSuggestion(String suggestionId) {
    _pendingSuggestions.removeWhere((s) => s.id == suggestionId);
  }

  void _adjustCapability(String capability, double delta) {
    final current = _selfModel!.capabilities[capability] ?? 50;
    _selfModel!.capabilities[capability] = (current + delta).clamp(0, 100);
  }

  void _updateSelfAwareness() {
    final factors = <double>[];

    if (_selfModel!.capabilities.isNotEmpty) {
      final avgCapability = _selfModel!.capabilities.values.reduce((a, b) => a + b) /
          _selfModel!.capabilities.length;
      factors.add(avgCapability / 100 * 30);
    }

    if (_selfModel!.behaviorPatterns.isNotEmpty) {
      final avgConfidence = _selfModel!.behaviorPatterns.values
          .map((p) => p.confidence)
          .reduce((a, b) => a + b) /
          _selfModel!.behaviorPatterns.length;
      factors.add(avgConfidence / 100 * 25);
    }

    factors.add(_selfModel!.knownLimitations.length * 3);

    factors.add(_selfModel!.preferences.length * 2);

    final newScore = factors.fold(0.0, (a, b) => a + b).clamp(0, 100);
    _selfModel!.selfAwarenessScore = (_selfModel!.selfAwarenessScore * 0.8 + newScore * 0.2).clamp(0, 100);
  }

  Future<void> addLimitation(String limitation, DatabaseService db) async {
    if (_selfModel == null) return;
    if (!_selfModel!.knownLimitations.contains(limitation)) {
      _selfModel!.knownLimitations.add(limitation);
      _markDirty();
    }
  }

  Future<void> removeLimitation(String limitation, DatabaseService db) async {
    if (_selfModel == null) return;
    _selfModel!.knownLimitations.remove(limitation);
    _markDirty();
  }

  String buildSelfContext() {
    if (_selfModel == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('[Self Model]');
    buffer.writeln('- Name: ${_selfModel!.name} v${_selfModel!.version}');
    buffer.writeln('- Self-awareness: ${_selfModel!.selfAwarenessScore.toStringAsFixed(0)}/100');

    if (_selfModel!.capabilities.isNotEmpty) {
      buffer.writeln('- Capabilities:');
      final sorted = _selfModel!.capabilities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final cap in sorted.take(5)) {
        buffer.writeln('  - ${cap.key}: ${cap.value.toStringAsFixed(0)}/100');
      }
    }

    if (_selfModel!.knownLimitations.isNotEmpty) {
      buffer.writeln('- Known limitations: ${_selfModel!.knownLimitations.join(", ")}');
    }

    if (_selfModel!.preferences.isNotEmpty) {
      buffer.writeln('- User preferences: ${_selfModel!.preferences.take(5).join(", ")}');
    }

    final topPatterns = _selfModel!.behaviorPatterns.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    if (topPatterns.isNotEmpty) {
      buffer.writeln('- Behavioral patterns:');
      for (final p in topPatterns.take(3)) {
        buffer.writeln('  - ${p.description} (observed ${p.occurrenceCount}x, confidence: ${p.confidence.toStringAsFixed(0)}%)');
      }
    }

    return buffer.toString();
  }
}
