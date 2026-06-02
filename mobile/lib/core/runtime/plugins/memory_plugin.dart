import '../../agent/cognitive/cognitive_engine.dart';
import '../../agent/cognitive/memory_event.dart';
import '../../agent/cognitive/recall_engine.dart';
import '../../di/app_di.dart';
import '../plugin/plugin_descriptor.dart';
import '../plugin/plugin_handler.dart';
import '../vocabulary/runtime_message.dart';
import '../vocabulary/runtime_event.dart';
import '../vocabulary/capability_context.dart';
import 'persistence_backend.dart';
import '../vocabulary/capability_params.dart';

class MemoryPlugin implements PluginHandler {
  final Map<String, Map<String, dynamic>> _legacyMemories = {};
  final PersistenceBackend? _persistence;
  int _idCounter = 0;
  bool _loaded = false;

  MemoryPlugin({PersistenceBackend? persistence}) : _persistence = persistence;

  CognitiveEngine? get _cognitive {
    try {
      return getIt<CognitiveEngine>();
    } catch (_) {
      return null;
    }
  }

  Future<void> loadFromPersistence() async {
    if (_persistence == null || _loaded) return;
    final keys = await _persistence.listKeys('mem_');
    for (final key in keys) {
      final data = await _persistence.read(key);
      if (data != null) {
        _legacyMemories[key] = data as Map<String, dynamic>;
        final counterPart = key.replaceFirst('mem_', '');
        final counterVal = int.tryParse(counterPart);
        if (counterVal != null && counterVal >= _idCounter) {
          _idCounter = counterVal + 1;
        }
      }
    }
    _loaded = true;
  }

  @override
  Future<HandlerResult> handleMessage(
    RuntimeMessage message,
    CapabilityContext context) async {
    return HandlerResult.ok();
  }

  @override
  Future<HandlerResult> handleEvent(
    RuntimeEvent event,
    CapabilityContext context) async {
    return HandlerResult.ok();
  }

  @override
  Future<CapabilityResult> invokeCapability(
    String capabilityId,
    CapabilityParams params,
    CapabilityContext context) async {
    if (!_loaded) await loadFromPersistence();

    final cognitive = _cognitive;
    if (cognitive != null) {
      return _handleWithCognitive(capabilityId, params, cognitive);
    }

    return _handleLegacy(capabilityId, params);
  }

  Future<CapabilityResult> _handleWithCognitive(
    String capabilityId,
    CapabilityParams params,
    CognitiveEngine cognitive,
  ) async {
    switch (capabilityId) {
      case 'memory.read':
        return _cognitiveRead(params, cognitive);
      case 'memory.write':
        return await _cognitiveWrite(params, cognitive);
      case 'memory.search':
        return await _cognitiveSearch(params, cognitive);
      case 'memory.embed':
        return _cognitiveEmbed(params, cognitive);
      default:
        return CapabilityResult.fail(
          RuntimeError(
            code: 'UNKNOWN_CAPABILITY',
            message: 'Unknown capability: $capabilityId'));
    }
  }

  CapabilityResult _cognitiveRead(CapabilityParams params, CognitiveEngine cognitive) {
    final id = params.string('id') ?? params.string('value') ?? '';

    for (final event in cognitive.events) {
      if (event.id == id) {
        return CapabilityResult.ok({
          'id': event.id,
          'content': event.summary,
          'category': event.memoryType.name,
          'importance': event.importance / 100.0,
          'createdAt': event.timestamp.millisecondsSinceEpoch,
          'metadata': {
            'intent': event.intent.name,
            'domain': event.domain.name,
            'persistence': event.persistence.name,
            'lifecycle': event.lifecycle.name,
            ...event.properties,
          },
        });
      }
    }

    final legacy = _legacyMemories[id];
    if (legacy != null) {
      return CapabilityResult.ok(legacy);
    }

    return CapabilityResult.fail(
      RuntimeError(code: 'NOT_FOUND', message: 'Memory not found: $id'));
  }

  Future<CapabilityResult> _cognitiveWrite(CapabilityParams params, CognitiveEngine cognitive) async {
    if (!params.has('content')) {
      return CapabilityResult.fail(
        const RuntimeError(
          code: 'INVALID_PARAMS',
          message: 'Expected {content, category?, importance?}'));
    }

    final content = params.string('content')!;
    final importance = params.doubleOr('importance', 0.5) * 100;

    final event = await cognitive.processMessage(
      content,
      db: getIt(),
    );

    if (event == null) {
      final id = 'mem_${_idCounter++}';
      _legacyMemories[id] = {
        'id': id,
        'content': content,
        'category': params.stringOr('category', 'general'),
        'importance': params.doubleOr('importance', 0.5),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'metadata': params.map('metadata') ?? {},
      };
      return CapabilityResult.ok({'id': id, 'created': true});
    }

    return CapabilityResult.ok({'id': event.id, 'created': true});
  }

