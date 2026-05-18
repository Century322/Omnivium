import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/quick_command_service.dart';

void main() {
  group('QuickCommand', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final cmd = QuickCommand(
        id: 'cmd_1',
        name: 'Translate',
        prompt: 'Translate the following text',
        emoji: '🌐',
        category: 'utility',
        createdAt: now,
        updatedAt: now,
      );
      expect(cmd.id, 'cmd_1');
      expect(cmd.name, 'Translate');
      expect(cmd.prompt, 'Translate the following text');
      expect(cmd.emoji, '🌐');
      expect(cmd.category, 'utility');
    });

    test('toJson returns correct map', () {
      final now = DateTime(2025, 1, 1);
      final cmd = QuickCommand(
        id: 'c1',
        name: 'Summarize',
        prompt: 'Summarize this',
        emoji: '📝',
        category: 'writing',
        createdAt: now,
        updatedAt: now,
      );
      final json = cmd.toJson();
      expect(json['id'], 'c1');
      expect(json['name'], 'Summarize');
      expect(json['prompt'], 'Summarize this');
      expect(json['emoji'], '📝');
      expect(json['category'], 'writing');
    });

    test('fromJson creates correct command', () {
      final json = {
        'id': 'c2',
        'name': 'Code Review',
        'prompt': 'Review this code',
        'emoji': '💻',
        'category': 'coding',
        'createdAt': DateTime(2025, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2025, 1, 1).toIso8601String(),
      };
      final cmd = QuickCommand.fromJson(json);
      expect(cmd.id, 'c2');
      expect(cmd.name, 'Code Review');
      expect(cmd.category, 'coding');
    });

    test('copyWith modifies specified fields', () {
      final now = DateTime.now();
      final cmd = QuickCommand(
        id: 'cw',
        name: 'Original',
        prompt: 'Original prompt',
        emoji: '⚡',
        createdAt: now,
        updatedAt: now,
      );
      final modified = cmd.copyWith(name: 'Modified', category: 'test');
      expect(modified.id, 'cw');
      expect(modified.name, 'Modified');
      expect(modified.prompt, 'Original prompt');
      expect(modified.category, 'test');
    });

    test('default category is general', () {
      final now = DateTime.now();
      final cmd = QuickCommand(
        id: 'd1',
        name: 'Default',
        prompt: 'Prompt',
        emoji: '⚡',
        createdAt: now,
        updatedAt: now,
      );
      expect(cmd.category, 'general');
    });
  });
}
