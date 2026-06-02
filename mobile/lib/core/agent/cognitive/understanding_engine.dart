import 'dart:convert';
import '../../app_logger.dart';
import '../../providers/ai_provider.dart';
import 'cognitive_types.dart';

class ExtractedEntity {
  final String name;
  final EntityType type;
  final List<String> aliases;
  final Map<String, dynamic> properties;

  const ExtractedEntity({
    required this.name,
    required this.type,
    this.aliases = const [],
    this.properties = const {},
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'aliases': aliases,
    'properties': properties,
  };

  factory ExtractedEntity.fromJson(Map<String, dynamic> json) => ExtractedEntity(
    name: json['name'] as String,
    type: EntityType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => EntityType.concept,
    ),
    aliases: (json['aliases'] as List<dynamic>?)?.cast<String>() ?? [],
    properties: (json['properties'] as Map<String, dynamic>?) ?? {},
  );
}

class ExtractedRelation {
  final String fromEntity;
  final String toEntity;
  final RelationType type;
  final Map<String, dynamic> metadata;

  const ExtractedRelation({
    required this.fromEntity,
    required this.toEntity,
    required this.type,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'from': fromEntity,
    'to': toEntity,
    'type': type.name,
    'metadata': metadata,
  };

  factory ExtractedRelation.fromJson(Map<String, dynamic> json) => ExtractedRelation(
    fromEntity: json['from'] as String,
    toEntity: json['to'] as String,
    type: RelationType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => RelationType.supports,
    ),
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );
}

class ExtractedEvent {
  final String type;
  final Map<String, dynamic> properties;

  const ExtractedEvent({
    required this.type,
    this.properties = const {},
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'properties': properties,
  };

  factory ExtractedEvent.fromJson(Map<String, dynamic> json) => ExtractedEvent(
    type: json['type'] as String,
    properties: (json['properties'] as Map<String, dynamic>?) ?? {},
  );
}

class UnderstandingResult {
  final IntentType intent;
  final EmotionType emotion;
  final int importance;
  final MemoryPersistence persistence;
  final double confidence;
  final MemoryType memoryType;
  final MemoryDomain domain;
  final String eventType;
  final String summary;
  final String? entityName;
  final EntityType? entityType;
  final RelationType? relationType;
  final String? relatedEntityName;
  final String? reason;
  final List<ExtractedEntity> entities;
  final List<ExtractedRelation> relations;
  final List<ExtractedEvent> events;
  final bool fromAI;
  final String? workspaceId;
  final String? topic;

  const UnderstandingResult({
    this.intent = IntentType.fact,
    this.emotion = EmotionType.neutral,
    this.importance = 50,
    this.persistence = MemoryPersistence.shortTerm,
    this.confidence = 80,
    this.memoryType = MemoryType.fact,
    this.domain = MemoryDomain.project,
    this.eventType = 'statement',
    this.summary = '',
    this.entityName,
    this.entityType,
    this.relationType,
    this.relatedEntityName,
    this.reason,
    this.entities = const [],
    this.relations = const [],
    this.events = const [],
    this.fromAI = false,
    this.workspaceId,
    this.topic,
  });

  UnderstandingResult withLegacyFields() {
    if (entityName != null || entities.isEmpty) return this;
    final primary = entities.first;
    ExtractedRelation? primaryRelation;
    if (relations.isNotEmpty) primaryRelation = relations.first;
    return UnderstandingResult(
      intent: intent,
      emotion: emotion,
      importance: importance,
      persistence: persistence,
      confidence: confidence,
      memoryType: memoryType,
      domain: domain,
      eventType: eventType,
      summary: summary,
      entityName: primary.name,
      entityType: primary.type,
      relationType: primaryRelation?.type,
      relatedEntityName: primaryRelation != null
          ? (primaryRelation.fromEntity == primary.name
              ? primaryRelation.toEntity
              : primaryRelation.fromEntity)
          : null,
      reason: reason,
      entities: entities,
      relations: relations,
      events: events,
      fromAI: fromAI,
      workspaceId: workspaceId,
      topic: topic,
    );
  }

