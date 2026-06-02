import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/model_cubit.dart';

void main() {
  group('ModelConfig', () {
    test('toJson and fromJson roundtrip', () {
      const config = ModelConfig(
        id: 'gpt-4',
        name: 'GPT-4',
        provider: 'openai',
        tier: 'smart',
      );
      final json = config.toJson();
      final restored = ModelConfig.fromJson(json);
      expect(restored.id, config.id);
      expect(restored.name, config.name);
      expect(restored.provider, config.provider);
      expect(restored.tier, config.tier);
    });

    test('fromJson defaults tier to smart', () {
      final config = ModelConfig.fromJson({
        'id': 'test',
        'name': 'Test',
      });
      expect(config.tier, 'smart');
    });
  });

  group('ModelState', () {
    test('initial state has empty models', () {
      const state = ModelState();
      expect(state.models, isEmpty);
      expect(state.activeModelId, isNull);
      expect(state.lastError, isNull);
    });

    test('activeModel returns matching model', () {
      const state = ModelState(
        models: [
          ModelConfig(id: 'a', name: 'A', provider: 'x'),
          ModelConfig(id: 'b', name: 'B', provider: 'y'),
        ],
        activeModelId: 'b',
      );
      expect(state.activeModel?.id, 'b');
      expect(state.activeModel?.name, 'B');
    });

    test('activeModel returns null when no match', () {
      const state = ModelState(
        models: [
          ModelConfig(id: 'a', name: 'A', provider: 'x'),
        ],
        activeModelId: 'z',
      );
      expect(state.activeModel, isNull);
    });

    test('activeModel returns null when activeModelId is null', () {
      const state = ModelState(
        models: [
          ModelConfig(id: 'a', name: 'A', provider: 'x'),
        ],
      );
      expect(state.activeModel, isNull);
    });

    test('copyWith preserves existing values', () {
      const state = ModelState(
        models: [ModelConfig(id: 'a', name: 'A', provider: 'x')],
        activeModelId: 'a',
      );
      final updated = state.copyWith();
      expect(updated.models, state.models);
      expect(updated.activeModelId, state.activeModelId);
    });

    test('copyWith updates error', () {
      const state = ModelState(lastError: 'old error');
      final updated = state.copyWith(lastError: 'new error');
      expect(updated.lastError, 'new error');
    });
  });
}
