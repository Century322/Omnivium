import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/capability_context.dart';
import 'persistence_backend.dart';

class MemoryEntry {
  final String id;
  final String content;
  final String category;
  final double importance;
  final int createdAt;
  final Map<String, dynamic> metadata;

  const MemoryEntry({
    required this.id,
    required this.content,
    this.category = 'general',
    this.importance = 0.5,
    required this.createdAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'category': category,
        'importance': importance,
        'createdAt': createdAt,
        'metadata': metadata,
      };

  factory MemoryEntry.fromJson(Map<String, dynamic> json) => MemoryEntry(
        id: json['id'] as String,
        content: json['content'] as String,
        category: json['category'] as String? ?? 'general',
        importance: (json['importance'] as num?)?.toDouble() ?? 0.5,
        createdAt: json['createdAt'] as int,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );
}

class MemoryPlugin implements PluginHandler {
  final Map<String, MemoryEntry> _memories = {};
  final PersistenceBackend? _persistence;
  int _idCounter = 0;
  bool _loaded = false;

  MemoryPlugin({PersistenceBackend? persistence}) : _persistence = persistence;

  Future<void> loadFromPersistence() async {
    if (_persistence == null || _loaded) return;
    final keys = await _persistence.listKeys('mem_');
    for (final key in keys) {
      final data = await _persistence.read(key);
      if (data != null) {
        final entry = MemoryEntry.fromJson(data);
        _memories[entry.id] = entry;
        final counterPart = entry.id.replaceFirst('mem_', '');
        final counterVal = int.tryParse(counterPart);
        if (counterVal != null && counterVal >= _idCounter) {
          _idCounter = counterVal + 1;
        }
      }
    }
    _loaded = true;
  }

  @override
  Future<HandlerResult> handleMessage(RuntimeMessage message, CapabilityContext context) async {
    return HandlerResult.ok();
  }

  @override
  Future<HandlerResult> handleEvent(RuntimeEvent event, CapabilityContext context) async {
    return HandlerResult.ok();
  }

  @override
  Future<CapabilityResult> invokeCapability(String capabilityId, dynamic params, CapabilityContext context) async {
    if (!_loaded) await loadFromPersistence();
    switch (capabilityId) {
      case 'memory.read':
        return _handleRead(params);
      case 'memory.write':
        return await _handleWrite(params);
      case 'memory.search':
        return _handleSearch(params);
      case 'memory.embed':
        return _handleEmbed(params);
      default:
        return CapabilityResult.fail(
          RuntimeError(code: 'UNKNOWN_CAPABILITY', message: 'Unknown capability: $capabilityId'),
        );
    }
  }

  CapabilityResult _handleRead(dynamic params) {
    final id = params is Map ? params['id'] as String : params as String;
    final entry = _memories[id];
    if (entry == null) {
      return CapabilityResult.fail(
        RuntimeError(code: 'NOT_FOUND', message: 'Memory not found: $id'),
      );
    }
    return CapabilityResult.ok(entry.toJson());
  }

  Future<CapabilityResult> _handleWrite(dynamic params) async {
    if (params is! Map) {
      return CapabilityResult.fail(const RuntimeError(code: 'INVALID_PARAMS', message: 'Expected {content, category?, importance?}'));
    }

    final id = 'mem_${_idCounter++}';
    final entry = MemoryEntry(
      id: id,
      content: params['content'] as String,
      category: params['category'] as String? ?? 'general',
      importance: (params['importance'] as num?)?.toDouble() ?? 0.5,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      metadata: (params['metadata'] as Map<String, dynamic>?) ?? {},
    );

    _memories[id] = entry;
    if (_persistence != null) {
      await _persistence.write(id, entry.toJson());
    }
    return CapabilityResult.ok({'id': id, 'created': true});
  }

  CapabilityResult _handleSearch(dynamic params) {
    final query = params is Map ? params['query'] as String : params as String;
    final category = params is Map ? params['category'] as String? : null;

    var results = _memories.values.where((m) {
      final matchesContent = m.content.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = category == null || m.category == category;
      return matchesContent && matchesCategory;
    }).toList();

    results.sort((a, b) => b.importance.compareTo(a.importance));

    return CapabilityResult.ok({
      'query': query,
      'count': results.length,
      'results': results.take(20).map((m) => m.toJson()).toList(),
    });
  }

  CapabilityResult _handleEmbed(dynamic params) {
    final id = params is Map ? params['id'] as String : params as String;
    final entry = _memories[id];
    if (entry == null) {
      return CapabilityResult.fail(
        RuntimeError(code: 'NOT_FOUND', message: 'Memory not found: $id'),
      );
    }
    return CapabilityResult.ok({
      'id': id,
      'embedding': List.generate(8, (i) => ((entry.content.hashCode >> (i * 4)) & 0xFF) / 255.0),
      'dimensions': 8,
    });
  }

  static PluginDescriptor descriptor() => PluginDescriptor(
        id: 'memory',
        name: 'Memory Plugin',
        version: '1.0.0',
        description: 'AI memory management with read/write/search/embed',
        capabilities: const [
          CapabilityDeclaration(
            id: 'memory.read',
            name: 'Read',
            description: 'Read a memory by ID',
            permission: 'auto',
          ),
          CapabilityDeclaration(
            id: 'memory.write',
            name: 'Write',
            description: 'Write a new memory',
            permission: 'confirm',
          ),
          CapabilityDeclaration(
            id: 'memory.search',
            name: 'Search',
            description: 'Search memories by content',
            permission: 'auto',
          ),
          CapabilityDeclaration(
            id: 'memory.embed',
            name: 'Embed',
            description: 'Get embedding for a memory',
            permission: 'auto',
          ),
        ],
      );
}