  Map<String, dynamic> toJson() => {
    'intent': intent.name,
    'emotion': emotion.name,
    'importance': importance,
    'persistence': persistence.name,
    'confidence': confidence,
    'memoryType': memoryType.name,
    'domain': domain.name,
    'eventType': eventType,
    'summary': summary,
    if (entityName != null) 'entityName': entityName,
    if (entityType != null) 'entityType': entityType!.name,
    if (relationType != null) 'relationType': relationType!.name,
    if (relatedEntityName != null) 'relatedEntityName': relatedEntityName,
    if (reason != null) 'reason': reason,
    'entities': entities.map((e) => e.toJson()).toList(),
    'relations': relations.map((r) => r.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
    'fromAI': fromAI,
    if (workspaceId != null) 'workspaceId': workspaceId,
    if (topic != null) 'topic': topic,
  };
}

class UnderstandingEngine {
  static const _projectKeywords = ['项目', 'project', '开发', 'develop', '平台', 'platform', '产品', 'product', 'app', '应用'];
  static const _techKeywords = ['flutter', 'matrix', 'mcp', 'dart', 'rust', 'react', 'vue', 'python', 'kotlin', 'swift', 'java', 'go', 'typescript', 'javascript', 'c++', 'ruby', 'swiftui', 'compose'];
  static const _goalKeywords = ['目标', 'goal', '计划', 'plan', '要做', '要开发', '准备', '打算', 'want to', 'going to', 'plan to'];
  static const _decisionKeywords = ['决定', 'decide', '选择', 'choose', '采用', '选用', '用...开发', 'decided to', 'chose'];
  static const _preferenceKeywords = ['喜欢', 'like', '偏好', 'prefer', '不喜欢', 'dislike', '讨厌', 'hate', '最爱', 'favorite'];
  static const _jokeKeywords = ['哈哈', 'lol', '搞笑', 'funny', '开玩笑', 'just kidding', '逗', '笑死'];
  static const _complaintKeywords = ['烦', 'annoying', '太慢', 'too slow', '崩溃', 'crash', 'bug', '难用', '不好用'];
  static const _promiseKeywords = ['答应', 'promise', '承诺', '保证', '一定', 'will definitely'];
  static const _ruleKeywords = ['不要', "don't", '禁止', 'forbidden', '规则', 'rule', '必须', 'must', '每次', 'always', '从不', 'never'];
  static const _ephemeralKeywords = ['天气', 'weather', '午饭', 'lunch', '晚饭', 'dinner', '早餐', 'breakfast', '今天', 'today'];
  static const _emotionKeywords = ['开心', 'happy', '难过', 'sad', '生气', 'angry', '焦虑', 'anxious', '兴奋', 'excited', '沮丧', 'frustrated', '害怕', 'fear', 'scared', '惊讶', 'surprise', '讨厌', 'disgust', '信任', 'trust', '期待', 'anticipation'];
  static const _frustrationKeywords = ['烦', '崩溃', '受不了', '太慢', '太难', '搞不定', '放弃', '不干了', 'annoying', 'frustrated', 'giving up', 'can\'t take it'];
  static const _joyKeywords = ['太好了', '棒', '厉害', '完美', 'awesome', 'great', 'amazing', 'perfect', 'love it', '太棒了'];
  static const _sadnessKeywords = ['难过', '伤心', '失望', '遗憾', 'sad', 'disappointed', 'unfortunate', '可惜'];
  static const _angerKeywords = ['生气', '愤怒', '火大', '烦死', 'angry', 'furious', 'pissed', 'mad'];
  static const _fearKeywords = ['害怕', '担心', '恐惧', '忧虑', 'afraid', 'worried', 'scared', 'anxious'];
  static const _surpriseKeywords = ['没想到', '出乎意料', '居然', '竟然', 'unexpected', 'surprising', 'wow', '不可思议'];
  static const _identityKeywords = ['我叫', '我的名字', '我是', 'my name is', "i'm", 'i am', '私の名前は', '제 이름은', '名字是', '叫什么'];

