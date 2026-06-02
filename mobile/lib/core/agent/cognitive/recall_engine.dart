import 'cognitive_types.dart';
import 'entity_layer.dart';
import 'entity_store.dart';
import 'goal_store.dart';
import 'memory_event.dart';
import 'working_memory.dart';
import 'episodic_memory.dart';
import '../embedding_service.dart';
import '../../app_logger.dart';

class RecallQuery {
  final String clue;
  final MemoryDomain? domain;
  final String? workspaceId;
  final String? subspaceId;
  final DateTime? timeStart;
  final DateTime? timeEnd;
  final String? speakerId;
  final String? entityId;
  final MemoryType? memoryType;
  final IntentType? intent;
  final int minImportance;
  final String? scene;

  const RecallQuery({
    required this.clue,
    this.domain,
    this.workspaceId,
    this.subspaceId,
    this.timeStart,
    this.timeEnd,
    this.speakerId,
    this.entityId,
    this.memoryType,
    this.intent,
    this.minImportance = 20,
    this.scene,
  });
}

class RecallResult {
  final List<MemoryEvent> events;
  final List<MemoryEntity> relatedEntities;
  final List<EntityRelation> relations;
  final String? workspaceContext;
  final double relevanceScore;
  final EpisodicMemory? episode;
  final Map<String, double> channelScores;

  const RecallResult({
    this.events = const [],
    this.relatedEntities = const [],
    this.relations = const [],
    this.workspaceContext,
    this.relevanceScore = 0,
    this.episode,
    this.channelScores = const {},
  });

  bool get isEmpty => events.isEmpty && relatedEntities.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class _ScoredEvent {
  final MemoryEvent event;
  double keywordScore;
  double embeddingScore;
  double graphScore;
  double episodicScore;
  double get fusedScore => keywordScore * 0.3 + embeddingScore * 0.35 + graphScore * 0.2 + episodicScore * 0.15;

  _ScoredEvent(this.event, {
    this.keywordScore = 0,
    this.embeddingScore = 0,
    this.graphScore = 0,
    this.episodicScore = 0,
  });
}

class RecallEngine {
  final EntityStore entityStore;
  final GoalStore goalStore;
  final WorkingMemory workingMemory;
  final EpisodicMemoryStore episodicMemoryStore;

  RecallEngine({
    required this.entityStore,
    required this.goalStore,
    required this.workingMemory,
    required this.episodicMemoryStore,
  });

  Future<RecallResult> recall(RecallQuery query, List<MemoryEvent> allEvents) async {
    var candidates = allEvents.where((e) => e.lifecycle != MemoryLifecycle.frozen).toList();

    if (query.domain != null) {
      candidates = candidates.where((e) => e.domain == query.domain).toList();
    }
    if (query.workspaceId != null) {
      candidates = candidates.where((e) => e.workspaceId == query.workspaceId).toList();
    }
    if (query.speakerId != null) {
      candidates = candidates.where((e) => e.speakerId == query.speakerId).toList();
    }
    if (query.memoryType != null) {
      candidates = candidates.where((e) => e.memoryType == query.memoryType).toList();
    }
    if (query.intent != null) {
      candidates = candidates.where((e) => e.intent == query.intent).toList();
    }
    if (query.minImportance > 0) {
      candidates = candidates.where((e) => e.importance >= query.minImportance).toList();
    }
    if (query.timeStart != null) {
      candidates = candidates.where((e) => e.timestamp.isAfter(query.timeStart!)).toList();
    }
    if (query.timeEnd != null) {
      candidates = candidates.where((e) => e.timestamp.isBefore(query.timeEnd!)).toList();
    }

    final scored = <String, _ScoredEvent>{};
    for (final event in candidates) {
      scored[event.id] = _ScoredEvent(event);
    }

    _scoreKeyword(scored, query);
    await _scoreEmbedding(scored, query);
    _scoreGraph(scored, query);
    _scoreEpisodic(scored, query);

    final sorted = scored.values.toList()
      ..sort((a, b) => b.fusedScore.compareTo(a.fusedScore));

    final topEvents = sorted.where((s) => s.fusedScore > 0).take(20).map((e) => e.event).toList();
    final relatedEntities = _collectEntities(topEvents, query);
    final relations = _collectRelations(relatedEntities);

    EpisodicMemory? episode;
    final sceneClue = query.scene ?? query.clue;
    final episodes = episodicMemoryStore.searchEpisodes(sceneClue);
    if (episodes.isNotEmpty) {
      episode = episodes.first;
    } else if (topEvents.isNotEmpty) {
      final eventIds = topEvents.map((e) => e.id).toSet();
      final episodes = episodicMemoryStore.episodes.where(
        (ep) => ep.relatedEventIds.any((id) => eventIds.contains(id)),
      ).toList();
      if (episodes.isNotEmpty) episode = episodes.first;
    }

    final topScored = sorted.where((s) => s.fusedScore > 0).firstOrNull;
    final channelScores = <String, double>{};
    if (topScored != null) {
      channelScores['keyword'] = topScored.keywordScore;
      channelScores['embedding'] = topScored.embeddingScore;
      channelScores['graph'] = topScored.graphScore;
      channelScores['episodic'] = topScored.episodicScore;
      channelScores['fused'] = topScored.fusedScore;
    }

    return RecallResult(
      events: topEvents,
      relatedEntities: relatedEntities,
      relations: relations,
      workspaceContext: query.workspaceId,
      relevanceScore: topScored?.fusedScore ?? 0,
      episode: episode,
      channelScores: channelScores,
    );
  }

