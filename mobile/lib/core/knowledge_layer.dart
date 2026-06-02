import 'dart:convert';
import 'app_logger.dart';
import 'database_service.dart';
import 'di/app_di.dart';
import 'workspace_service.dart';
import 'agent_service.dart';

enum KnowledgeLayer {
  project,
  personal,
  system,
  agent,
}

class KnowledgeEntry {
  final String id;
  final String title;
  final String content;
  final KnowledgeLayer layer;
  final String? workspaceId;
  final String? agentId;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KnowledgeEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.layer,
    this.workspaceId,
    this.agentId,
    this.tags = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'layer': layer.name,
    if (workspaceId != null) 'workspaceId': workspaceId,
    if (agentId != null) 'agentId': agentId,
    'tags': tags,
    'metadata': metadata,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory KnowledgeEntry.fromJson(Map<String, dynamic> json) => KnowledgeEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    layer: KnowledgeLayer.values.firstWhere(
      (e) => e.name == json['layer'],
      orElse: () => KnowledgeLayer.personal,
    ),
    workspaceId: json['workspaceId'] as String?,
    agentId: json['agentId'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class KnowledgeLayerService {
  final DatabaseService _db;
  bool _isInitialized = false;

  static const _entriesKey = 'knowledge_entries';
  static const _maxEntries = 500;

  List<KnowledgeEntry> _entries = [];

  KnowledgeLayerService(this._db);

  bool get isInitialized => _isInitialized;
  int get entryCount => _entries.length;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final json = await _db.getCache(_entriesKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        _entries = list
            .map((e) => KnowledgeEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _isInitialized = true;
      AppLogger.instance.info('KnowledgeLayerService initialized: ${_entries.length} entries');
    } catch (e, st) {
      AppLogger.instance.error('KnowledgeLayerService init failed', error: e, stackTrace: st);
      _isInitialized = true;
    }
  }

  Future<KnowledgeEntry> addEntry({
    required String title,
    required String content,
    required KnowledgeLayer layer,
    String? workspaceId,
    String? agentId,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    final entry = KnowledgeEntry(
      id: 'kn_${DateTime.now().millisecondsSinceEpoch}_${title.hashCode.abs()}',
      title: title,
      content: content,
      layer: layer,
      workspaceId: workspaceId,
      agentId: agentId,
      tags: tags,
      metadata: metadata,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _entries.add(entry);

    if (_entries.length > _maxEntries) {
      _entries = _entries.sublist(_entries.length - _maxEntries);
    }

    await _persist();
    return entry;
  }

  Future<KnowledgeEntry> updateEntry(String id, {
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx < 0) return _entries.first;

    _entries[idx] = KnowledgeEntry(
      id: _entries[idx].id,
      title: title ?? _entries[idx].title,
      content: content ?? _entries[idx].content,
      layer: _entries[idx].layer,
      workspaceId: _entries[idx].workspaceId,
      agentId: _entries[idx].agentId,
      tags: tags ?? _entries[idx].tags,
      metadata: _entries[idx].metadata,
      createdAt: _entries[idx].createdAt,
      updatedAt: DateTime.now(),
    );

    await _persist();
    return _entries[idx];
  }

  Future<void> removeEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persist();
  }

  List<KnowledgeEntry> getEntriesByLayer(KnowledgeLayer layer) =>
      _entries.where((e) => e.layer == layer).toList();

  List<KnowledgeEntry> getEntriesByWorkspace(String workspaceId) =>
      _entries.where((e) => e.workspaceId == workspaceId).toList();

  List<KnowledgeEntry> getEntriesByAgent(String agentId) =>
      _entries.where((e) => e.agentId == agentId).toList();

  List<KnowledgeEntry> searchEntries(String query) {
    final lower = query.toLowerCase();
    return _entries.where((e) =>
        e.title.toLowerCase().contains(lower) ||
        e.content.toLowerCase().contains(lower) ||
        e.tags.any((t) => t.toLowerCase().contains(lower)),
    ).toList();
  }

  String buildKnowledgeContext({String? workspaceId, String? agentId}) {
    final buffer = StringBuffer();
    buffer.writeln('[Knowledge]');

    final projectEntries = workspaceId != null
        ? getEntriesByWorkspace(workspaceId)
        : getEntriesByLayer(KnowledgeLayer.project);

    final personalEntries = getEntriesByLayer(KnowledgeLayer.personal);
    final systemEntries = getEntriesByLayer(KnowledgeLayer.system);
    final agentEntries = agentId != null
        ? getEntriesByAgent(agentId)
        : getEntriesByLayer(KnowledgeLayer.agent);

    if (projectEntries.isNotEmpty) {
      buffer.writeln('\nProject Knowledge:');
      for (final entry in projectEntries.take(5)) {
        buffer.writeln('  ${entry.title}: ${_truncate(entry.content, 80)}');
      }
    }

    if (personalEntries.isNotEmpty) {
      buffer.writeln('\nPersonal Knowledge:');
      for (final entry in personalEntries.take(5)) {
        buffer.writeln('  ${entry.title}: ${_truncate(entry.content, 80)}');
      }
    }

    if (systemEntries.isNotEmpty) {
      buffer.writeln('\nSystem Knowledge:');
      for (final entry in systemEntries.take(3)) {
        buffer.writeln('  ${entry.title}: ${_truncate(entry.content, 80)}');
      }
    }

    if (agentEntries.isNotEmpty) {
      buffer.writeln('\nAgent Knowledge:');
      for (final entry in agentEntries.take(3)) {
        buffer.writeln('  ${entry.title}: ${_truncate(entry.content, 80)}');
      }
    }

    if (projectEntries.isEmpty && personalEntries.isEmpty &&
        systemEntries.isEmpty && agentEntries.isEmpty) {
      buffer.writeln('No knowledge entries yet.');
    }

    return buffer.toString();
  }

  String _truncate(String text, int maxLen) =>
      text.length <= maxLen ? text : '${text.substring(0, maxLen - 3)}...';

  Future<void> _persist() async {
    try {
      await _db.putCache(
        _entriesKey,
        jsonEncode(_entries.map((e) => e.toJson()).toList()),
      );
    } catch (e, st) {
      AppLogger.instance.error('KnowledgeLayerService persist failed', error: e, stackTrace: st);
    }
  }

  Future<void> clear() async {
    _entries.clear();
    await _persist();
  }
}
