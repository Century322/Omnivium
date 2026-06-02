import 'skills/skill.dart';
import 'skills/skill_registry.dart';
import 'runtime/sdk/omnivium_sdk.dart';
import 'runtime/plugin/plugin_descriptor.dart';
import 'runtime/plugin/plugin_handler.dart';
import 'runtime/vocabulary/runtime_message.dart';
import 'runtime/vocabulary/runtime_event.dart';
import 'runtime/vocabulary/capability_context.dart';
import 'tool_memory.dart';
import 'database_service.dart';
import 'di/app_di.dart';
import 'app_logger.dart';

class SkillBridge {
  static Future<void> registerSkillsAsPlugins() async {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;

    final skillRegistry = getIt<SkillRegistry>();
    final toolMemory = getIt<ToolMemory>();
    if (!toolMemory.isInitialized) await toolMemory.init();

    for (final skill in skillRegistry.all) {
      try {
        final descriptor = PluginDescriptor(
          id: 'skill_${skill.id}',
          name: skill.name,
          version: skill.version.toString(),
          description: skill.description,
          author: 'Omnivium',
          capabilities: [
            CapabilityDeclaration(
              id: 'skill.${skill.id}',
              name: skill.name,
              description: skill.description,
              channel: skill.channel.name,
              permission: skill.permission.name,
              timeoutMs: skill.timeoutMs,
              maxRetries: skill.maxRetries,
              isDestructive: skill.isDestructive,
            ),
          ],
        );

        final handler = _SkillPluginHandler(skill, toolMemory);
        await sdk.container.registerPlugin(descriptor, handler);
        await sdk.container.activatePlugin(descriptor.id);
      } catch (e, st) {
        AppLogger.instance.error(
          'SkillBridge: failed to register skill ${skill.id}',
          error: e,
          stackTrace: st,
        );
      }
    }
    AppLogger.instance.info('SkillBridge: ${skillRegistry.all.length} skills registered as plugins');
  }
}

class _SkillPluginHandler implements PluginHandler {
  final Skill _skill;
  final ToolMemory _toolMemory;

  _SkillPluginHandler(this._skill, this._toolMemory);

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
    final stopwatch = Stopwatch()..start();
    final paramMap = params is Map<String, dynamic> ? params : <String, dynamic>{};

    try {
      final result = await _skill.execute(paramMap);
      stopwatch.stop();

      await _toolMemory.record(ToolUsageRecord(
        toolId: _skill.id,
        capabilityId: capabilityId,
        success: result.success,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
        error: result.error?.toString(),
        context: paramMap,
      ));

      if (result.success) {
        return CapabilityResult.ok(result.data);
      } else {
        return CapabilityResult.fail(
          RuntimeError(code: 'SKILL_ERROR', message: result.error?.toString() ?? 'Unknown error', recoverable: true),
        );
      }
    } catch (e) {
      stopwatch.stop();
      await _toolMemory.record(ToolUsageRecord(
        toolId: _skill.id,
        capabilityId: capabilityId,
        success: false,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
        error: e.toString(),
        context: paramMap,
      ));
      return CapabilityResult.fail(
        RuntimeError(code: 'SKILL_EXCEPTION', message: e.toString(), recoverable: true),
      );
    }
  }
}
