import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/agent/agent_memory_service.dart';

void main() {
  group('MemoryEntry', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final entry = MemoryEntry(
        id: 'mem_1',
        category: 'preference',
        content: 'User likes dark mode',
        createdAt: now,
      );
      expect(entry.id, 'mem_1');
      expect(entry.category, 'preference');
      expect(entry.content, 'User likes dark mode');
      expect(entry.importance, 0.5);
      expect(entry.accessCount, 0);
      expect(entry.lastAccessedAt, isNull);
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final accessed = now.subtract(const Duration(hours: 1));
      final entry = MemoryEntry(
        id: 'mem_2',
        category: 'fact',
        content: 'User is a developer',
        importance: 0.9,
        createdAt: now,
        lastAccessedAt: accessed,
        accessCount: 5,
      );
      expect(entry.importance, 0.9);
      expect(entry.accessCount, 5);
      expect(entry.lastAccessedAt, accessed);
    });

    test('toJson returns correct map', () {
      final now = DateTime(2025, 1, 1);
      final entry = MemoryEntry(
        id: 't1',
        category: 'goal',
        content: 'Learn Flutter',
        importance: 0.8,
        createdAt: now,
        accessCount: 3,
      );
      final json = entry.toJson();
      expect(json['id'], 't1');
      expect(json['category'], 'goal');
      expect(json['importance'], 0.8);
      expect(json['accessCount'], 3);
      expect(json['lastAccessedAt'], isNull);
    });

    test('fromJson creates correct entry', () {
      final now = DateTime(2025, 1, 1);
      final json = {
        'id': 'f1',
        'category': 'instruction',
        'content': 'Be concise',
        'importance': 0.7,
        'createdAt': now.toIso8601String(),
        'accessCount': 2,
      };
      final entry = MemoryEntry.fromJson(json);
      expect(entry.id, 'f1');
      expect(entry.category, 'instruction');
      expect(entry.importance, 0.7);
      expect(entry.accessCount, 2);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'f2',
        'category': 'context',
        'content': 'Test',
        'createdAt': DateTime(2025, 1, 1).toIso8601String(),
      };
      final entry = MemoryEntry.fromJson(json);
      expect(entry.importance, 0.5);
      expect(entry.accessCount, 0);
      expect(entry.lastAccessedAt, isNull);
    });

    test('fromJson handles int importance as double', () {
      final json = {
        'id': 'f3',
        'category': 'test',
        'content': 'Test',
        'importance': 1,
        'createdAt': DateTime(2025, 1, 1).toIso8601String(),
      };
      final entry = MemoryEntry.fromJson(json);
      expect(entry.importance, 1.0);
    });

    test('toJson/fromJson round-trip', () {
      final now = DateTime(2025, 6, 15);
      final entry = MemoryEntry(
        id: 'rt',
        category: 'pattern',
        content: 'User asks about code',
        importance: 0.6,
        createdAt: now,
        lastAccessedAt: now,
        accessCount: 10,
      );
      final json = entry.toJson();
      final restored = MemoryEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.category, entry.category);
      expect(restored.content, entry.content);
      expect(restored.importance, entry.importance);
      expect(restored.accessCount, entry.accessCount);
    });
  });
}
