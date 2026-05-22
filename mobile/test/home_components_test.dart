import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/presentation/widgets/home_components.dart';
import 'package:omnivium/core/agent/agent_state.dart';

void main() {
  group('ChatMessageData', () {
    test('creates with required fields', () {
      final msg = ChatMessageData(role: 'user', content: 'Hello');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.isStreaming, isFalse);
      expect(msg.cardType, isNull);
      expect(msg.cardData, isNull);
      expect(msg.thoughts, isEmpty);
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final thoughts = [
        ThoughtStep(
          type: ThoughtType.planning,
          content: 'Planning...',
          timestamp: now,
        ),
      ];
      final msg = ChatMessageData(
        role: 'assistant',
        content: 'Response',
        isStreaming: true,
        cardType: 'code',
        cardData: {'lang': 'dart'},
        thoughts: thoughts,
      );
      expect(msg.isStreaming, isTrue);
      expect(msg.cardType, 'code');
      expect(msg.cardData!['lang'], 'dart');
      expect(msg.thoughts.length, 1);
    });
  });

  group('ChatItemData', () {
    test('creates with positional fields', () {
      final item = ChatItemData('id1', 'Alice', 'Hello', '10:30');
      expect(item.id, 'id1');
      expect(item.name, 'Alice');
      expect(item.lastMsg, 'Hello');
      expect(item.time, '10:30');
    });
  });

  group('FriendMessageData', () {
    test('creates with required fields', () {
      final msg = FriendMessageData(isMe: true, content: 'Hi there');
      expect(msg.isMe, isTrue);
      expect(msg.content, 'Hi there');
    });
  });
}
