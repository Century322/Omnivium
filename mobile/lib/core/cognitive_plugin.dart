import 'agent/cognitive/cognitive_engine.dart';
import 'agent/cognitive/entity_store.dart';
import 'agent/cognitive/goal_store.dart';
import 'agent/cognitive/understanding_engine.dart';
import 'agent/cognitive/cognitive_types.dart';
import 'database_service.dart';
import 'runtime/plugin/plugin_descriptor.dart';
import 'runtime/plugin/plugin_handler.dart';
import 'runtime/vocabulary/runtime_message.dart';
import 'runtime/vocabulary/runtime_event.dart';
import 'runtime/vocabulary/capability_context.dart';
import 'di/app_di.dart';
import 'omni_model.dart';

class CognitivePlugin {
  static PluginDescriptor descriptor() => PluginDescriptor(
    id: 'cognitive',
    name: 'Cognitive Engine',
    version: '1.0.0',
    description: 'AI cognitive capabilities: understanding, recall, entity management, goal tracking',
    author: 'Omnivium',
    capabilities: [
      CapabilityDeclaration(
        id: 'cognitive.understand',
        name: 'Understand',
        description: 'Analyze message with AI understanding',
        channel: 'slow',
        permission: 'auto',
        timeoutMs: 30000,
      ),
      CapabilityDeclaration(
        id: 'cognitive.recall',
        name: 'Recall',
        description: 'Recall relevant memories',
        channel: 'slow',
        permission: 'auto',
        timeoutMs: 10000,
      ),
      CapabilityDeclaration(
        id: 'cognitive.entity.query',
        name: 'Query Entities',
        description: 'Search entities by name or type',
        channel: 'fast',
        permission: 'auto',
        timeoutMs: 5000,
      ),
      CapabilityDeclaration(
        id: 'cognitive.entity.get',
        name: 'Get Entity',
        description: 'Get entity by ID',
        channel: 'fast',
        permission: 'auto',
        timeoutMs: 3000,
      ),
      CapabilityDeclaration(
        id: 'cognitive.goal.query',
        name: 'Query Goals',
        description: 'Get active goals',
        channel: 'fast',
        permission: 'auto',
        timeoutMs: 5000,
      ),
      CapabilityDeclaration(
        id: 'cognitive.goal.create',
        name: 'Create Goal',
        description: 'Create a new goal',
        channel: 'slow',
        permission: 'confirm',
        timeoutMs: 10000,
      ),
      CapabilityDeclaration(
        id: 'cognitive.context.build',
        name: 'Build Context',
        description: 'Build memory context for AI prompt',
        channel: 'slow',
        permission: 'auto',
        timeoutMs: 10000,
      ),
    ],
  );

  static CognitivePluginHandler handler() => CognitivePluginHandler();
}

class CognitivePluginHandler implements PluginHandler {
  @override
  Future<HandlerResult> handleMessage(
    RuntimeMessage message,
    CapabilityContext context,
  ) async {
    return HandlerResult.ok({'processed': true});
  }

  @override
  Future<HandlerResult> handleEvent(
    RuntimeEvent event,
    CapabilityContext context,
  ) async {
    return HandlerResult.ok({'processed': true});
  }

  @override
  Future<CapabilityResult> invokeCapability(
    String capabilityId,
    Object? params,
    CapabilityContext context,
  ) async {
    final p = params is Map<String, dynamic> ? params : <String, dynamic>{};

    try {
      switch (capabilityId) {
        case 'cognitive.understand':
          return await _handleUnderstand(p);
        case 'cognitive.recall':
          return await _handleRecall(p);
        case 'cognitive.entity.query':
          return await _handleEntityQuery(p);
        case 'cognitive.entity.get':
          return await _handleEntityGet(p);
        case 'cognitive.goal.query':
          return await _handleGoalQuery(p);
        case 'cognitive.goal.create':
          return await _handleGoalCreate(p);
        case 'cognitive.context.build':
          return await _handleContextBuild(p);
        default:
          return CapabilityResult.fail(
            RuntimeError.notFound(message: 'Unknown cognitive capability: $capabilityId'),
          );
      }
    } catch (e) {
      return CapabilityResult.fail(
        RuntimeError(code: 'COGNITIVE_ERROR', message: e.toString(), recoverable: true),
      );
    }
  }

