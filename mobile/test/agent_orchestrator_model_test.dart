import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/agent/agent_orchestrator.dart';
import 'package:omnivium/core/agent/agent_state.dart';
import 'package:omnivium/core/agent/conversation_manager.dart';

void main() {
  group('AgentLogEntry', () {
    test('isRunning returns true when endTime is null', () {
      final entry = AgentLogEntry(
        skillName: 'Test',
        skillId: 'test_1',
        input: 'hello',
        startTime: DateTime.now(),
      );
      expect(entry.isRunning, isTrue);
    });

    test('isRunning returns false when endTime is set', () {
      final now = DateTime.now();
      final entry = AgentLogEntry(
        skillName: 'Test',
        skillId: 'test_1',
        input: 'hello',
        startTime: now,
        endTime: now.add(const Duration(seconds: 5)),
      );
      expect(entry.isRunning, isFalse);
    });

    test('duration returns zero when endTime is null', () {
      final entry = AgentLogEntry(
        skillName: 'Test',
        skillId: 'test_1',
        input: 'hello',
        startTime: DateTime.now(),
      );
      expect(entry.duration, Duration.zero);
    });

    test('duration returns correct difference', () {
      final start = DateTime(2025, 1, 1, 10, 0, 0);
      final end = DateTime(2025, 1, 1, 10, 0, 5);
      final entry = AgentLogEntry(
        skillName: 'Test',
        skillId: 'test_1',
        input: 'hello',
        startTime: start,
        endTime: end,
      );
      expect(entry.duration, const Duration(seconds: 5));
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final entry = AgentLogEntry(
        skillName: 'Skill',
        skillId: 's1',
        input: 'input',
        startTime: now,
        endTime: now,
        success: true,
        output: 'result',
        error: null,
      );
      expect(entry.skillName, 'Skill');
      expect(entry.success, isTrue);
      expect(entry.output, 'result');
    });
  });

  group('ConversationMessage', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final msg = ConversationMessage(role: 'user', content: 'Hello', timestamp: now);
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.isStreaming, isFalse);
      expect(msg.thoughts, isEmpty);
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final thoughts = [ThoughtStep(type: ThoughtType.analysis, content: 'Processing...', timestamp: now)];
      final msg = ConversationMessage(
        role: 'assistant',
        content: 'Response',
        timestamp: now,
        isStreaming: true,
        thoughts: thoughts,
      );
      expect(msg.isStreaming, isTrue);
      expect(msg.thoughts.length, 1);
    });

    test('copyWith updates specified fields', () {
      final now = DateTime.now();
      final msg = ConversationMessage(role: 'assistant', content: 'Original', timestamp: now);
      final updated = msg.copyWith(content: 'Updated', isStreaming: true);
      expect(updated.content, 'Updated');
      expect(updated.isStreaming, isTrue);
      expect(updated.role, 'assistant');
      expect(updated.timestamp, now);
    });

    test('copyWith without args keeps original', () {
      final now = DateTime.now();
      final msg = ConversationMessage(role: 'user', content: 'Hello', timestamp: now, isStreaming: true);
      final copy = msg.copyWith();
      expect(copy.content, 'Hello');
      expect(copy.isStreaming, isTrue);
    });
  });
}