  ChatService? _chatService;
  bool _useAI = false;

  void setChatService(ChatService service) {
    _chatService = service;
    _useAI = true;
  }

  UnderstandingResult analyze(String message, {String? speakerId}) {
    final lower = message.toLowerCase();
    final intent = _classifyIntent(lower, message);
    final emotion = _classifyEmotion(lower, message);
    final importance = _scoreImportance(lower, message, intent);
    final persistence = _scorePersistence(lower, intent, importance);
    final memoryType = _classifyMemoryType(lower, intent);
    final domain = _classifyDomain(lower);
    final eventType = _extractEventType(intent, memoryType);
    final summary = _generateSummary(message, intent, memoryType);
    final entityInfo = _extractEntity(message, lower);
    final confidence = _scoreConfidence(intent, importance);

    final entities = _extractEntities(message, lower, intent);
    final relations = _extractRelations(message, lower, entities, intent);
    final events = _extractEvents(intent, memoryType, entities, relations);

    return UnderstandingResult(
      intent: intent,
      emotion: emotion,
      importance: importance,
      persistence: persistence,
      confidence: confidence,
      memoryType: memoryType,
      domain: domain,
      eventType: eventType,
      summary: summary,
      entityName: entityInfo.$1,
      entityType: entityInfo.$2,
      relationType: entityInfo.$3,
      relatedEntityName: entityInfo.$4,
      reason: importance >= 60 ? _generateReason(intent, memoryType) : null,
      entities: entities,
      relations: relations,
      events: events,
      fromAI: false,
    );
  }

  Future<UnderstandingResult> analyzeWithAI(String message, {String? speakerId}) async {
    if (!_useAI || _chatService == null) {
      return analyze(message, speakerId: speakerId);
    }

    try {
      final aiResult = await _callAIForAnalysis(message);
      if (aiResult != null) return aiResult;
    } catch (e) {
      AppLogger.instance.warning('AI analysis failed, falling back to keyword', error: e);
    }

    return analyze(message, speakerId: speakerId);
  }