  void _scoreKeyword(Map<String, _ScoredEvent> scored, RecallQuery query) {
    final clueLower = query.clue.toLowerCase();
    final clueWords = clueLower.split(RegExp(r'\s+')).where((w) => w.length > 1);

    for (final entry in scored.entries) {
      final event = entry.value.event;
      var score = event.importance / 100.0 * 30;

      final summaryLower = event.summary.toLowerCase();
      for (final word in clueWords) {
        if (summaryLower.contains(word)) {
          score += 20;
        }
      }

      final entityName = event.properties['entityName'] as String?;
      if (entityName != null && clueLower.contains(entityName.toLowerCase())) {
        score += 25;
      }

      final aliases = (event.properties['aliases'] as List<dynamic>?) ?? [];
      for (final alias in aliases) {
        if (clueLower.contains(alias.toString().toLowerCase())) {
          score += 15;
          break;
        }
      }

      final ageDays = DateTime.now().difference(event.timestamp).inDays;
      score += 1.0 / (1.0 + ageDays * 0.01) * 15;

      if (workingMemory.activeEntityIds.isNotEmpty) {
        final eName = event.properties['entityName'] as String?;
        if (eName != null) {
          final matching = entityStore.entities.where(
            (e) => workingMemory.activeEntityIds.contains(e.id) && e.name.toLowerCase() == eName.toLowerCase(),
          );
          if (matching.isNotEmpty) score += 10;
        }
      }

      entry.value.keywordScore = score.clamp(0, 100);
    }
  }

  Future<void> _scoreEmbedding(Map<String, _ScoredEvent> scored, RecallQuery query) async {
    try {
      final embeddingService = EmbeddingService.instance;
      final similarResults = await embeddingService.searchSimilar(
        query.clue,
        maxResults: 30,
        threshold: 0.3,
      );

      for (final result in similarResults) {
        if (scored.containsKey(result.key)) {
          scored[result.key]!.embeddingScore = (result.value * 100).clamp(0, 100);
        } else {
          for (final entry in scored.entries) {
            if (entry.value.event.id == result.key) {
              entry.value.embeddingScore = (result.value * 100).clamp(0, 100);
              break;
            }
          }
        }
      }
    } catch (e) {
      AppLogger.instance.warning('Embedding recall failed', error: e);
    }
  }

