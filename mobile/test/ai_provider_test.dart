import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/providers/ai_provider.dart';
import 'package:omnivium/core/model_provider.dart';

void main() {
  group('ChatMessage', () {
    test('creates user message', () {
      final msg = ChatMessage(role: 'user', content: 'Hello');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
    });

    test('creates assistant message', () {
      final msg = ChatMessage(role: 'assistant', content: 'Hi there!');
      expect(msg.role, 'assistant');
      expect(msg.content, 'Hi there!');
    });

    test('creates system message', () {
      final msg = ChatMessage(role: 'system', content: 'You are a helper');
      expect(msg.role, 'system');
      expect(msg.content, 'You are a helper');
    });

    test('toJson returns correct map', () {
      final msg = ChatMessage(role: 'user', content: 'Test');
      final json = msg.toJson();
      expect(json['role'], 'user');
      expect(json['content'], 'Test');
    });

    test('handles empty content', () {
      final msg = ChatMessage(role: 'user', content: '');
      expect(msg.content, '');
      expect(msg.toJson()['content'], '');
    });

    test('handles long content', () {
      final longContent = 'A' * 10000;
      final msg = ChatMessage(role: 'user', content: longContent);
      expect(msg.content.length, 10000);
    });
  });

  group('AIResponse', () {
    test('creates with all fields', () {
      final response = AIResponse(
        content: 'Hello!',
        model: 'gpt-4o',
        promptTokens: 10,
        completionTokens: 20,
      );
      expect(response.content, 'Hello!');
      expect(response.model, 'gpt-4o');
      expect(response.promptTokens, 10);
      expect(response.completionTokens, 20);
    });

    test('creates with default token counts', () {
      final response = AIResponse(content: 'Hi', model: 'gpt-4o');
      expect(response.promptTokens, 0);
      expect(response.completionTokens, 0);
    });
  });

  group('ChatService', () {
    test('is a singleton', () {
      final a = ChatService.instance;
      final b = ChatService.instance;
      expect(identical(a, b), true);
    });

    test('setModel updates currentModel', () {
      final service = ChatService.instance;
      service.setModel('gpt-4o');
      expect(service.currentModel, 'gpt-4o');
    });
  });

  group('ModelConfig', () {
    test('creates with required fields', () {
      final config = ModelConfig(
        id: 'test-1',
        name: 'GPT-4o',
        provider: 'openai',
      );
      expect(config.id, 'test-1');
      expect(config.name, 'GPT-4o');
      expect(config.provider, 'openai');
    });

    test('toJson returns correct map', () {
      final config = ModelConfig(
        id: 'test-3',
        name: 'GPT-4o',
        provider: 'openai',
      );
      final json = config.toJson();
      expect(json['id'], 'test-3');
      expect(json['name'], 'GPT-4o');
      expect(json['provider'], 'openai');
    });

    test('fromJson creates correct config', () {
      final json = {'id': 'test-4', 'name': 'Claude', 'provider': 'claude'};
      final config = ModelConfig.fromJson(json);
      expect(config.id, 'test-4');
      expect(config.name, 'Claude');
      expect(config.provider, 'claude');
    });
  });
}
