import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/agent/conversation_manager.dart';

void main() {
  group('ConversationMessage', () {
    test('constructor sets fields', () {
      final now = DateTime.now();
      final msg = ConversationMessage(
        role: 'user',
        content: 'Hello',
        timestamp: now,
      );
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.timestamp, now);
      expect(msg.isStreaming, isFalse);
      expect(msg.thoughts, isEmpty);
    });

    test('copyWith updates content', () {
      final now = DateTime.now();
      final msg = ConversationMessage(
        role: 'assistant',
        content: 'Hello',
        timestamp: now,
      );
      final updated = msg.copyWith(content: 'World');
      expect(updated.content, 'World');
      expect(updated.role, 'assistant');
    });

    test('copyWith updates isStreaming', () {
      final now = DateTime.now();
      final msg = ConversationMessage(
        role: 'assistant',
        content: '',
        timestamp: now,
        isStreaming: true,
      );
      final updated = msg.copyWith(isStreaming: false);
      expect(updated.isStreaming, isFalse);
    });

    test('copyWith updates thoughts', () {
      final now = DateTime.now();
      final msg = ConversationMessage(
        role: 'assistant',
        content: 'Thinking...',
        timestamp: now,
      );
      final updated = msg.copyWith(thoughts: []);
      expect(updated.thoughts, isEmpty);
    });
  });

  group('ConversationManager', () {
    test('initial messages is empty', () {
      final manager = ConversationManager();
      expect(manager.messages, isEmpty);
    });

    test('initial chatHistory is empty', () {
      final manager = ConversationManager();
      expect(manager.chatHistory, isEmpty);
    });

    test('addUserMessage adds message', () {
      final manager = ConversationManager();
      manager.addUserMessage('Hello AI');
      expect(manager.messages.length, 1);
      expect(manager.messages.first.role, 'user');
      expect(manager.messages.first.content, 'Hello AI');
    });

    test('addStreamingAssistant returns index', () {
      final manager = ConversationManager();
      manager.addUserMessage('Hello');
      final index = manager.addStreamingAssistant();
      expect(index, 1);
      expect(manager.messages[index].role, 'assistant');
      expect(manager.messages[index].isStreaming, isTrue);
    });

    test('updateStreamingContent updates content', () {
      final manager = ConversationManager();
      manager.addUserMessage('Hello');
      final index = manager.addStreamingAssistant();
      manager.updateStreamingContent(index, 'Hi');
      expect(manager.messages[index].content, 'Hi');
    });

    test('finalizeStreaming sets isStreaming false', () {
      final manager = ConversationManager();
      manager.addUserMessage('Hello');
      final index = manager.addStreamingAssistant();
      manager.updateStreamingContent(index, 'Hi there!');
      manager.finalizeStreaming(index, 'Hi there!');
      expect(manager.messages[index].isStreaming, isFalse);
      expect(manager.messages[index].content, 'Hi there!');
    });

    test('messages is unmodifiable', () {
      final manager = ConversationManager();
      expect(
        () => manager.messages.add(
          ConversationMessage(
            role: 'test',
            content: '',
            timestamp: DateTime.now(),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('multiple user messages', () {
      final manager = ConversationManager();
      manager.addUserMessage('First');
      manager.addUserMessage('Second');
      manager.addUserMessage('Third');
      expect(manager.messages.length, 3);
      expect(manager.messages[0].content, 'First');
      expect(manager.messages[1].content, 'Second');
      expect(manager.messages[2].content, 'Third');
    });

    test('currentThoughts is empty initially', () {
      final manager = ConversationManager();
      expect(manager.currentThoughts, isEmpty);
    });
  });
}