  void _scoreGraph(Map<String, _ScoredEvent> scored, RecallQuery query) {
    final clueLower = query.clue.toLowerCase();
    final clueEntities = <MemoryEntity>[];

    for (final entity in entityStore.entities) {
      if (clueLower.contains(entity.name.toLowerCase())) {
        clueEntities.add(entity);
      }
      final aliases = (entity.properties['aliases'] as List<dynamic>?) ?? [];
      for (final alias in aliases) {
        if (clueLower.contains(alias.toString().toLowerCase())) {
          clueEntities.add(entity);
          break;
        }
      }
    }

    if (clueEntities.isEmpty) return;

    final relatedEntityIds = <String>{};
    for (final entity in clueEntities) {
      relatedEntityIds.add(entity.id);
      final related = entityStore.getRelatedEntities(entity.id);
      for (final r in related) {
        relatedEntityIds.add(r.id);
      }
    }

    for (final entry in scored.entries) {
      final event = entry.value.event;
      final entityName = event.properties['entityName'] as String?;
      if (entityName != null) {
        final entity = entityStore.getEntityByName(entityName);
        if (entity != null && relatedEntityIds.contains(entity.id)) {
          entry.value.graphScore = 25.0;
        }
      }
    }
  }

  void _scoreEpisodic(Map<String, _ScoredEvent> scored, RecallQuery query) {
    final clue = query.scene ?? query.clue;
    final episodes = episodicMemoryStore.searchEpisodes(clue);

    if (episodes.isEmpty) return;

    final episodeEventIds = <String>{};
    for (final ep in episodes) {
      episodeEventIds.addAll(ep.relatedEventIds);
    }

    for (final entry in scored.entries) {
      if (episodeEventIds.contains(entry.key)) {
        entry.value.episodicScore = 30.0;
      }
    }
  }

  List<MemoryEntity> _collectEntities(List<MemoryEvent> events, RecallQuery query) {
    final entityIds = <String>{};
    for (final event in events) {
      final entityName = event.properties['entityName'] as String?;
      if (entityName != null) {
        final entity = entityStore.getEntityByName(entityName);
        if (entity != null) entityIds.add(entity.id);
      }
      final extractedEntities = event.properties['extractedEntities'] as List<dynamic>?;
      if (extractedEntities != null) {
        for (final e in extractedEntities) {
          if (e is Map<String, dynamic>) {
            final name = e['name'] as String?;
            if (name != null) {
              final entity = entityStore.getEntityByName(name);
              if (entity != null) entityIds.add(entity.id);
            }
          }
        }
      }
    }
    if (query.entityId != null) entityIds.add(query.entityId!);
    return entityIds.map((id) => entityStore.getEntity(id)).whereType<MemoryEntity>().toList();
  }

  List<EntityRelation> _collectRelations(List<MemoryEntity> entities) {
    final entityIds = entities.map((e) => e.id).toSet();
    return entityStore.relations.where((r) =>
        entityIds.contains(r.fromEntityId) || entityIds.contains(r.toEntityId)).toList();
  }

  RecallResult recallByEntity(String entityName, List<MemoryEvent> allEvents, {int limit = 10}) {
    final entity = entityStore.getEntityByName(entityName);
    if (entity == null) return const RecallResult();

    final subGraph = entityStore.extractSubGraph(entity.id, radius: 2);

    final relatedEvents = allEvents.where((e) {
      final eName = e.properties['entityName'] as String?;
      if (eName != null && eName.toLowerCase() == entityName.toLowerCase()) return true;
      final extracted = e.properties['extractedEntities'] as List<dynamic>?;
      if (extracted != null) {
        return extracted.any((ex) =>
          ex is Map<String, dynamic> && (ex['name'] as String?)?.toLowerCase() == entityName.toLowerCase());
      }
      return false;
    }).toList()
      ..sort((a, b) => b.importance.compareTo(a.importance));

    return RecallResult(
      events: relatedEvents.take(limit).toList(),
      relatedEntities: subGraph.entities,
      relations: subGraph.relations,
      relevanceScore: 0.8,
      channelScores: {'graph': 80.0},
    );
  }
}
