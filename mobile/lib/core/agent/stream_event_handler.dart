import 'agent_state.dart';
import 'agent_state_machine.dart';
import 'conversation_manager.dart';
import '../runtime/streaming_controller.dart';
import '../providers/ai_provider.dart';

class StreamEventResult {
  final bool shouldNotify;
  final bool isComplete;
  final bool isError;

  const StreamEventResult({
    this.shouldNotify = false,
    this.isComplete = false,
    this.isError = false,
  });
}

class StreamEventHandler {
  final AgentStateMachine _stateMachine;
  final StreamingController _streamingController;
  final ConversationManager _conversation;

  String _streamingBuffer = '';

  String get streamingBuffer => _streamingBuffer;
  StreamingController get streamingController => _streamingController;

  StreamEventHandler({
    required AgentStateMachine stateMachine,
    required StreamingController streamingController,
    required ConversationManager conversation,
  }) : _stateMachine = stateMachine,
       _streamingController = streamingController,
       _conversation = conversation;

  StreamEventResult handleEvent(AgentEvent event, int msgIndex) {
    final data = event.data;

    switch (event.type) {
      case 'agent_status':
        return _handleStatus(data, msgIndex);
      case 'agent_memory':
        _conversation.addThought(ThoughtType.memory, 'Relevant memory found');
        return const StreamEventResult(shouldNotify: true);
      case 'agent_intent':
        return _handleIntent(data, msgIndex);
      case 'agent_skill_result':
        return _handleSkillResult(data, msgIndex);
      case 'agent_error':
        return _handleError(data, msgIndex);
      case 'message':
        return _handleMessage(data, msgIndex);
      default:
        return const StreamEventResult();
    }
  }

  StreamEventResult _handleStatus(Map<String, dynamic> data, int msgIndex) {
    final phase = data['phase'] as String? ?? '';
    if (phase == 'classifying') {
      _conversation.addThought(ThoughtType.analysis, 'Analyzing input');
    } else if (phase == 'generating') {
      _stateMachine.transition(AgentState.executing);
    } else if (phase == 'completed') {
      _stateMachine.transition(AgentState.completed);
    }
    return const StreamEventResult(shouldNotify: true);
  }

  StreamEventResult _handleIntent(Map<String, dynamic> data, int msgIndex) {
    final intent = data['intent'] ?? 'chat';
    final channel = data['channel'] ?? 'fast';
    _conversation.addThought(
      ThoughtType.planning,
      'Intent classified: $intent ($channel)');
    return const StreamEventResult(shouldNotify: true);
  }

  StreamEventResult _handleSkillResult(
    Map<String, dynamic> data,
    int msgIndex) {
    final skillName = data['skill'] as String? ?? '';
    final success = data['success'] as bool? ?? false;
    _conversation.addThought(
      ThoughtType.evaluation,
      'Tool ${success ? 'succeeded' : 'failed'}: $skillName');
    return const StreamEventResult(shouldNotify: true);
  }

  StreamEventResult _handleError(Map<String, dynamic> data, int msgIndex) {
    _conversation.updateStreamingContent(
      msgIndex,
      'Error: ${data['error'] ?? 'Unknown error'}');
    _conversation.finalizeStreaming(
      msgIndex,
      'Error: ${data['error'] ?? 'Unknown error'}');
    return const StreamEventResult(
      shouldNotify: true,
      isComplete: true,
      isError: true);
  }

  static const _analysisStart = '<<<COGNITIVE_ANALYSIS>>>';
  static const _analysisEnd = '<<<END_ANALYSIS>>>';

  StreamEventResult _handleMessage(Map<String, dynamic> data, int msgIndex) {
    final choices = data['choices'] as List<dynamic>?;
    final firstChoice = choices != null && choices.isNotEmpty
        ? choices[0] as Map<String, dynamic>?
        : null;
    final delta = firstChoice?['delta'] as Map<String, dynamic>?;
    final content = delta?['content']?.toString() ?? '';
    if (content.isEmpty) return const StreamEventResult();

    _streamingBuffer += content;

    final displayBuffer = _stripAnalysisBlock(_streamingBuffer);
    _streamingController.addChunk(content);
    _conversation.updateStreamingContent(msgIndex, displayBuffer);
    return const StreamEventResult(shouldNotify: true);
  }

  String _stripAnalysisBlock(String buffer) {
    final startIdx = buffer.indexOf(_analysisStart);
    if (startIdx < 0) return buffer;
    return buffer.substring(0, startIdx).trim();
  }

  void completeStream(int msgIndex) {
    final cleanBuffer = _stripAnalysisBlock(_streamingBuffer);
    _conversation.finalizeStreaming(msgIndex, cleanBuffer);
    _streamingController.complete();
  }

  void completeStreamWithError(int msgIndex, Object error) {
    String msg;
    if (error is RateLimitException) {
      msg =
          '⚠️ ${error.waitSeconds < 60 ? '${error.waitSeconds}s' : '${(error.waitSeconds / 60).round()}min'}';
    } else {
      msg = 'Error: $error';
    }
    _conversation.finalizeStreaming(msgIndex, msg);
    _streamingController.addError(error.toString());
  }

  void reset() {
    _streamingBuffer = '';
  }
}
