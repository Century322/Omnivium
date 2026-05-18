import '../memory/context_budget.dart';
import 'agent_state.dart';
import '../providers/ai_provider.dart';

class ConversationMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final List<ThoughtStep> thoughts;

  const ConversationMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.thoughts = const [],
  });

  ConversationMessage copyWith({
    String? content,
    bool? isStreaming,
    List<ThoughtStep>? thoughts,
  }) =>
      ConversationMessage(
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
        thoughts: thoughts ?? this.thoughts,
      );
}

class ConversationManager {
  final List<ConversationMessage> _messages = [];
  final List<ChatMessage> _chatHistory = [];
  final ContextBudgetManager _budgetManager = ContextBudgetManager();
  final List<ThoughtStep> _currentThoughts = [];

  List<ConversationMessage> get messages => List.unmodifiable(_messages);
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  ContextBudgetManager get budgetManager => _budgetManager;
  List<ThoughtStep> get currentThoughts => List.unmodifiable(_currentThoughts);

  void addUserMessage(String content) {
    _messages.add(ConversationMessage(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    ));
    _chatHistory.add(ChatMessage(role: 'user', content: content));
  }

  int addStreamingAssistant() {
    _messages.add(ConversationMessage(
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    ));
    return _messages.length - 1;
  }

  void updateStreamingContent(int index, String content) {
    if (index < _messages.length) {
      _messages[index] = _messages[index].copyWith(content: content);
    }
  }

  void finalizeStreaming(int index, String fullContent) {
    if (index < _messages.length) {
      _messages[index] = _messages[index].copyWith(
        content: fullContent,
        isStreaming: false,
      );
    }
    _chatHistory.add(ChatMessage(role: 'assistant', content: fullContent));
  }

  void addStaticAssistant(String content) {
    _messages.add(ConversationMessage(
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    ));
    _chatHistory.add(ChatMessage(role: 'assistant', content: content));
  }

  void addThought(ThoughtType type, String content, {Map<String, dynamic>? metadata}) {
    _currentThoughts.add(ThoughtStep(
      type: type,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  void clearThoughts() {
    _currentThoughts.clear();
  }

  bool tryAllocateBudget(String input) {
    final inputTokens = estimateTokens(input);
    if (!_budgetManager.canFit(inputTokens)) {
      if (_chatHistory.isEmpty) return false;
      final oldest = _chatHistory.removeAt(0);
      _budgetManager.release(estimateTokens(oldest.content));
    }
    _budgetManager.allocate(inputTokens);
    return true;
  }

  void clear() {
    _messages.clear();
    _chatHistory.clear();
    _currentThoughts.clear();
    _budgetManager.reset();
  }
}
