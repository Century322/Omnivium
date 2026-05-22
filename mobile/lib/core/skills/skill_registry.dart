import 'skill.dart';
import '../agent/agent_state.dart';
import '../app_logger.dart';

class SkillRegistry {
  final Map<String, Skill> _skills = {};

  void register(Skill skill) {
    if (_skills.containsKey(skill.id)) {
      AppLogger.instance.warning(
        'Skill "${skill.id}" re-registered, overwriting previous registration',
      );
    }
    _skills[skill.id] = skill;
  }

  void unregister(String id) {
    _skills.remove(id);
  }

  Skill? get(String id) => _skills[id];

  List<Skill> get all => _skills.values.toList();

  List<Skill> findByChannel(IntentChannel channel) {
    return _skills.values.where((s) => s.channel == channel).toList();
  }

  List<Skill> findByPermission(PermissionLevel permission) {
    return _skills.values.where((s) => s.permission == permission).toList();
  }

  bool has(String id) => _skills.containsKey(id);

  void clear() => _skills.clear();
}
