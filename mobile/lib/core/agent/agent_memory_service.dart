import 'dart:convert';
import 'dart:isolate';
import '../database_service.dart';
import '../remote_config_service.dart';
import '../app_logger.dart';
import 'embedding_service.dart';

class MemoryEntry {
  final String id;
  final String category;
  final String content;
  final double importance;
  final DateTime createdAt;
  final DateTime? lastAccessedAt;
  final int accessCount;

  const MemoryEntry({
    required this.id,
    required this.category,
    required this.content,
    this.importance = 0.5,
    required this.createdAt,
    this.lastAccessedAt,
    this.accessCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'content': content,
    'importance': importance,
    'createdAt': createdAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt?.toIso8601String(),
    'accessCount': accessCount,
  };

  factory MemoryEntry.fromJson(Map<String, dynamic> json) => MemoryEntry(
    id: json['id'],
    category: json['category'],
    content: json['content'],
    importance: (json['importance'] as num?)?.toDouble() ?? 0.5,
    createdAt: DateTime.parse(json['createdAt']),
    lastAccessedAt: json['lastAccessedAt'] != null
        ? DateTime.parse(json['lastAccessedAt'])
        : null,
    accessCount: json['accessCount'] ?? 0,
  );
}

class AgentMemoryService {
  static final AgentMemoryService _instance = AgentMemoryService._();
  static AgentMemoryService get instance => _instance;
  AgentMemoryService._();

  static const _memoryKey = 'agent_long_term_memory';
  static const _profileKey = 'agent_user_profile';
  static const _maxInputLength = 10000;
  static const _regexTimeoutMs = 2000;

  List<MemoryEntry> _memories = [];
  Map<String, dynamic> _userProfile = {};

  List<MemoryEntry> get memories => List.unmodifiable(_memories);
  Map<String, dynamic> get userProfile => Map.unmodifiable(_userProfile);

  Future<void> init() async {
    await _loadFromDB();
  }

  Future<void> _loadFromDB() async {
    final db = DatabaseService.instance;
    final raw = db.getCache(_memoryKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _memories = list
            .map((e) => MemoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _memories = [];
      }
    }

    final profileRaw = db.getCache(_profileKey);
    if (profileRaw != null) {
      try {
        _userProfile = jsonDecode(profileRaw) as Map<String, dynamic>;
      } catch (e) {
        _userProfile = {};
      }
    }
  }

  Future<void> _saveToDB() async {
    final db = DatabaseService.instance;
    await db.putCache(
      _memoryKey,
      jsonEncode(_memories.map((m) => m.toJson()).toList()),
    );
    await db.putCache(_profileKey, jsonEncode(_userProfile));
  }

  Future<void> store(
    String content, {
    String category = 'fact',
    double importance = 0.5,
  }) async {
    final id = 'mem_${DateTime.now().millisecondsSinceEpoch}';
    final entry = MemoryEntry(
      id: id,
      category: category,
      content: content,
      importance: importance,
      createdAt: DateTime.now(),
    );
    _memories.add(entry);
    final maxMem = RemoteConfigService.instance.maxMemories;
    if (_memories.length > maxMem) {
      _memories.sort((a, b) => b.importance.compareTo(a.importance));
      _memories = _memories.sublist(0, maxMem);
    }
    await _saveToDB();
  }

