import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/note_service.dart';

void main() {
  group('NoteItem', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final item = NoteItem(
        id: 'note_1',
        title: 'Test Note',
        content: 'Hello world',
        type: NoteType.text,
        createdAt: now,
        updatedAt: now,
      );
      expect(item.id, 'note_1');
      expect(item.title, 'Test Note');
      expect(item.content, 'Hello world');
      expect(item.type, NoteType.text);
      expect(item.isDone, false);
      expect(item.dueDate, isNull);
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final due = now.add(const Duration(days: 1));
      final item = NoteItem(
        id: 'todo_1',
        title: 'Buy milk',
        content: 'From supermarket',
        type: NoteType.todo,
        isDone: true,
        dueDate: due,
        createdAt: now,
        updatedAt: now,
      );
      expect(item.type, NoteType.todo);
      expect(item.isDone, true);
      expect(item.dueDate, due);
    });

    test('toJson returns correct map', () {
      final now = DateTime(2025, 1, 1);
      final item = NoteItem(
        id: 'n1',
        title: 'Title',
        content: 'Content',
        type: NoteType.schedule,
        createdAt: now,
        updatedAt: now,
      );
      final json = item.toJson();
      expect(json['id'], 'n1');
      expect(json['title'], 'Title');
      expect(json['content'], 'Content');
      expect(json['type'], NoteType.schedule.index);
      expect(json['isDone'], false);
      expect(json['dueDate'], isNull);
    });

    test('fromJson creates correct item', () {
      final now = DateTime(2025, 1, 1);
      final json = {
        'id': 'n2',
        'title': 'Restored',
        'content': 'From JSON',
        'type': 1,
        'isDone': true,
        'dueDate': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      final item = NoteItem.fromJson(json);
      expect(item.id, 'n2');
      expect(item.title, 'Restored');
      expect(item.type, NoteType.todo);
      expect(item.isDone, true);
      expect(item.dueDate, isNotNull);
    });

    test('toJson and fromJson round-trip', () {
      final now = DateTime(2025, 6, 15);
      final item = NoteItem(
        id: 'rt',
        title: 'Round Trip',
        content: 'Test',
        type: NoteType.todo,
        isDone: true,
        dueDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final json = item.toJson();
      final restored = NoteItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.content, item.content);
      expect(restored.type, item.type);
      expect(restored.isDone, item.isDone);
    });

    test('copyWith modifies specified fields', () {
      final now = DateTime.now();
      final item = NoteItem(
        id: 'cw',
        title: 'Original',
        content: 'Original content',
        type: NoteType.text,
        createdAt: now,
        updatedAt: now,
      );
      final modified = item.copyWith(title: 'Modified', isDone: true);
      expect(modified.id, 'cw');
      expect(modified.title, 'Modified');
      expect(modified.content, 'Original content');
      expect(modified.isDone, true);
      expect(modified.type, NoteType.text);
    });

    test('copyWith without args returns identical item', () {
      final now = DateTime.now();
      final item = NoteItem(
        id: 'same',
        title: 'Same',
        content: 'Same',
        createdAt: now,
        updatedAt: now,
      );
      final copy = item.copyWith();
      expect(copy.id, item.id);
      expect(copy.title, item.title);
      expect(copy.content, item.content);
      expect(copy.isDone, item.isDone);
    });

    test('NoteType enum has correct values', () {
      expect(NoteType.values.length, 3);
      expect(NoteType.values[0], NoteType.text);
      expect(NoteType.values[1], NoteType.todo);
      expect(NoteType.values[2], NoteType.schedule);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'n3',
        'title': 'Minimal',
        'createdAt': DateTime(2025, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2025, 1, 1).toIso8601String(),
      };
      final item = NoteItem.fromJson(json);
      expect(item.content, '');
      expect(item.type, NoteType.text);
      expect(item.isDone, false);
      expect(item.dueDate, isNull);
    });
  });
}
