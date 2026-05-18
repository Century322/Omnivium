import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'memory_manager.dart';

class LocalMemoryManager implements MemoryManager {
  static const _key = 'omnivium_memories';
  List<LegacyMemoryEntry> _entries = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _entries = list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _entries.map(_toJson).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  @override
  Future<void> store(LegacyMemoryEntry entry) async {
    await _ensureLoaded();
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      _entries[idx] = entry;
    } else {
      _entries.add(entry);
    }
    await _save();
  }

  @override
  Future<List<LegacyMemoryEntry>> retrieve(String query, {int limit = 10}) async {
    await _ensureLoaded();
    final q = query.toLowerCase();
    final now = DateTime.now();
    final scored = <MapEntry<LegacyMemoryEntry, double>>[];
    for (final entry in _entries) {
      if (entry.expiresAt != null && entry.expiresAt!.isBefore(now)) continue;
      double score = 0;
      if (entry.content.toLowerCase().contains(q)) score += 2.0;
      score += entry.importance;
      final ageDays = now.difference(entry.createdAt).inDays;
      score *= 1.0 / (1.0 + ageDays * 0.02);
      scored.add(MapEntry(entry, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  @override
  Future<void> delete(String id) async {
    await _ensureLoaded();
    _entries.removeWhere((e) => e.id == id);
    await _save();
  }

  @override
  Future<List<LegacyMemoryEntry>> getUserMemories() async {
    await _ensureLoaded();
    final now = DateTime.now();
    return _entries.where((e) => e.expiresAt == null || e.expiresAt!.isAfter(now)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<LegacyMemoryEntry>> getConversationMemories(String conversationId) async {
    await _ensureLoaded();
    return _entries.where((e) => e.id.startsWith('conv_$conversationId')).toList();
  }

  @override
  Future<List<LegacyMemoryEntry>> getTopicMemories(String topic) async {
    await _ensureLoaded();
    final t = topic.toLowerCase();
    return _entries.where((e) => e.content.toLowerCase().contains(t)).toList();
  }

  Map<String, dynamic> _toJson(LegacyMemoryEntry e) => {
    'id': e.id, 'type': e.type.name, 'content': e.content,
    'importance': e.importance, 'confidence': e.confidence,
    'createdAt': e.createdAt.toIso8601String(),
    'expiresAt': e.expiresAt?.toIso8601String(),
  };

  LegacyMemoryEntry _fromJson(Map<String, dynamic> m) => LegacyMemoryEntry(
    id: m['id'],
    type: _parseMemoryType(m['type']),
    content: m['content'], importance: (m['importance'] as num).toDouble(),
    confidence: (m['confidence'] as num).toDouble(),
    createdAt: DateTime.parse(m['createdAt']),
    expiresAt: m['expiresAt'] != null ? DateTime.parse(m['expiresAt']) : null,
  );

  static MemoryType _parseMemoryType(dynamic value) {
    if (value is String) {
      return MemoryType.values.where((e) => e.name == value).firstOrNull ?? MemoryType.fact;
    }
    if (value is int) {
      return MemoryType.values[value.clamp(0, MemoryType.values.length - 1)];
    }
    return MemoryType.fact;
  }
}
