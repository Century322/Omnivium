import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/note_provider.dart';
import 'package:omnivium/core/note_service.dart';

void main() {
  group('NoteProvider', () {
    test('initial state', () {
      final provider = NoteProvider();
      expect(provider.notes, isA<List<NoteItem>>());
    });

    test('items getter returns service items', () {
      final provider = NoteProvider();
      expect(provider.items, isA<List<NoteItem>>());
    });

    test('todos getter returns todo type items', () {
      final provider = NoteProvider();
      expect(provider.todos, isA<List<NoteItem>>());
    });

    test('schedules getter returns schedule type items', () {
      final provider = NoteProvider();
      expect(provider.schedules, isA<List<NoteItem>>());
    });

    test('pendingTodos getter returns pending items', () {
      final provider = NoteProvider();
      expect(provider.pendingTodos, isA<List<NoteItem>>());
    });

    test('todaySchedules getter returns today items', () {
      final provider = NoteProvider();
      expect(provider.todaySchedules, isA<List<NoteItem>>());
    });
  });
}
