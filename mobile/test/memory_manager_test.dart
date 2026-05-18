import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/memory/memory_manager.dart';

void main() {
  group('MemoryType', () {
    test('has all expected values', () {
      expect(MemoryType.values.length, 7);
      expect(MemoryType.values, contains(MemoryType.identity));
      expect(MemoryType.values, contains(MemoryType.instruction));
      expect(MemoryType.values, contains(MemoryType.preference));
      expect(MemoryType.values, contains(MemoryType.goal));
      expect(MemoryType.values, contains(MemoryType.context));
      expect(MemoryType.values, contains(MemoryType.fact));
      expect(MemoryType.values, contains(MemoryType.pattern));
    });
  });

  group('LegacyMemoryEntry', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final entry = LegacyMemoryEntry(
        id: 'lm1',
        type: MemoryType.fact,
        content: 'User prefers dark mode',
        createdAt: now,
      );
      expect(entry.id, 'lm1');
      expect(entry.type, MemoryType.fact);
      expect(entry.content, 'User prefers dark mode');
      expect(entry.importance, 0.5);
      expect(entry.confidence, 1.0);
      expect(entry.expiresAt, isNull);
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final expires = now.add(const Duration(days: 30));
      final entry = LegacyMemoryEntry(
        id: 'lm2',
        type: MemoryType.goal,
        content: 'Complete project',
        importance: 0.9,
        confidence: 0.8,
        createdAt: now,
        expiresAt: expires,
      );
      expect(entry.importance, 0.9);
      expect(entry.confidence, 0.8);
      expect(entry.expiresAt, expires);
    });

    test('default values are correct', () {
      final now = DateTime.now();
      final entry = LegacyMemoryEntry(
        id: 'lm3',
        type: MemoryType.instruction,
        content: 'Be helpful',
        createdAt: now,
      );
      expect(entry.importance, 0.5);
      expect(entry.confidence, 1.0);
      expect(entry.expiresAt, isNull);
    });
  });
}
