import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/quick_command_cubit.dart';
import 'package:omnivium/core/quick_command_service.dart';

void main() {
  group('QuickCommandState', () {
    test('initial state has empty commands and categories', () {
      const state = QuickCommandState();
      expect(state.commands, isEmpty);
      expect(state.categories, isEmpty);
    });

    test('copyWith updates commands and categories', () {
      final cmd = QuickCommand(
        id: 'test1',
        name: 'Test',
        emoji: '🧪',
        prompt: 'Do something',
        category: 'general',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      const state = QuickCommandState();
      final updated = state.copyWith(
        commands: [cmd],
        categories: {'general'},
      );
      expect(updated.commands.length, 1);
      expect(updated.categories, {'general'});
    });

    test('copyWith preserves existing values', () {
      final cmd = QuickCommand(
        id: 'test1',
        name: 'Test',
        emoji: '🧪',
        prompt: 'Do something',
        category: 'general',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final state = QuickCommandState(
        commands: [cmd],
        categories: {'general'},
      );
      final updated = state.copyWith();
      expect(updated.commands, state.commands);
      expect(updated.categories, state.categories);
    });
  });

  group('QuickCommandCubit', () {
    late QuickCommandCubit cubit;

    setUp(() {
      cubit = QuickCommandCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is empty', () {
      expect(cubit.state.commands, isEmpty);
      expect(cubit.state.categories, isEmpty);
    });

    test('shortcut getters match state', () {
      expect(cubit.commands, cubit.state.commands);
      expect(cubit.categories, cubit.state.categories);
    });
  });
}
