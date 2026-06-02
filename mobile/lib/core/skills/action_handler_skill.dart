import 'skill.dart';
import '../omni_model.dart';
import '../omni_objects.dart';
import '../action_executor.dart';
import '../app_logger.dart';

class ActionHandlerSkill extends Skill {
  final String actionId;
  final OmniObjectType objectType;
  final String _name;
  final String _description;
  @override
  final PermissionLevel permission;
  @override
  final bool isDestructive;

  ActionHandlerSkill({
    required this.actionId,
    required this.objectType,
    required String name,
    required String description,
    this.permission = PermissionLevel.auto,
    this.isDestructive = false,
  })  : _name = name,
        _description = description;

  @override
  String get id => actionId;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  IntentChannel get channel => isDestructive ? IntentChannel.slow : IntentChannel.fast;

  @override
  int get timeoutMs => 15000;

  @override
  int get maxRetries => 1;

  @override
  Future<SkillResult> execute(Map<String, dynamic> params) async {
    try {
      final objectId = params['objectId'] as String? ?? '';
      final registry = OmniObjectRegistry.instance;
      var target = registry.getObject(objectId) ?? registry.findObject(objectId);

      if (target == null) {
        return SkillResult.fail('Object not found: $objectId');
      }

      final action = OmniAction(
        id: actionId,
        name: name,
        description: description,
        objectTypeId: objectType.name,
        capabilityId: actionId,
        isDestructive: isDestructive,
        permission: permission.name,
      );

      final result = await ActionExecutor.instance.execute(action, target, params);
      if (result.success) {
        return SkillResult.ok(result.data);
      }
      return SkillResult.fail(result.error ?? 'Action failed');
    } catch (e) {
      AppLogger.instance.warning('ActionHandlerSkill execute failed', error: e);
      return SkillResult.fail(e.toString());
    }
  }
}