  Future<UnderstandingResult?> _callAIForAnalysis(String message) async {
    if (_chatService == null) return null;

    final prompt = '''Analyze this message and return a JSON object with this exact structure:
{
  "intent": "one of: fact, question, command, opinion, goal, decision, promise, joke, sarcasm, complaint, emotion, guess",
  "emotion": "one of: neutral, joy, sadness, anger, fear, surprise, disgust, trust, anticipation, frustration",
  "importance": 0-100,
  "persistence": "one of: permanent, longTerm, shortTerm, ephemeral",
  "memoryType": "one of: fact, goal, decision, preference, rule, relationship, experience, procedure",
  "domain": "one of: project, personal, friend, business, research, entertainment",
  "summary": "concise summary max 100 chars",
  "confidence": 0-100,
  "entities": [
    {"name": "canonical name", "type": "one of: person, project, tech, concept, organization, document, task, goal", "aliases": ["alternative name 1", "alternative name 2"], "properties": {}}
  ],
  "relations": [
    {"from": "entity name", "to": "entity name", "type": "one of: owns, uses, dependsOn, partOf, knows, prefers, blocks, supports, created, decided", "metadata": {}}
  ],
  "events": [
    {"type": "event_type like tech_selected, preference_set, decision_made, identity_stated, goal_set", "properties": {}}
  ]
}

Critical rules:
- Identity information (name, self-description) MUST have importance >= 90 and persistence "permanent"
- Extract ALL entities mentioned, not just one
- Extract ALL relations between entities
- Use CANONICAL names for entities. If user says "谷歌那个跨平台框架", use canonical name "Flutter" with alias "谷歌那个跨平台框架"
- If user says "那个Dart框架", use canonical name "Flutter" with alias "那个Dart框架"
- "我叫张三" → entities: [{name:"张三", type:"person", aliases:[]}], relations: [{from:"user", to:"张三", type:"knows"}], events: [{type:"identity_stated"}]
- "我决定Omni用Flutter" → entities: [{name:"Omni", type:"project", aliases:[]}, {name:"Flutter", type:"tech", aliases:["谷歌那个跨平台框架","那个Dart框架"]}], relations: [{from:"Omni", to:"Flutter", type:"uses"}], events: [{type:"tech_selected"}]
- "我喜欢深色模式" → entities: [{name:"深色模式", type:"concept", aliases:["dark mode"]}], relations: [{from:"user", to:"深色模式", type:"prefers"}], events: [{type:"preference_set"}]
- Emotion detection: "我准备放弃" → frustration, "太好了" → joy, "烦死了" → anger, "担心" → fear, "没想到" → surprise
- If user expresses frustration about a project, set emotion to "frustration" and importance >= 80

Message: "$message"

Return ONLY the JSON object, no other text.''';;

    final messages = [
      ChatMessage(role: 'system', content: 'You are a cognitive understanding engine. Analyze messages into structured entities, relations, and events. Return only valid JSON.'),
      ChatMessage(role: 'user', content: prompt),
    ];

    final stream = await _chatService!.agentChat(
      messages,
      model: null,
      skills: [],
    );

    final buffer = StringBuffer();
    await for (final event in stream.events) {
      if (event.type == 'content' || event.type == 'text') {
        final data = event.data;
        if (data is String) {
          buffer.write(data);
        } else if (data is Map<String, dynamic>) {
          buffer.write(data['content'] ?? data['text'] ?? '');
        }
      }
    }

    final raw = buffer.toString().trim();
    final jsonStr = _extractJson(raw);
    if (jsonStr == null) return null;

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;

    final entities = (json['entities'] as List<dynamic>?)
        ?.map((e) => ExtractedEntity.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    final relations = (json['relations'] as List<dynamic>?)
        ?.map((e) => ExtractedRelation.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    final events = (json['events'] as List<dynamic>?)
        ?.map((e) => ExtractedEvent.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    String? primaryEntityName;
    EntityType? primaryEntityType;
    RelationType? primaryRelationType;
    String? primaryRelatedEntityName;

    if (entities.isNotEmpty) {
      primaryEntityName = entities.first.name;
      primaryEntityType = entities.first.type;
    }
    if (relations.isNotEmpty) {
      primaryRelationType = relations.first.type;
      primaryRelatedEntityName = relations.first.fromEntity == primaryEntityName
          ? relations.first.toEntity
          : relations.first.fromEntity;
    }

    return UnderstandingResult(
      intent: _parseIntent(json['intent'] as String?),
      emotion: _parseEmotion(json['emotion'] as String?),
      importance: (json['importance'] as num?)?.toInt() ?? 50,
      persistence: _parsePersistence(json['persistence'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 80,
      memoryType: _parseMemoryType(json['memoryType'] as String?),
      domain: _parseDomain(json['domain'] as String?),
      eventType: json['eventType'] as String? ?? (events.isNotEmpty ? events.first.type : 'statement'),
      summary: json['summary'] as String? ?? message,
      entityName: primaryEntityName ?? json['entityName'] as String?,
      entityType: primaryEntityType ?? _parseEntityType(json['entityType'] as String?),
      relationType: primaryRelationType ?? _parseRelationType(json['relationType'] as String?),
      relatedEntityName: primaryRelatedEntityName ?? json['relatedEntityName'] as String?,
      reason: json['reason'] as String?,
      entities: entities,
      relations: relations,
      events: events,
      fromAI: true,
    );
  }

  String? _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return raw.substring(start, end + 1);
    }
    return null;
  }

  IntentType _parseIntent(String? value) {
    if (value == null) return IntentType.fact;
    return IntentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => IntentType.fact,
    );
  }

  MemoryPersistence _parsePersistence(String? value) {
    if (value == null) return MemoryPersistence.shortTerm;
    return MemoryPersistence.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MemoryPersistence.shortTerm,
    );
  }

  MemoryType _parseMemoryType(String? value) {
    if (value == null) return MemoryType.fact;
    return MemoryType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MemoryType.fact,
    );
  }

