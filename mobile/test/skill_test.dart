import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/skills/skill.dart';
import 'package:omnivium/core/skills/skill_registry.dart';
import 'package:omnivium/core/agent/agent_state.dart';

class _MockSkill extends Skill {
  final String _id;
  final String _name;
  final String _desc;
  final bool _isDestructive;

  _MockSkill(this._id, this._name, this._desc, {bool isDestructive = false})
    : _isDestructive = isDestructive;

  @override
  String get id => _id;
  @override
  String get name => _name;
  @override
  String get description => _desc;
  @override
  IntentChannel get channel => IntentChannel.slow;
  @override
  PermissionLevel get permission => PermissionLevel.auto;
  @override
  int get timeoutMs => 30000;
  @override
  int get maxRetries => 1;
  @override
  bool get isDestructive => _isDestructive;

  @override
  Future<SkillResult> execute(Map<String, dynamic> params) async =>
      SkillResult.ok('mock result');
}

void main() {
  group('SkillRegistry', () {
    late SkillRegistry registry;

    setUp(() {
      registry = SkillRegistry();
    });

    test('starts empty', () {
      expect(registry.all, isEmpty);
    });

    test('register adds skill', () {
      registry.register(_MockSkill('test', 'Test', 'A test skill'));
      expect(registry.all.length, 1);
      expect(registry.all.first.id, 'test');
    });

    test('get by id', () {
      registry.register(_MockSkill('search', 'Search', 'Web search'));
      final found = registry.get('search');
      expect(found, isNotNull);
      expect(found!.name, 'Search');
    });

    test('get returns null for unknown id', () {
      expect(registry.get('unknown'), isNull);
    });

    test('unregister removes skill', () {
      registry.register(_MockSkill('test', 'Test', 'A test skill'));
      registry.unregister('test');
      expect(registry.all, isEmpty);
    });

    test('register multiple skills', () {
      registry.register(_MockSkill('a', 'A', 'Skill A'));
      registry.register(_MockSkill('b', 'B', 'Skill B'));
      registry.register(_MockSkill('c', 'C', 'Skill C'));
      expect(registry.all.length, 3);
    });

    test('register same id replaces', () {
      registry.register(_MockSkill('test', 'V1', 'Version 1'));
      registry.register(_MockSkill('test', 'V2', 'Version 2'));
      expect(registry.all.length, 1);
      expect(registry.all.first.name, 'V2');
    });
  });

  group('SkillResult', () {
    test('ok result', () {
      final result = SkillResult.ok('data');
      expect(result.success, true);
      expect(result.data, 'data');
      expect(result.error, isNull);
    });

    test('fail result', () {
      final result = SkillResult.fail('error msg');
      expect(result.success, false);
      expect(result.error, 'error msg');
      expect(result.data, isNull);
    });
  });

  group('RemoteSkill', () {
    test('properties', () {
      final skill = RemoteSkill(
        id: 'remote1',
        name: 'Remote',
        description: 'A remote skill',
        endpoint: '/api/skill',
      );
      expect(skill.id, 'remote1');
      expect(skill.name, 'Remote');
      expect(skill.channel, IntentChannel.slow);
      expect(skill.permission, PermissionLevel.auto);
      expect(skill.isDestructive, false);
      expect(skill.timeoutMs, 30000);
    });
  });
}