  Future<List<MemoryEntry>> retrieve(String query, {int maxResults = 5}) async {
    final embeddingResults = await EmbeddingService.instance.searchSimilar(
      query,
      maxResults: maxResults * 2,
      threshold: 0.3,
    );
    if (embeddingResults.isNotEmpty) {
      final keys = embeddingResults.map((e) => e.key).toSet();
      final matched = _memories
          .where(
            (m) => keys.any(
              (k) => m.content.toLowerCase().contains(k.toLowerCase()),
            ),
          )
          .toList();
      if (matched.length >= maxResults) {
        await _markAccessed(matched.take(maxResults).toList());
        return matched.take(maxResults).toList();
      }
    }

    final queryLower = query.toLowerCase();
    final scored = <MapEntry<MemoryEntry, double>>[];

    for (final mem in _memories) {
      double score = 0;
      final contentLower = mem.content.toLowerCase();
      final words = queryLower.split(RegExp(r'\s+'));
      for (final word in words) {
        if (contentLower.contains(word)) score += 1.0;
      }
      score += mem.importance * 0.5;
      score += (mem.accessCount * 0.1).clamp(0, 2.0);
      final recency = DateTime.now().difference(mem.createdAt).inHours;
      score += (24.0 / (recency + 1)).clamp(0, 1.0);

      if (score > 0) {
        scored.add(MapEntry(mem, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    final results = scored.take(maxResults).map((e) => e.key).toList();
    await _markAccessed(results);
    return results;
  }

  Future<void> _markAccessed(List<MemoryEntry> entries) async {
    bool changed = false;
    for (int i = 0; i < _memories.length; i++) {
      final mem = _memories[i];
      if (entries.any((e) => e.id == mem.id)) {
        _memories[i] = MemoryEntry(
          id: mem.id,
          category: mem.category,
          content: mem.content,
          importance: mem.importance,
          createdAt: mem.createdAt,
          lastAccessedAt: DateTime.now(),
          accessCount: mem.accessCount + 1,
        );
        changed = true;
      }
    }
    if (changed) await _saveToDB();
  }

  Future<String> buildMemoryContext(
    String query, {
    int maxTokens = 1000,
  }) async {
    final relevant = await retrieve(query);
    if (relevant.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('[用户记忆]');
    for (final mem in relevant) {
      final line = '- ${mem.content}';
      if (buffer.length + line.length > maxTokens * 4) break;
      buffer.writeln(line);
    }
    return buffer.toString();
  }

  Future<void> updateProfile(String key, dynamic value) async {
    _userProfile[key] = value;
    await _saveToDB();
  }

  List<_ExtractionPattern> _getRemotePatterns() {
    final remote = RemoteConfigService.instance.getValue<List<dynamic>>(
      'memory_extraction_patterns',
    );
    if (remote == null || remote.isEmpty) return [];
    return remote.map((item) {
      final m = item as Map<String, dynamic>;
      return _ExtractionPattern(
        RegExp(
          m['pattern'] as String? ?? '',
          caseSensitive: m['case_sensitive'] as bool? ?? true,
        ),
        m['category'] as String? ?? 'custom',
        (m['confidence'] as num?)?.toDouble() ?? 0.5,
      );
    }).toList();
  }

  Future<void> extractAndStore(String conversationContent) async {
    if (conversationContent.length > _maxInputLength) {
      conversationContent = conversationContent.substring(0, _maxInputLength);
    }

    final patterns = <_ExtractionPattern>[
      ..._getRemotePatterns(),
      _ExtractionPattern(RegExp(r'(?:我叫|我的名字是|我是)(\S+)'), 'name', 0.9),
      _ExtractionPattern(
        RegExp(
          r"(?:my name is|i'm|i am) (\w+(?:\s\w+)?)",
          caseSensitive: false,
        ),
        'name',
        0.9,
      ),
      _ExtractionPattern(RegExp(r'(?:私の名前は|私は)(\S+?)です'), 'name', 0.9),
      _ExtractionPattern(RegExp(r'(?:제 이름은|저는)(\S+?)입니다'), 'name', 0.9),
      _ExtractionPattern(RegExp(r'(?:我在|住在|来自)(\S+)'), 'location', 0.7),
      _ExtractionPattern(
        RegExp(
          r"(?:i live in|i'm from|i am from) ([\w\s]+)",
          caseSensitive: false,
        ),
        'location',
        0.7,
      ),
      _ExtractionPattern(RegExp(r'(?:私は)(\S+?)に住んでいます'), 'location', 0.7),
      _ExtractionPattern(RegExp(r'(?:저는)(\S+?)에 살고 있습니다'), 'location', 0.7),
      _ExtractionPattern(RegExp(r'(?:我喜欢|我爱|我偏好)(\S+)'), 'preference', 0.8),
      _ExtractionPattern(
        RegExp(r"(?:i like|i love|i prefer) ([\w\s]+)", caseSensitive: false),
        'preference',
        0.8,
      ),
      _ExtractionPattern(RegExp(r'(?:私は)(\S+?)が好きです'), 'preference', 0.8),
      _ExtractionPattern(RegExp(r'(?:저는)(\S+?)을 좋아합니다'), 'preference', 0.8),
      _ExtractionPattern(RegExp(r'(?:我不喜欢|我讨厌|我不爱)(\S+)'), 'dislike', 0.8),
      _ExtractionPattern(
        RegExp(
          r"(?:i don't like|i hate|i dislike) ([\w\s]+)",
          caseSensitive: false,
        ),
        'dislike',
        0.8,
      ),
      _ExtractionPattern(RegExp(r'(?:我的工作|我的职业|我是做)(\S+)'), 'occupation', 0.7),
      _ExtractionPattern(
        RegExp(r"(?:i work as|i'm a|i am a) ([\w\s]+)", caseSensitive: false),
        'occupation',
        0.7,
      ),
      _ExtractionPattern(
        RegExp(r'(?:我(?:的)?(?:手机|电话|邮箱|email)(?:是|:|：)\s*(\S+))'),
        'contact',
        0.6,
      ),
      _ExtractionPattern(
        RegExp(
          r"(?:my (?:phone|email) (?:is|:)\s*(\S+))",
          caseSensitive: false,
        ),
        'contact',
        0.6,
      ),
    ];

    for (final pattern in patterns) {
      try {
        final match = await _safeRegexMatch(pattern.regex, conversationContent);
        if (match != null) {
          final value = match.group(1);
          if (value != null && value.length < 50) {
            await store(
              '${pattern.category}: $value',
              category: pattern.category,
              importance: pattern.importance,
            );
            await updateProfile(pattern.category, value);
          }
        }
      } catch (e, stackTrace) {
        AppLogger.instance.warning(
          'Regex extraction failed for category: ${pattern.category}',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<RegExpMatch?> _safeRegexMatch(RegExp regex, String input) async {
    try {
      final result = await Isolate.run(() {
        return regex.firstMatch(input);
      }).timeout(Duration(milliseconds: _regexTimeoutMs));
      return result;
    } catch (e) {
      AppLogger.instance.warning(
        'Regex execution timed out or failed',
        error: e,
      );
      return null;
    }
  }

  Future<void> clear() async {
    _memories.clear();
    _userProfile.clear();
    await _saveToDB();
  }
}

class _ExtractionPattern {
  final RegExp regex;
  final String category;
  final double importance;
  const _ExtractionPattern(this.regex, this.category, this.importance);
}
