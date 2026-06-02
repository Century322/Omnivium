import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';
import '../../app_logger.dart';
import '../../database_service.dart';
import 'cognitive_types.dart';
import 'memory_transaction.dart';

part 'episodic_memory.freezed.dart';

@freezed
class EpisodicMemory with _$EpisodicMemory {
  const EpisodicMemory._();

  const factory EpisodicMemory({
    required String id,
    required String scene,
    @Default(<String>[]) List<String> participants,
    String? emotion,
    required DateTime timestamp,
    String? workspaceId,
    @Default(<String>[]) List<String> relatedEventIds,
    String? location,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _EpisodicMemory;

  Map<String, dynamic> toJson() => {
    'id': id,
    'scene': scene,
    'participants': participants,
    'emotion': emotion,
    'timestamp': timestamp.toIso8601String(),
    'workspaceId': workspaceId,
    'relatedEventIds': relatedEventIds,
    'location': location,
    'metadata': metadata,
  };

  factory EpisodicMemory.fromJson(Map<String, dynamic> json) => EpisodicMemory(
    id: json['id'] as String,
    scene: json['scene'] as String,
    participants: (json['participants'] as List<dynamic>?)?.cast<String>() ?? [],
    emotion: json['emotion'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
    workspaceId: json['workspaceId'] as String?,
    relatedEventIds: (json['relatedEventIds'] as List<dynamic>?)?.cast<String>() ?? [],
    location: json['location'] as String?,
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );
}

class EpisodicMemoryStore {
  static const _episodesKey = 'cognitive_episodes';

  final DatabaseService _db;
  List<EpisodicMemory> _episodes = [];
  bool _initialized = false;
  bool _dirty = false;

  EpisodicMemoryStore(this._db);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final json = await _db.getCache(_episodesKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _episodes = list.map((e) => EpisodicMemory.fromJson(e as Map<String, dynamic>)).toList();
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('EpisodicMemoryStore init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persist() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      await _db.putCache(_episodesKey, jsonEncode(_episodes.map((e) => e.toJson()).toList()));
    } catch (e, st) {
      AppLogger.instance.error('EpisodicMemoryStore persist failed', error: e, stackTrace: st);
    }
  }

  void _markDirty() => _dirty = true;

  void registerWithTransaction(MemoryTransaction tx) {
    if (!_dirty) return;
    tx.register(_episodesKey, () => jsonEncode(_episodes.map((e) => e.toJson()).toList()));
    _dirty = false;
  }

  List<EpisodicMemory> get episodes => List.unmodifiable(_episodes);

  EpisodicMemory? getEpisode(String id) {
    for (final e in _episodes) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<EpisodicMemory> getEpisodesByWorkspace(String workspaceId) =>
      _episodes.where((e) => e.workspaceId == workspaceId).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  List<EpisodicMemory> getEpisodesByEmotion(String emotion) =>
      _episodes.where((e) => e.emotion?.toLowerCase() == emotion.toLowerCase()).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  List<EpisodicMemory> getRecentEpisodes({int limit = 10}) =>
      _episodes.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp))
        ..length = _episodes.length < limit ? _episodes.length : limit;

  Future<EpisodicMemory> createEpisode({
    required String scene,
    List<String>? participants,
    String? emotion,
    String? workspaceId,
    List<String>? relatedEventIds,
    String? location,
  }) async {
    final episode = EpisodicMemory(
      id: 'ep_${DateTime.now().millisecondsSinceEpoch}_${scene.hashCode.abs()}',
      scene: scene,
      participants: participants ?? [],
      emotion: emotion,
      timestamp: DateTime.now(),
      workspaceId: workspaceId,
      relatedEventIds: relatedEventIds ?? [],
      location: location,
    );
    _episodes.add(episode);
    _markDirty();
    return episode;
  }

  Future<void> removeEpisode(String id) async {
    _episodes.removeWhere((e) => e.id == id);
    _markDirty();
  }

  List<EpisodicMemory> searchEpisodes(String clue) {
    final clueLower = clue.toLowerCase();
    final scored = <MapEntry<EpisodicMemory, double>>[];

    for (final ep in _episodes) {
      var score = 0.0;
      if (ep.scene.toLowerCase().contains(clueLower)) score += 30;
      if (ep.emotion?.toLowerCase().contains(clueLower) == true) score += 20;
      if (ep.location?.toLowerCase().contains(clueLower) == true) score += 15;
      for (final p in ep.participants) {
        if (p.toLowerCase().contains(clueLower)) score += 10;
      }
      if (score > 0) {
        scored.add(MapEntry(ep, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  int get episodeCount => _episodes.length;
}