  Future<CapabilityResult> _handleUnderstand(Map<String, dynamic> params) async {
    final message = params['message'] as String?;
    if (message == null) {
      return CapabilityResult.fail(
        RuntimeError(code: 'MISSING_PARAM', message: 'message is required'),
      );
    }
    final cognitive = getIt<CognitiveEngine>();
    final result = await cognitive.understand(message, speakerId: params['speakerId'] as String?);
    return CapabilityResult.ok(result.toJson());
  }

  Future<CapabilityResult> _handleRecall(Map<String, dynamic> params) async {
    final clue = params['clue'] as String? ?? '';
    final workspaceId = params['workspaceId'] as String?;
    final cognitive = getIt<CognitiveEngine>();
    final context = await cognitive.buildMemoryContext(
      workspaceId: workspaceId,
      understanding: null,
    );
    return CapabilityResult.ok({'context': context});
  }

  Future<CapabilityResult> _handleEntityQuery(Map<String, dynamic> params) async {
    final query = params['query'] as String?;
    final typeStr = params['type'] as String?;
    final entityStore = getIt<EntityStore>();

    if (query != null) {
      final entity = entityStore.getEntityByName(query);
      if (entity != null) {
        return CapabilityResult.ok({
          'entities': [{'name': entity.name, 'type': entity.type.name}],
        });
      }
      final byDomain = entityStore.getEntitiesByDomain(MemoryDomain.project);
      final filtered = byDomain.where((e) => e.name.toLowerCase().contains(query.toLowerCase())).toList();
      return CapabilityResult.ok({
        'entities': filtered.map((e) => {'name': e.name, 'type': e.type.name}).toList(),
      });
    }

    if (typeStr != null) {
      final type = EntityType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => EntityType.concept,
      );
      final entities = entityStore.getEntitiesByType(type);
      return CapabilityResult.ok({
        'entities': entities.map((e) => {'name': e.name, 'type': e.type.name}).toList(),
      });
    }

    return CapabilityResult.fail(
      RuntimeError(code: 'MISSING_PARAM', message: 'query or type is required'),
    );
  }

  Future<CapabilityResult> _handleEntityGet(Map<String, dynamic> params) async {
    final name = params['name'] as String?;
    if (name == null) {
      return CapabilityResult.fail(
        RuntimeError(code: 'MISSING_PARAM', message: 'name is required'),
      );
    }
    final entityStore = getIt<EntityStore>();
    final entity = entityStore.getEntityByName(name);
    if (entity == null) {
      return CapabilityResult.fail(
        RuntimeError.notFound(message: 'Entity not found: $name'),
      );
    }
    return CapabilityResult.ok({
      'name': entity.name,
      'type': entity.type.name,
    });
  }

  Future<CapabilityResult> _handleGoalQuery(Map<String, dynamic> params) async {
    final workspaceId = params['workspaceId'] as String?;
    final goalStore = getIt<GoalStore>();
    final goals = goalStore.getActiveGoals(workspaceId: workspaceId);
    return CapabilityResult.ok({
      'goals': goals.map((g) => {
        'id': g.id,
        'title': g.title,
        'progress': g.progress,
        'priority': g.priority,
        'status': g.status.name,
      }).toList(),
    });
  }

  Future<CapabilityResult> _handleGoalCreate(Map<String, dynamic> params) async {
    final title = params['title'] as String?;
    if (title == null) {
      return CapabilityResult.fail(
        RuntimeError(code: 'MISSING_PARAM', message: 'title is required'),
      );
    }
    final goalStore = getIt<GoalStore>();
    final goal = await goalStore.createGoal(
      title: title,
      workspaceId: params['workspaceId'] as String?,
    );
    return CapabilityResult.ok({
      'id': goal.id,
      'title': goal.title,
      'status': goal.status.name,
    });
  }

  Future<CapabilityResult> _handleContextBuild(Map<String, dynamic> params) async {
    final workspaceId = params['workspaceId'] as String?;
    final cognitive = getIt<CognitiveEngine>();
    final context = await cognitive.buildMemoryContext(workspaceId: workspaceId);
    return CapabilityResult.ok({'context': context});
  }
}
