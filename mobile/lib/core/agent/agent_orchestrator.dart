import 'dart:async';
import 'package:flutter/foundation.dart';
import '../remote_config_service.dart';
import '../memory/context_budget.dart';
import 'agent_state.dart';
import 'agent_state_machine.dart';
import 'conversation_manager.dart';
import 'stream_event_handler.dart';
import '../skills/skill.dart';
import '../skills/skill_registry.dart';
import '../runtime/streaming_controller.dart';
import '../runtime/card_runtime.dart';
import '../providers/ai_provider.dart';
import '../api_proxy_service.dart';

class AgentLogEntry {
  final String skillName;
  final String skillId;
  final String input;
  final DateTime startTime;
  final DateTime? endTime;
  final bool? success;
  final String? output;
  final String? error;
  bool get isRunning => endTime == null;
  Duration get duration => endTime?.difference(startTime) ?? Duration.zero;
  const AgentLogEntry({
    required this.skillName,
    required this.skillId,
    required this.input,
    required this.startTime,
    this.endTime,
    this.success,
    this.output,
    this.error,
  });
}

class AgentOrchestrator extends ChangeNotifier {
  final AgentStateMachine _stateMachine = AgentStateMachine();
  final SkillRegistry _skillRegistry = SkillRegistry();
  final ConversationManager _conversation = ConversationManager();
  final StreamingController _streamingController = StreamingController();
  final CardRuntime _cardRuntime = CardRuntime();
  late final StreamEventHandler _eventHandler;

  String _currentModel = '';
  final List<AgentLogEntry> _executionLogs = [];
  Completer<bool>? _permissionCompleter;
  String? _pendingSkillName;

  DateTime _lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const _notifyThrottleMs = 50;
  bool _hasPendingNotify = false;

  AgentOrchestrator() {
    _eventHandler = StreamEventHandler(
      stateMachine: _stateMachine,
      streamingController: _streamingController,
      conversation: _conversation,
    );
  }