  MemoryDomain _parseDomain(String? value) {
    if (value == null) return MemoryDomain.personal;
    return MemoryDomain.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MemoryDomain.personal,
    );
  }

  EntityType? _parseEntityType(String? value) {
    if (value == null) return null;
    return EntityType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EntityType.concept,
    );
  }

  RelationType? _parseRelationType(String? value) {
    if (value == null) return null;
    for (final e in RelationType.values) {
      if (e.name.toLowerCase() == value.toLowerCase()) return e;
    }
    return null;
  }

  IntentType _classifyIntent(String lower, String original) {
    if (_containsAny(lower, _jokeKeywords)) return IntentType.joke;
    if (_containsAny(lower, _complaintKeywords)) return IntentType.complaint;
    if (_containsAny(lower, _emotionKeywords)) return IntentType.emotion;
    if (_containsAny(lower, _promiseKeywords)) return IntentType.promise;
    if (_containsAny(lower, _ruleKeywords)) return IntentType.command;
    if (_containsAny(lower, _decisionKeywords)) return IntentType.decision;
    if (_containsAny(lower, _goalKeywords)) return IntentType.goal;
    if (_containsAny(lower, _preferenceKeywords)) return IntentType.opinion;
    if (_containsAny(lower, _identityKeywords)) return IntentType.fact;
    if (original.contains('?') || original.contains('？')) return IntentType.question;
    if (_containsAny(lower, ['可能', 'maybe', '也许', 'perhaps', '猜测'])) return IntentType.guess;
    return IntentType.fact;
  }

  EmotionType _classifyEmotion(String lower, String original) {
    if (_containsAny(lower, _frustrationKeywords)) return EmotionType.frustration;
    if (_containsAny(lower, _joyKeywords)) return EmotionType.joy;
    if (_containsAny(lower, _angerKeywords)) return EmotionType.anger;
    if (_containsAny(lower, _sadnessKeywords)) return EmotionType.sadness;
    if (_containsAny(lower, _fearKeywords)) return EmotionType.fear;
    if (_containsAny(lower, _surpriseKeywords)) return EmotionType.surprise;
    if (_containsAny(lower, _emotionKeywords)) {
      if (_containsAny(lower, ['开心', 'happy', '兴奋', 'excited'])) return EmotionType.joy;
      if (_containsAny(lower, ['难过', 'sad', '沮丧', 'frustrated'])) return EmotionType.sadness;
      if (_containsAny(lower, ['生气', 'angry', '焦虑', 'anxious'])) return EmotionType.anger;
      if (_containsAny(lower, ['害怕', 'fear', 'scared'])) return EmotionType.fear;
      return EmotionType.neutral;
    }
    return EmotionType.neutral;
  }

