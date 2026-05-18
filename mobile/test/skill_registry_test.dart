import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/skills/skill_registry.dart';
import 'package:omnivium/core/agent/agent_state.dart';

void main() {
  group('SkillRegistry', () {
    test('starts empty', () {
      final registry = SkillRegistry();
      expect(registry.all, isEmpty);
    });

    test('has returns false for unknown id', () {
      final registry = SkillRegistry();
      expect(registry.has('unknown'), false);
    });

    test('get returns null for unknown id', () {
      final registry = SkillRegistry();
      expect(registry.get('unknown'), isNull);
    });

    test('findByChannel returns empty list when no skills', () {
      final registry = SkillRegistry();
      expect(registry.findByChannel(IntentChannel.fast), isEmpty);
    });

    test('findByPermission returns empty list when no skills', () {
      final registry = SkillRegistry();
      expect(registry.findByPermission(PermissionLevel.auto), isEmpty);
    });
  });
}