  void _throttledNotify() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastNotifyTime).inMilliseconds;
    if (elapsed >= _notifyThrottleMs) {
      _lastNotifyTime = now;
      _hasPendingNotify = false;
      notifyListeners();
    } else if (!_hasPendingNotify) {
      _hasPendingNotify = true;
      Future.delayed(Duration(milliseconds: _notifyThrottleMs - elapsed), () {
        if (_hasPendingNotify) {
          _hasPendingNotify = false;
          _lastNotifyTime = DateTime.now();
          notifyListeners();
        }
      });
    }
  }

  void _immediateNotify() {
    _hasPendingNotify = false;
    _lastNotifyTime = DateTime.now();
    notifyListeners();
  }

  AgentState get state => _stateMachine.state;
  SkillRegistry get skillRegistry => _skillRegistry;
  StreamingController get streamingController => _streamingController;
  CardRuntime get cardRuntime => _cardRuntime;
  ContextBudgetManager get budgetManager => _conversation.budgetManager;
  List<ConversationMessage> get messages => _conversation.messages;
  List<AgentLogEntry> get executionLogs => List.unmodifiable(_executionLogs);
  List<ThoughtStep> get currentThoughts => _conversation.currentThoughts;
  String get currentModel => _currentModel;
  bool get isIdle => state == AgentState.idle;
  bool get isThinking => state == AgentState.thinking;
  bool get isReflecting => state == AgentState.reflecting;
  bool get isMemorizing => state == AgentState.memorizing;
  bool get isStreaming => _streamingController.isStreaming;
  bool get isWaitingPermission => _permissionCompleter != null && !_permissionCompleter!.isCompleted;
  String? get pendingSkillName => _pendingSkillName;

  void grantPermission() {
    if (_permissionCompleter != null && !_permissionCompleter!.isCompleted) {
      _permissionCompleter!.complete(true);
      _pendingSkillName = null;
    }
  }

  void denyPermission() {
    if (_permissionCompleter != null && !_permissionCompleter!.isCompleted) {
      _permissionCompleter!.complete(false);
      _pendingSkillName = null;
    }
  }

  void configure({String model = ''}) {
    _currentModel = model;
    ChatService.instance.setModel(model);
  }

  void registerSkill(Skill skill) {
    _skillRegistry.register(skill);
  }

  void setModel(String model) {
    _currentModel = model;
    _immediateNotify();
  }

  Future<void> sendMessage(String input) async {
    if (input.trim().isEmpty) return;
    if (!isIdle) return;

    if (!_conversation.tryAllocateBudget(input)) return;

    _conversation.clearThoughts();
    _conversation.addUserMessage(input);
    _immediateNotify();

    await _processInput(input);
  }

  void restoreMessage(String role, String content) {
    if (role == 'user') {
      _conversation.addUserMessage(content);
    } else {
      _conversation.addStaticAssistant(content);
    }
    _immediateNotify();
  }

  Future<void> _processInput(String input) async {
    _stateMachine.transition(AgentState.thinking);
    _conversation.addThought(
      ThoughtType.analysis,
      'Analyzing input: "${input.length > 50 ? '${input.substring(0, 50)}...' : input}"',
    );
    _throttledNotify();

    _stateMachine.transition(AgentState.planning);
    _stateMachine.transition(AgentState.executing);
    _throttledNotify();

    await _streamAIResponse(input);
  }

  Future<void> _streamAIResponse(String input) async {
    if (!ApiProxyService.instance.isConfigured) {
      _conversation.addStaticAssistant('AI is not configured. Please check your settings.');
      _immediateNotify();
      return;
    }

    _eventHandler.reset();
    final msgIndex = _conversation.addStreamingAssistant();
    _immediateNotify();

    try {
      List<ChatMessage> contextMessages = List.from(_conversation.chatHistory);

      final systemPrompt = _buildSystemPrompt();
      final hasSystemMsg = contextMessages.any((m) => m.role == 'system');
      if (!hasSystemMsg) {
        contextMessages.insert(0, ChatMessage(role: 'system', content: systemPrompt));
      }

      final skillsList = _skillRegistry.all.map((s) => {
            'id': s.id,
            'name': s.name,
            'description': s.description,
            'channel': s.channel.name,
          }).toList();

      final agentStream = await ChatService.instance.agentChat(
        contextMessages,
        model: _currentModel,
        skills: skillsList,
      );

      await for (final event in agentStream.events) {
        final result = _eventHandler.handleEvent(event, msgIndex);
        if (result.shouldNotify) {
          _throttledNotify();
        }
        if (result.isComplete) break;
      }

      _eventHandler.completeStream(msgIndex);
    } catch (e) {
      _eventHandler.completeStreamWithError(msgIndex, e);
    }

    _stateMachine.reset();
    _immediateNotify();
  }

  String _buildSystemPrompt() {
    final remotePrompt = RemoteConfigService.instance.getValue<String>('system_prompt');
    final skills = _skillRegistry.all;
    final skillList = skills.map((s) => '- ${s.name} (${s.id}): ${s.description}').join('\n');

    if (remotePrompt != null && remotePrompt.isNotEmpty) {
      return remotePrompt.replaceAll('{skills}', skillList.isNotEmpty ? skillList : 'No tools currently available.');
    }

    return '''You are OMNI, the AI assistant for Omnivium. You are helpful, accurate, and transparent about your reasoning.

Available tools:
${skillList.isNotEmpty ? skillList : 'No tools currently available.'}

Guidelines:
- Always think step by step before answering
- If you need to use a tool, explain why
- Be honest about uncertainty
- Remember user preferences and context across conversations''';
  }

  void interrupt() {
    _stateMachine.interrupt();
    _streamingController.complete();
    _stateMachine.forceState(AgentState.idle);
    _immediateNotify();
  }

  void clearConversation() {
    _conversation.clear();
    _eventHandler.reset();
    _streamingController.reset();
    _stateMachine.reset();
    _immediateNotify();
  }

  @override
  void dispose() {
    _streamingController.dispose();
    super.dispose();
  }
}
