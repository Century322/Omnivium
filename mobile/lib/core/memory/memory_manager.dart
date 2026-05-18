enum MemoryType {
  identity,
  instruction,
  preference,
  goal,
  context,
  fact,
  pattern,
}

class LegacyMemoryEntry {
  final String id;
  final MemoryType type;
  final String content;
  final double importance;
  final double confidence;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const LegacyMemoryEntry({
    required this.id,
    required this.type,
    required this.content,
    this.importance = 0.5,
    this.confidence = 1.0,
    required this.createdAt,
    this.expiresAt,
  });
}

abstract class MemoryManager {
  Future<void> store(LegacyMemoryEntry entry);
  Future<List<LegacyMemoryEntry>> retrieve(String query, {int limit = 10});
  Future<void> delete(String id);
  Future<List<LegacyMemoryEntry>> getUserMemories();
  Future<List<LegacyMemoryEntry>> getConversationMemories(String conversationId);
  Future<List<LegacyMemoryEntry>> getTopicMemories(String topic);
}