  Future<CapabilityResult> _cognitiveSearch(CapabilityParams params, CognitiveEngine cognitive) async {
    final query = params.string('query') ?? params.string('value') ?? '';

    final recallQuery = RecallQuery(
      clue: query,
      minImportance: 20,
    );

    final result = await cognitive.recall(recallQuery);

    final results = result.events.map((event) => {
      'id': event.id,
      'content': event.summary,
      'category': event.memoryType.name,
      'importance': event.importance / 100.0,
      'createdAt': event.timestamp.millisecondsSinceEpoch,
      'metadata': {
        'intent': event.intent.name,
        'domain': event.domain.name,
        ...event.properties,
      },
    }).toList();

    return CapabilityResult.ok({
      'query': query,
      'count': results.length,
      'results': results,
    });
  }

  CapabilityResult _cognitiveEmbed(CapabilityParams params, CognitiveEngine cognitive) {
    final id = params.string('id') ?? params.string('value') ?? '';

    for (final event in cognitive.events) {
      if (event.id == id) {
        return CapabilityResult.ok({
          'id': id,
          'embedding': List.generate(
            8,
            (i) => ((event.summary.hashCode >> (i * 4)) & 0xFF) / 255.0),
          'dimensions': 8,
        });
      }
    }

    return CapabilityResult.fail(
      RuntimeError(code: 'NOT_FOUND', message: 'Memory not found: $id'));
  }

  CapabilityResult _handleLegacy(String capabilityId, CapabilityParams params) {
    switch (capabilityId) {
      case 'memory.read':
        final id = params.string('id') ?? params.string('value') ?? '';
        final entry = _legacyMemories[id];
        if (entry == null) {
          return CapabilityResult.fail(
            RuntimeError(code: 'NOT_FOUND', message: 'Memory not found: $id'));
        }
        return CapabilityResult.ok(entry);
      case 'memory.write':
        if (!params.has('content')) {
          return CapabilityResult.fail(
            const RuntimeError(
              code: 'INVALID_PARAMS',
              message: 'Expected {content, category?, importance?}'));
        }
        final id = 'mem_${_idCounter++}';
        _legacyMemories[id] = {
          'id': id,
          'content': params.string('content')!,
          'category': params.stringOr('category', 'general'),
          'importance': params.doubleOr('importance', 0.5),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'metadata': params.map('metadata') ?? {},
        };
        return CapabilityResult.ok({'id': id, 'created': true});
      case 'memory.search':
        final query = params.string('query') ?? params.string('value') ?? '';
        final results = _legacyMemories.values.where((m) {
          final content = (m['content'] as String?) ?? '';
          return content.toLowerCase().contains(query.toLowerCase());
        }).toList()
          ..sort((a, b) => ((b['importance'] as num?)?.toDouble() ?? 0.5)
              .compareTo((a['importance'] as num?)?.toDouble() ?? 0.5));
        return CapabilityResult.ok({
          'query': query,
          'count': results.length,
          'results': results.take(20),
        });
      case 'memory.embed':
        final id = params.string('id') ?? params.string('value') ?? '';
        final entry = _legacyMemories[id];
        if (entry == null) {
          return CapabilityResult.fail(
            RuntimeError(code: 'NOT_FOUND', message: 'Memory not found: $id'));
        }
        final content = (entry['content'] as String?) ?? '';
        return CapabilityResult.ok({
          'id': id,
          'embedding': List.generate(
            8,
            (i) => ((content.hashCode >> (i * 4)) & 0xFF) / 255.0),
          'dimensions': 8,
        });
      default:
        return CapabilityResult.fail(
          RuntimeError(
            code: 'UNKNOWN_CAPABILITY',
            message: 'Unknown capability: $capabilityId'));
    }
  }

  static PluginDescriptor descriptor() => PluginDescriptor(
    id: 'memory',
    name: 'Memory Plugin',
    version: '2.0.0',
    description: 'AI memory management powered by CognitiveEngine',
    capabilities: const [
      CapabilityDeclaration(
        id: 'memory.read',
        name: 'Read',
        description: 'Read a memory by ID',
        permission: 'auto'),
      CapabilityDeclaration(
        id: 'memory.write',
        name: 'Write',
        description: 'Write a new memory via CognitiveEngine',
        permission: 'confirm'),
      CapabilityDeclaration(
        id: 'memory.search',
        name: 'Search',
        description: 'Search memories using RecallEngine',
        permission: 'auto'),
      CapabilityDeclaration(
        id: 'memory.embed',
        name: 'Embed',
        description: 'Get embedding for a memory',
        permission: 'auto'),
    ]);
}