  EmotionType _parseEmotion(String? value) {
    if (value == null) return EmotionType.neutral;
    return EmotionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EmotionType.neutral,
    );
  }

  int _scoreImportance(String lower, String original, IntentType intent) {
    if (_containsAny(lower, _identityKeywords)) return 95;
    var score = 30;
    if (_containsAny(lower, _projectKeywords)) score += 30;
    if (_containsAny(lower, _techKeywords)) score += 25;
    if (_containsAny(lower, _goalKeywords)) score += 30;
    if (_containsAny(lower, _decisionKeywords)) score += 35;
    if (_containsAny(lower, _preferenceKeywords)) score += 20;
    if (_containsAny(lower, _ruleKeywords)) score += 25;
    if (_containsAny(lower, _promiseKeywords)) score += 30;
    if (_containsAny(lower, _ephemeralKeywords)) score -= 20;
    if (intent == IntentType.joke) score -= 25;
    if (intent == IntentType.complaint) score -= 10;
    if (intent == IntentType.emotion) score -= 5;
    if (intent == IntentType.decision) score += 10;
    if (intent == IntentType.goal) score += 15;
    if (intent == IntentType.promise) score += 15;
    return score.clamp(0, 100);
  }

  MemoryPersistence _scorePersistence(String lower, IntentType intent, int importance) {
    if (_containsAny(lower, _identityKeywords)) return MemoryPersistence.permanent;
    if (_containsAny(lower, ['名字', 'name', '叫什么'])) return MemoryPersistence.permanent;
    if (intent == IntentType.decision) return MemoryPersistence.longTerm;
    if (intent == IntentType.goal) return MemoryPersistence.longTerm;
    if (intent == IntentType.promise) return MemoryPersistence.longTerm;
    if (_containsAny(lower, _ruleKeywords)) return MemoryPersistence.longTerm;
    if (_containsAny(lower, _preferenceKeywords)) return MemoryPersistence.longTerm;
    if (importance >= 80) return MemoryPersistence.longTerm;
    if (importance >= 60) return MemoryPersistence.shortTerm;
    if (_containsAny(lower, _ephemeralKeywords)) return MemoryPersistence.ephemeral;
    return MemoryPersistence.shortTerm;
  }

  MemoryType _classifyMemoryType(String lower, IntentType intent) {
    switch (intent) {
      case IntentType.decision: return MemoryType.decision;
      case IntentType.goal: return MemoryType.goal;
      case IntentType.opinion: return MemoryType.preference;
      case IntentType.command: return MemoryType.rule;
      case IntentType.promise: return MemoryType.rule;
      case IntentType.complaint: return MemoryType.experience;
      default:
        if (_containsAny(lower, _preferenceKeywords)) return MemoryType.preference;
        if (_containsAny(lower, _ruleKeywords)) return MemoryType.rule;
        if (_containsAny(lower, _identityKeywords)) return MemoryType.fact;
        return MemoryType.fact;
    }
  }

  MemoryDomain _classifyDomain(String lower) {
    if (_containsAny(lower, _projectKeywords)) return MemoryDomain.project;
    if (_containsAny(lower, ['朋友', 'friend', '好友', '聊天'])) return MemoryDomain.friend;
    if (_containsAny(lower, ['公司', 'company', '商业', 'business', '客户', 'client'])) return MemoryDomain.business;
    if (_containsAny(lower, ['研究', 'research', '论文', 'paper', '实验'])) return MemoryDomain.research;
    if (_containsAny(lower, ['游戏', 'game', '电影', 'movie', '音乐', 'music'])) return MemoryDomain.entertainment;
    return MemoryDomain.personal;
  }

  String _extractEventType(IntentType intent, MemoryType memoryType) {
    switch (memoryType) {
      case MemoryType.decision: return 'decision_made';
      case MemoryType.goal: return 'goal_set';
      case MemoryType.preference: return 'preference_set';
      case MemoryType.rule: return 'rule_established';
      case MemoryType.relationship: return 'relationship_noted';
      case MemoryType.experience: return 'experience_recorded';
      case MemoryType.procedure: return 'lesson_learned';
      default: return 'fact_stated';
    }
  }

  String _generateSummary(String message, IntentType intent, MemoryType memoryType) {
    if (message.length <= 100) return message;
    return '${message.substring(0, 97)}...';
  }

  (String?, EntityType?, RelationType?, String?) _extractEntity(String message, String lower) {
    for (final m in _identityPatterns) {
      final match = m.regex.firstMatch(message);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty && name.length < 50) {
          return (name, EntityType.person, RelationType.knows, 'user');
        }
      }
    }
    for (final m in _preferencePatterns) {
      final match = m.regex.firstMatch(message);
      if (match != null) {
        final target = match.group(1)?.trim();
        if (target != null && target.isNotEmpty && target.length < 50) {
          return (target, EntityType.concept, RelationType.prefers, 'user');
        }
      }
    }
    for (final tech in _techKeywords) {
      if (lower.contains(tech)) {
        String? project;
        final projectPatterns = [RegExp(r'(.+?)[用采]'), RegExp(r'(.+?)项目')];
        for (final p in projectPatterns) {
          final m = p.firstMatch(message);
          if (m != null) {
            project = m.group(1)?.trim();
            break;
          }
        }
        return (
          tech[0].toUpperCase() + tech.substring(1),
          EntityType.tech,
          project != null ? RelationType.uses : null,
          project,
        );
      }
    }
    for (final kw in _projectKeywords) {
      final idx = lower.indexOf(kw);
      if (idx > 0) {
        final before = message.substring(0, idx).trim();
        if (before.isNotEmpty && before.length <= 30) {
          return (before, EntityType.project, null, null);
        }
      }
    }
    return (null, null, null, null);
  }

  List<ExtractedEntity> _extractEntities(String message, String lower, IntentType intent) {
    final entities = <ExtractedEntity>[];

    for (final m in _identityPatterns) {
      final match = m.regex.firstMatch(message);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty && name.length < 50) {
          entities.add(ExtractedEntity(name: name, type: EntityType.person, properties: {'source': 'identity'}));
        }
      }
    }

    for (final m in _preferencePatterns) {
      final match = m.regex.firstMatch(message);
      if (match != null) {
        final target = match.group(1)?.trim();
        if (target != null && target.isNotEmpty && target.length < 50) {
          final type = _inferEntityType(target, lower);
          entities.add(ExtractedEntity(name: target, type: type, properties: {'source': 'preference'}));
        }
      }
    }

    for (final tech in _techKeywords) {
      if (lower.contains(tech)) {
        final name = tech[0].toUpperCase() + tech.substring(1);
        if (!entities.any((e) => e.name.toLowerCase() == name.toLowerCase())) {
          entities.add(ExtractedEntity(name: name, type: EntityType.tech, properties: {'source': 'keyword'}));
        }
      }
    }

    for (final kw in _projectKeywords) {
      final idx = lower.indexOf(kw);
      if (idx > 0) {
        final before = message.substring(0, idx).trim();
        if (before.isNotEmpty && before.length <= 30 && !entities.any((e) => e.name == before)) {
          entities.add(ExtractedEntity(name: before, type: EntityType.project, properties: {'source': 'keyword'}));
        }
      }
    }

    return entities;
  }

  List<ExtractedRelation> _extractRelations(String message, String lower, List<ExtractedEntity> entities, IntentType intent) {
    final relations = <ExtractedRelation>[];

    for (final entity in entities) {
      if (entity.properties['source'] == 'identity') {
        relations.add(ExtractedRelation(fromEntity: 'user', toEntity: entity.name, type: RelationType.knows));
      } else if (entity.properties['source'] == 'preference') {
        relations.add(ExtractedRelation(fromEntity: 'user', toEntity: entity.name, type: RelationType.prefers));
      }
    }

    if (intent == IntentType.decision && entities.length >= 2) {
      final projectEntity = entities.firstWhere(
        (e) => e.type == EntityType.project || e.type == EntityType.tech,
        orElse: () => entities.first,
      );
      final techEntity = entities.firstWhere(
        (e) => e.type == EntityType.tech && e != projectEntity,
        orElse: () => entities.length > 1 ? entities.last : entities.first,
      );
      if (projectEntity != techEntity) {
        relations.add(ExtractedRelation(fromEntity: projectEntity.name, toEntity: techEntity.name, type: RelationType.uses));
      }
    }

    final usesPatterns = [RegExp(r'(.+?)[用采](.+)'), RegExp(r'(.+?)使用(.+)')];
    for (final p in usesPatterns) {
      final m = p.firstMatch(message);
      if (m != null) {
        final from = m.group(1)?.trim();
        final to = m.group(2)?.trim();
        if (from != null && to != null && from.isNotEmpty && to.isNotEmpty) {
          if (!relations.any((r) => r.fromEntity == from && r.toEntity.contains(to))) {
            relations.add(ExtractedRelation(fromEntity: from, toEntity: to, type: RelationType.uses));
          }
        }
      }
    }

    return relations;
  }

  List<ExtractedEvent> _extractEvents(IntentType intent, MemoryType memoryType, List<ExtractedEntity> entities, List<ExtractedRelation> relations) {
    final events = <ExtractedEvent>[];

    if (entities.any((e) => e.properties['source'] == 'identity')) {
      events.add(ExtractedEvent(type: 'identity_stated', properties: {'entityName': entities.firstWhere((e) => e.properties['source'] == 'identity').name}));
    }

    if (relations.any((r) => r.type == RelationType.uses)) {
      final usesRelation = relations.firstWhere((r) => r.type == RelationType.uses);
      events.add(ExtractedEvent(type: 'tech_selected', properties: {'project': usesRelation.fromEntity, 'tech': usesRelation.toEntity}));
    }

    if (relations.any((r) => r.type == RelationType.prefers)) {
      final prefersRelation = relations.firstWhere((r) => r.type == RelationType.prefers);
      events.add(ExtractedEvent(type: 'preference_set', properties: {'target': prefersRelation.toEntity}));
    }

    if (events.isEmpty) {
      events.add(ExtractedEvent(type: _extractEventType(intent, memoryType)));
    }

    return events;
  }

  EntityType _inferEntityType(String name, String lower) {
    if (_techKeywords.any((t) => lower.contains(t))) return EntityType.tech;
    if (_projectKeywords.any((k) => lower.contains(k))) return EntityType.project;
    return EntityType.concept;
  }

  double _scoreConfidence(IntentType intent, int importance) {
    var conf = 80.0;
    if (intent == IntentType.joke) conf -= 30;
    if (intent == IntentType.sarcasm) conf -= 25;
    if (intent == IntentType.guess) conf -= 20;
    if (intent == IntentType.emotion) conf -= 10;
    if (intent == IntentType.fact) conf += 5;
    if (intent == IntentType.decision) conf += 10;
    return conf.clamp(0, 100);
  }

  String _generateReason(IntentType intent, MemoryType memoryType) {
    switch (memoryType) {
      case MemoryType.decision: return '用户做出决策';
      case MemoryType.goal: return '用户设定目标';
      case MemoryType.preference: return '用户表达偏好';
      case MemoryType.rule: return '用户设定规则';
      case MemoryType.relationship: return '关系信息';
      default: return '重要信息';
    }
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  static final _identityPatterns = [
    _Pattern(RegExp(r'(?:我叫|我的名字是|名字是)(\S+)'), 'name'),
    _Pattern(RegExp(r"(?:my name is|i'm|i am) (\w+(?:\s\w+)?)", caseSensitive: false), 'name'),
    _Pattern(RegExp(r'(?:私の名前は|私は)(\S+?)です'), 'name'),
    _Pattern(RegExp(r'(?:제 이름은|저는)(\S+?)입니다'), 'name'),
    _Pattern(RegExp(r'(?:我在|住在|来自)(\S+)'), 'location'),
    _Pattern(RegExp(r"(?:i live in|i'm from|i am from) ([\w\s]+)", caseSensitive: false), 'location'),
    _Pattern(RegExp(r'(?:我的工作|我的职业|我是做)(\S+)'), 'occupation'),
    _Pattern(RegExp(r"(?:i work as|i'm a|i am a) ([\w\s]+)", caseSensitive: false), 'occupation'),
  ];

  static final _preferencePatterns = [
    _Pattern(RegExp(r'(?:我喜欢|我爱|我偏好)(\S+)'), 'preference'),
    _Pattern(RegExp(r'(?:i like|i love|i prefer) ([\w\s]+)', caseSensitive: false), 'preference'),
    _Pattern(RegExp(r'(?:我不喜欢|我讨厌|我不爱)(\S+)'), 'dislike'),
    _Pattern(RegExp(r"(?:i don't like|i hate|i dislike) ([\w\s]+)", caseSensitive: false), 'dislike'),
  ];
}

class _Pattern {
  final RegExp regex;
  final String category;
  const _Pattern(this.regex, this.category);
}
