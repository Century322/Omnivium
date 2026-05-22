import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/quick_command_service.dart';

void main() {
  group('QuickCommand', () {
    test('toJson/fromJson roundtrip', () {
      final now = DateTime.now();
      final cmd = QuickCommand(
        id: 'test_1',
        name: '搜索',
        emoji: '🔍',
        prompt: '帮我搜索最新的',
        category: 'tool',
        createdAt: now,
        updatedAt: now,
      );
      final json = cmd.toJson();
      final restored = QuickCommand.fromJson(json);
      expect(restored.id, cmd.id);
      expect(restored.name, cmd.name);
      expect(restored.emoji, cmd.emoji);
      expect(restored.prompt, cmd.prompt);
      expect(restored.category, cmd.category);
    });

    test('copyWith updates fields', () {
      final now = DateTime.now();
      final cmd = QuickCommand(
        id: 'test_1',
        name: '搜索',
        emoji: '🔍',
        prompt: '帮我搜索最新的',
        category: 'tool',
        createdAt: now,
        updatedAt: now,
      );
      final updated = cmd.copyWith(name: '翻译', emoji: '🌐', prompt: '翻译成英文：');
      expect(updated.id, cmd.id);
      expect(updated.name, '翻译');
      expect(updated.emoji, '🌐');
      expect(updated.prompt, '翻译成英文：');
      expect(updated.category, 'tool');
      expect(updated.createdAt, cmd.createdAt);
      expect(
        updated.updatedAt.isAfter(cmd.updatedAt) ||
            updated.updatedAt == cmd.updatedAt,
        isTrue,
      );
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'test_2',
        'name': '测试',
        'prompt': '测试指令',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final cmd = QuickCommand.fromJson(json);
      expect(cmd.emoji, '⚡');
      expect(cmd.category, 'general');
    });
  });
}
