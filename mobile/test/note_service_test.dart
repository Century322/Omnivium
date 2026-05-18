import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/note_service.dart';

void main() {
  group('NoteItem', () {
    test('toJson/fromJson roundtrip', () {
      final now = DateTime.now();
      final note = NoteItem(
        id: 'note_1',
        title: '测试笔记',
        content: '这是内容',
        type: NoteType.text,
        createdAt: now,
        updatedAt: now,
      );
      final json = note.toJson();
      final restored = NoteItem.fromJson(json);
      expect(restored.id, note.id);
      expect(restored.title, note.title);
      expect(restored.content, note.content);
      expect(restored.type, NoteType.text);
      expect(restored.isDone, false);
    });

    test('todo item with dueDate', () {
      final now = DateTime.now();
      final due = DateTime(2026, 6, 15, 10, 30);
      final todo = NoteItem(
        id: 'todo_1',
        title: '完成项目',
        content: '',
        type: NoteType.todo,
        isDone: false,
        dueDate: due,
        createdAt: now,
        updatedAt: now,
      );
      final json = todo.toJson();
      final restored = NoteItem.fromJson(json);
      expect(restored.type, NoteType.todo);
      expect(restored.dueDate, due);
      expect(restored.isDone, false);
    });

    test('copyWith updates fields', () {
      final now = DateTime.now();
      final note = NoteItem(
        id: 'note_1',
        title: '原标题',
        content: '原内容',
        type: NoteType.todo,
        isDone: false,
        createdAt: now,
        updatedAt: now,
      );
      final updated = note.copyWith(isDone: true, title: '新标题');
      expect(updated.id, note.id);
      expect(updated.title, '新标题');
      expect(updated.isDone, true);
      expect(updated.content, '原内容');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'note_2',
        'title': '测试',
        'content': '',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final note = NoteItem.fromJson(json);
      expect(note.type, NoteType.text);
      expect(note.isDone, false);
      expect(note.dueDate, isNull);
    });
  });
}
