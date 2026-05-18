import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/model_provider.dart';
import 'package:omnivium/core/agent/agent_orchestrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModelConfig', () {
    test('creates with required fields', () {
      const config = ModelConfig(id: 'gpt4', name: 'GPT-4', provider: 'openai');
      expect(config.id, 'gpt4');
      expect(config.name, 'GPT-4');
      expect(config.provider, 'openai');
      expect(config.tier, 'smart');
    });

    test('creates with tier', () {
      const config = ModelConfig(id: 'gpt4o-mini', name: 'GPT-4o Mini', provider: 'openai', tier: 'fast');
      expect(config.tier, 'fast');
    });

    test('toJson returns correct map', () {
      const config = ModelConfig(id: 'gpt4', name: 'GPT-4', provider: 'openai');
      final json = config.toJson();
      expect(json['id'], 'gpt4');
      expect(json['name'], 'GPT-4');
      expect(json['provider'], 'openai');
      expect(json['tier'], 'smart');
    });

    test('fromJson creates correct config', () {
      final json = {'id': 'test', 'name': 'Test', 'provider': 'claude', 'tier': 'fast'};
      final config = ModelConfig.fromJson(json);
      expect(config.id, 'test');
      expect(config.name, 'Test');
      expect(config.provider, 'claude');
      expect(config.tier, 'fast');
    });

    test('fromJson handles missing provider and tier', () {
      final json = {'id': 'test', 'name': 'Test'};
      final restored = ModelConfig.fromJson(json);
      expect(restored.provider, '');
      expect(restored.tier, 'smart');
    });
  });

  group('ModelProvider', () {
    late AgentOrchestrator orchestrator;
    late ModelProvider provider;

    setUp(() {
      orchestrator = AgentOrchestrator();
      provider = ModelProvider(orchestrator: orchestrator);
    });

    tearDown(() {
      provider.dispose();
      orchestrator.dispose();
    });

    test('starts with empty models', () {
      expect(provider.models, isEmpty);
    });

    test('starts with no active model', () {
      expect(provider.activeModelId, isNull);
      expect(provider.activeModel, isNull);
    });

    test('models list is unmodifiable', () {
      expect(() => provider.models.add(const ModelConfig(id: 'x', name: 'X', provider: 'openai')), throwsUnsupportedError);
    });

    test('orchestrator getter returns same instance', () {
      expect(identical(provider.orchestrator, orchestrator), true);
    });

    test('switchModel with no models does nothing', () {
      provider.switchModel('nonexistent');
      expect(provider.activeModelId, isNull);
    });
  });
}
