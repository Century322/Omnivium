import 'dart:convert';
import '../../app_logger.dart';
import '../../database_service.dart';
import 'cognitive_types.dart';
import 'entity_layer.dart';
import 'memory_transaction.dart';

class EntityStore {
  static const _entitiesKey = 'cognitive_entities';
  static const _relationsKey = 'cognitive_relations';
  static const _stateHistoryKey = 'cognitive_entity_states';

  final DatabaseService _db;
  List<MemoryEntity> _entities = [];
  List<EntityRelation> _relations = [];
  List<EntityState> _stateHistory = [];
  bool _initialized = false;
  bool _dirty = false;

  EntityStore(this._db);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final entitiesJson = await _db.getCache(_entitiesKey);
      if (entitiesJson != null) {
        final list = jsonDecode(entitiesJson) as List<dynamic>;
        _entities = list.map((e) => MemoryEntity.fromJson(e as Map<String, dynamic>)).toList();
      }
      final relationsJson = await _db.getCache(_relationsKey);
      if (relationsJson != null) {
        final list = jsonDecode(relationsJson) as List<dynamic>;
        _relations = list.map((e) => EntityRelation.fromJson(e as Map<String, dynamic>)).toList();
      }
      final statesJson = await _db.getCache(_stateHistoryKey);
      if (statesJson != null) {
        final list = jsonDecode(statesJson) as List<dynamic>;
        _stateHistory = list.map((e) => EntityState.fromJson(e as Map<String, dynamic>)).toList();
      }
      _initialized = true;
    } catch (e, st) {
      AppLogger.instance.error('EntityStore init failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persist() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      await _db.putCache(_entitiesKey, jsonEncode(_entities.map((e) => e.toJson()).toList()));
      await _db.putCache(_relationsKey, jsonEncode(_relations.map((e) => e.toJson()).toList()));
      await _db.putCache(_stateHistoryKey, jsonEncode(_stateHistory.map((e) => e.toJson()).toList()));
    } catch (e, st) {
      AppLogger.instance.error('EntityStore persist failed', error: e, stackTrace: st);
    }
  }

  void _markDirty() => _dirty = true;

  void registerWithTransaction(MemoryTransaction tx) {
    if (!_dirty) return;
    tx.register(_entitiesKey, () => jsonEncode(_entities.map((e) => e.toJson()).toList()));
    tx.register(_relationsKey, () => jsonEncode(_relations.map((e) => e.toJson()).toList()));
    tx.register(_stateHistoryKey, () => jsonEncode(_stateHistory.map((e) => e.toJson()).toList()));
    _dirty = false;
  }

  // ── Entity CRUD ──

  List<MemoryEntity> get entities => List.unmodifiable(_entities);
  List<EntityRelation> get relations => List.unmodifiable(_relations);

  MemoryEntity? getEntity(String id) {
    final idx = _entities.indexWhere((e) => e.id == id);
    return idx >= 0 ? _entities[idx] : null;
  }

  MemoryEntity? getEntityByName(String name, {EntityType? type}) {
    final lower = name.toLowerCase();
    for (final e in _entities) {
      if (e.name.toLowerCase() == lower) {
        if (type == null || e.type == type) return e;
      }
    }
    for (final e in _entities) {
      final aliases = (e.properties['aliases'] as List<dynamic>?) ?? [];
      if (aliases.any((a) => a.toString().toLowerCase() == lower)) {
        if (type == null || e.type == type) return e;
      }
    }
    return null;
  }

  Future<void> addAlias(String entityId, String alias) async {
    final idx = _entities.indexWhere((e) => e.id == entityId);
    if (idx < 0) return;
    final entity = _entities[idx];
    final aliases = List<String>.from((entity.properties['aliases'] as List<dynamic>?) ?? []);
    if (!aliases.any((a) => a.toLowerCase() == alias.toLowerCase())) {
      aliases.add(alias);
      _entities[idx] = entity.copyWith(
        properties: {...entity.properties, 'aliases': aliases},
        updatedAt: DateTime.now(),
      );
      _markDirty();
    }
  }

  MemoryEntity? resolveEntity(String name, {EntityType? type}) {
    return getEntityByName(name, type: type);
  }

  List<MemoryEntity> getEntitiesByType(EntityType type) =>
      _entities.where((e) => e.type == type).toList();

  List<MemoryEntity> getEntitiesByDomain(MemoryDomain domain) =>
      _entities.where((e) => e.domain == domain).toList();

  List<MemoryEntity> getEntitiesByWorkspace(String workspaceId) =>
      _entities.where((e) => e.workspaceId == workspaceId).toList();

  Future<MemoryEntity> upsertEntity(MemoryEntity entity) async {
    final idx = _entities.indexWhere((e) => e.id == entity.id);
    if (idx >= 0) {
      _entities[idx] = entity;
    } else {
      _entities.add(entity);
    }
    _markDirty();
    return entity;
  }

  Future<MemoryEntity> findOrCreateEntity({
    required String name,
    required EntityType type,
    MemoryDomain domain = MemoryDomain.project,
    String? workspaceId,
    Map<String, dynamic>? properties,
  }) async {
    final existing = getEntityByName(name, type: type);
    if (existing != null) {
      final touched = existing.copyWith(
        lastAccessedAt: DateTime.now(),
        properties: properties != null ? {...existing.properties, ...properties} : null,
      );
      return upsertEntity(touched);
    }
    final entity = MemoryEntity(
      id: 'entity_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.abs()}',
      name: name,
      type: type,
      domain: domain,
      workspaceId: workspaceId,
      currentState: 'created',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      properties: properties ?? {},
    );
    return upsertEntity(entity);
  }

  Future<void> removeEntity(String id) async {
    _entities.removeWhere((e) => e.id == id);
    _relations.removeWhere((r) => r.fromEntityId == id || r.toEntityId == id);
    _stateHistory.removeWhere((s) => s.entityId == id);
    _markDirty();
  }

  // ── Entity State ──

  List<EntityState> getStateHistory(String entityId) =>
      _stateHistory.where((s) => s.entityId == entityId).toList()
        ..sort((a, b) => b.since.compareTo(a.since));

  Future<void> setEntityState(String entityId, String newState, {String? sourceEventId}) async {
    final idx = _entities.indexWhere((e) => e.id == entityId);
    if (idx < 0) return;
    final oldState = _entities[idx].currentState;
    if (oldState == newState) return;
    final stateEntry = EntityState(
      id: 'state_${DateTime.now().millisecondsSinceEpoch}',
      entityId: entityId,
      state: newState,
      since: DateTime.now(),
      sourceEventId: sourceEventId,
      context: {'previousState': oldState},
    );
    _stateHistory.add(stateEntry);
    _entities[idx] = _entities[idx].copyWith(
      currentState: newState,
      updatedAt: DateTime.now(),
    );
    _markDirty();
  }

  // ── Relations ──

  List<EntityRelation> getRelationsFrom(String entityId) =>
      _relations.where((r) => r.fromEntityId == entityId).toList();

  List<EntityRelation> getRelationsTo(String entityId) =>
      _relations.where((r) => r.toEntityId == entityId).toList();

  List<EntityRelation> getRelationsOfType(RelationType type) =>
      _relations.where((r) => r.type == type).toList();

  EntityRelation? getRelation(String fromId, {String? toId, RelationType? type}) {
    for (final r in _relations) {
      if (r.fromEntityId == fromId &&
          (toId == null || r.toEntityId == toId) &&
          (type == null || r.type == type)) {
        return r;
      }
    }
    return null;
  }

  Future<EntityRelation> addRelation({
    required String fromEntityId,
    required String toEntityId,
    required RelationType type,
    double strength = 1.0,
    String? sourceEventId,
    Map<String, dynamic>? metadata,
  }) async {
    final existing = getRelation(fromEntityId, toId: toEntityId, type: type);
    if (existing != null) return existing;
    final relation = EntityRelation(
      id: 'rel_${DateTime.now().millisecondsSinceEpoch}_${fromEntityId.hashCode.abs()}_${toEntityId.hashCode.abs()}',
      fromEntityId: fromEntityId,
      toEntityId: toEntityId,
      type: type,
      strength: strength,
      since: DateTime.now(),
      sourceEventId: sourceEventId,
      metadata: metadata ?? {},
    );
    _relations.add(relation);
    _markDirty();
    return relation;
  }

  Future<void> removeRelation(String relationId) async {
    _relations.removeWhere((r) => r.id == relationId);
    _markDirty();
  }

  // ── Graph Queries ──

  List<MemoryEntity> getRelatedEntities(String entityId, {RelationType? type}) {
    final ids = <String>{};
    for (final r in _relations) {
      if (type != null && r.type != type) continue;
      if (r.fromEntityId == entityId) ids.add(r.toEntityId);
      if (r.toEntityId == entityId) ids.add(r.fromEntityId);
    }
    return ids.map((id) => getEntity(id)).whereType<MemoryEntity>().toList();
  }

  List<MemoryEntity> getEntitiesUsing(String entityId) {
    final ids = <String>{};
    for (final r in _relations) {
      if (r.toEntityId == entityId && r.type == RelationType.uses) {
        ids.add(r.fromEntityId);
      }
    }
    return ids.map((id) => getEntity(id)).whereType<MemoryEntity>().toList();
  }

  List<MemoryEntity> traverse(String startEntityId, {int maxHops = 3, RelationType? relationType, Set<String>? visited}) {
    final result = <MemoryEntity>[];
    final seen = visited ?? <String>{};
    seen.add(startEntityId);

    final neighbors = getRelatedEntities(startEntityId, type: relationType);
    for (final neighbor in neighbors) {
      if (seen.contains(neighbor.id)) continue;
      seen.add(neighbor.id);
      result.add(neighbor);

      if (maxHops > 1) {
        final deeper = traverse(neighbor.id, maxHops: maxHops - 1, relationType: relationType, visited: seen);
        result.addAll(deeper);
      }
    }
    return result;
  }

  List<List<String>> findPaths(String fromId, String toId, {int maxDepth = 4}) {
    final paths = <List<String>>[];
    _dfsPath(fromId, toId, <String>[], <String>{}, maxDepth, paths);
    return paths;
  }

  void _dfsPath(
    String current,
    String target,
    List<String> path,
    Set<String> visited,
    int maxDepth,
    List<List<String>> results,
  ) {
    if (path.length > maxDepth) return;
    visited.add(current);
    path.add(current);

    if (current == target) {
      results.add(List.from(path));
      path.removeLast();
      visited.remove(current);
      return;
    }

    for (final r in _relations) {
      String? next;
      if (r.fromEntityId == current && !visited.contains(r.toEntityId)) {
        next = r.toEntityId;
      } else if (r.toEntityId == current && !visited.contains(r.fromEntityId)) {
        next = r.fromEntityId;
      }
      if (next != null) {
        _dfsPath(next, target, path, visited, maxDepth, results);
      }
    }

    path.removeLast();
    visited.remove(current);
  }

  SubGraph extractSubGraph(String centerEntityId, {int radius = 2}) {
    final entityIds = <String>{centerEntityId};
    final edgeRelations = <EntityRelation>[];
    var frontier = <String>{centerEntityId};

    for (var hop = 0; hop < radius; hop++) {
      final nextFrontier = <String>{};
      for (final id in frontier) {
        for (final r in _relations) {
          if (r.fromEntityId == id && !entityIds.contains(r.toEntityId)) {
            entityIds.add(r.toEntityId);
            nextFrontier.add(r.toEntityId);
            edgeRelations.add(r);
          } else if (r.toEntityId == id && !entityIds.contains(r.fromEntityId)) {
            entityIds.add(r.fromEntityId);
            nextFrontier.add(r.fromEntityId);
            edgeRelations.add(r);
          } else if (r.fromEntityId == id || r.toEntityId == id) {
            if (!edgeRelations.any((er) => er.id == r.id)) {
              edgeRelations.add(r);
            }
          }
        }
      }
      frontier = nextFrontier;
    }

    final subEntities = entityIds.map((id) => getEntity(id)).whereType<MemoryEntity>().toList();
    return SubGraph(entities: subEntities, relations: edgeRelations);
  }

  // ── Lifecycle ──

  Future<void> transitionLifecycle(String entityId, MemoryLifecycle newLifecycle) async {
    final idx = _entities.indexWhere((e) => e.id == entityId);
    if (idx < 0) return;
    _entities[idx] = _entities[idx].copyWith(
      lifecycle: newLifecycle,
      updatedAt: DateTime.now(),
    );
    _markDirty();
  }

  Future<void> decayLifecycle() async {
    final now = DateTime.now();
    for (var i = 0; i < _entities.length; i++) {
      final e = _entities[i];
      if (e.lifecycle == MemoryLifecycle.active) {
        final diff = now.difference(e.lastAccessedAt).inDays;
        if (diff > 180) {
          _entities[i] = e.copyWith(lifecycle: MemoryLifecycle.warm, updatedAt: now);
        }
      } else if (e.lifecycle == MemoryLifecycle.warm) {
        final diff = now.difference(e.lastAccessedAt).inDays;
        if (diff > 730) {
          _entities[i] = e.copyWith(lifecycle: MemoryLifecycle.frozen, updatedAt: now);
        }
      }
    }
    _markDirty();
  }

  // ── Stats ──

  int get entityCount => _entities.length;
  int get relationCount => _relations.length;

  Map<String, int> get entityCountsByType {
    final counts = <String, int>{};
    for (final e in _entities) {
      counts[e.type.name] = (counts[e.type.name] ?? 0) + 1;
    }
    return counts;
  }
}
