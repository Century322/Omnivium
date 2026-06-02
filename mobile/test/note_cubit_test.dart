import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/note_cubit.dart';
import 'package:omnivium/core/note_service.dart';

void main() {
  group('NoteState', () {
    test('initial state has empty items', () {
      const state = NoteState();
      expect(state.items, isEmpty);
    });

    test('notes filters by text type', () {
      final items = [
        NoteItem(
          id: '1',
          title: 'Note',
          content: 'Content',
          type: NoteType.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NoteItem(
          id: '2',
          title: 'Todo',
          content: 'Content',
          type: NoteType.todo,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final state = NoteState(items: items);
      expect(state.notes.length, 1);
      expect(state.notes.first.type, NoteType.text);
    });

    test('todos filters by todo type', () {
      final items = [
        NoteItem(
          id: '1',
          title: 'Note',
          content: 'Content',
          type: NoteType.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NoteItem(
          id: '2',
          title: 'Todo',
          content: 'Content',
          type: NoteType.todo,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final state = NoteState(items: items);
      expect(state.todos.length, 1);
      expect(state.todos.first.type, NoteType.todo);
    });

    test('schedules filters by schedule type', () {
      final items = [
        NoteItem(
          id: '1',
          title: 'Schedule',
          content: 'Content',
          type: NoteType.schedule,
          dueDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final state = NoteState(items: items);
      expect(state.schedules.length, 1);
    });

    test('pendingTodos filters incomplete todos', () {
      final items = [
        NoteItem(
          id: '1',
          title: 'Done',
          content: '',
          type: NoteType.todo,
          isDone: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NoteItem(
          id: '2',
          title: 'Pending',
          content: '',
          type: NoteType.todo,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final state = NoteState(items: items);
      expect(state.pendingTodos.length, 1);
      expect(state.pendingTodos.first.isDone, false);
    });

    test('copyWith preserves existing values', () {
      final item = NoteItem(
        id: '1',
        title: 'Note',
        content: 'Content',
        type: NoteType.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final state = NoteState(items: [item]);
      final updated = state.copyWith();
      expect(updated.items, state.items);
    });
  });
}
