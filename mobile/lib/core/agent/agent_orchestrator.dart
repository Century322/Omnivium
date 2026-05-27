import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../remote_config_service.dart';
import '../notification_center.dart';
import '../memory/context_budget.dart';
import 'agent_state.dart';
import 'agent_state_machine.dart';
import 'conversation_manager.dart';
import 'stream_event_handler.dart';
import '../skills/skill.dart';
import '../skills/skill_registry.dart';
import '../runtime/streaming_controller.dart';
import '../runtime/card_runtime.dart';
import '../runtime/sdk/omnivium_sdk.dart';
import '../runtime/plugin/plugin_descriptor.dart';
import '../runtime/plugin/plugin_handler.dart';
import '../runtime/vocabulary/runtime_message.dart';
import '../runtime/vocabulary/runtime_event.dart';
import '../runtime/vocabulary/capability_context.dart';
import '../app_capability_service.dart';
import '../providers/ai_provider.dart';
import '../api_proxy_service.dart';
import '../app_logger.dart';
import '../notification_center.dart' as nc;

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
  final CardRuntime _cardRuntime = CardRuntime(autoStartTimer: false);
  late final StreamEventHandler _eventHandler;

  String _currentModel = '';
  final List<AgentLogEntry> _executionLogs = [];
  Completer<bool>? _permissionCompleter;
  String? _pendingSkillName;
  OmniviumSDK? _sdk;

  DateTime _lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const _notifyThrottleMs = 50;
  bool _hasPendingNotify = false;
  bool _enabled = true;
  bool _disposed = false;
  Timer? _throttleTimer;

  bool get isEnabled => _enabled;
  void setEnabled(bool v) {
    _enabled = v;
  }

  AgentOrchestrator() {
    _eventHandler = StreamEventHandler(
      stateMachine: _stateMachine,
      streamingController: _streamingController,
      conversation: _conversation,
    );
  }

  void connectRuntime(OmniviumSDK sdk) {
    _sdk = sdk;
  }

  OmniviumSDK? get runtime => _sdk;

  void _throttledNotify() {
    if (_disposed) return;
    final now = DateTime.now();
    final elapsed = now.difference(_lastNotifyTime).inMilliseconds;
    if (elapsed >= _notifyThrottleMs) {
      _lastNotifyTime = now;
      _hasPendingNotify = false;
      notifyListeners();
    } else if (!_hasPendingNotify) {
      _hasPendingNotify = true;
      _throttleTimer?.cancel();
      _throttleTimer = Timer(Duration(milliseconds: _notifyThrottleMs - elapsed), () {
        if (_hasPendingNotify && !_disposed) {
          _hasPendingNotify = false;
          _lastNotifyTime = DateTime.now();
          notifyListeners();
        }
      });
    }
  }

  void _immediateNotify() {
    if (_disposed) return;
    _hasPendingNotify = false;
    _lastNotifyTime = DateTime.now();
    notifyListeners();
    nc.NotificationCenter.post(
      nc.Event.agentStateChanged,
      data: {'state': _stateMachine.state.name},
    );
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
  bool get isWaitingPermission {
    final completer = _permissionCompleter;
    return completer != null && !completer.isCompleted;
  }
  String? get pendingSkillName => _pendingSkillName;

  void stopStreaming() {
    _streamingController.complete();
    if (_stateMachine.state != AgentState.idle) {
      _stateMachine.transition(AgentState.idle);
      _throttledNotify();
    }
  }

  void grantPermission() {
    final completer = _permissionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(true);
      _pendingSkillName = null;
    }
  }

  void denyPermission() {
    final completer = _permissionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
      _pendingSkillName = null;
    }
  }

  void configure({String model = ''}) {
    _currentModel = model;
    ChatService.instance.setModel(model);
  }

  void registerSkill(Skill skill) {
    _skillRegistry.register(skill);
    _registerSkillAsRuntimeCapability(skill);
  }

  void _registerSkillAsRuntimeCapability(Skill skill) {
    final sdk = _sdk;
    if (sdk == null || !sdk.isInitialized) return;
    try {
      final descriptor = PluginDescriptor(
        id: 'skill_${skill.id}',
        name: skill.name,
        version: '1.0.0',
        description: skill.description,
        capabilities: [
          CapabilityDeclaration(
            id: 'skill.${skill.id}.execute',
            name: skill.name,
            description: skill.description,
            permission: 'auto',
          ),
        ],
      );
      final registered = await sdk.container.registerPlugin(descriptor, _SkillPluginHandler(skill));
      if (registered) {
        await sdk.container.activatePlugin(descriptor.id);
      } else {
        AppLogger.instance.warning(
          'Skill registration: plugin limit reached, skipping ${skill.id}',
        );
      }
    } catch (e) {
      AppLogger.instance.warning(
        'Skill registration: failed to register skill as runtime capability',
        error: e,
      );
    }
  }

  void setModel(String model) {
    _currentModel = model;
    _immediateNotify();
  }

  dynamic createCard(String type, {Map<String, dynamic>? data, Duration? ttl}) {
    _cardRuntime.ensureTimerStarted();
    final card = _cardRuntime.create(type, data: data ?? const {}, ttl: ttl);
    return card;
  }

  Future<void> sendMessage(String input) async {
    if (input.trim().isEmpty) return;
    if (!isIdle) return;
    if (!_enabled) return;

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
      _conversation.addStaticAssistant(
        'AI is not configured. Please check your settings.',
      );
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
        contextMessages.insert(
          0,
          ChatMessage(role: 'system', content: systemPrompt),
        );
      }

      final skillsList = _skillRegistry.all
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'description': s.description,
              'channel': s.channel.name,
            },
          )
          .toList();

      final capResult = await AppCapabilityService.instance.invoke(
        'agent.chat',
        params: {
          'messages': contextMessages
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
          'model': _currentModel,
          'skills': skillsList,
        },
        timeoutMs: 30000,
      );

      if (capResult.status == CapabilityStatus.success &&
          capResult.data != null) {
        final data = capResult.data!;
        if (data.containsKey('stream')) {
          final agentStream = data['stream'] as AgentStream;
          await for (final event in agentStream.events) {
            final result = _eventHandler.handleEvent(event, msgIndex);
            if (result.shouldNotify) _throttledNotify();
            if (result.isComplete) break;
          }
        } else if (data.containsKey('content')) {
          _conversation.updateStreamingContent(
            msgIndex,
            data['content'] as String,
          );
        }
      } else {
        await _streamAIDirect(contextMessages, skillsList, msgIndex);
      }
    } catch (e) {
      await _streamAIDirectFallback(input, msgIndex, e);
    }

    _stateMachine.reset();
    _immediateNotify();
  }

  Future<void> _streamAIDirect(
    List<ChatMessage> contextMessages,
    List<Map<String, dynamic>> skillsList,
    int msgIndex,
  ) async {
    final agentStream = await ChatService.instance.agentChat(
      contextMessages,
      model: _currentModel,
      skills: skillsList,
    );

    await for (final event in agentStream.events) {
      final result = _eventHandler.handleEvent(event, msgIndex);
      if (result.shouldNotify) _throttledNotify();
      if (result.isComplete) break;
    }
    _eventHandler.completeStream(msgIndex);
  }

  Future<void> _streamAIDirectFallback(
    String input,
    int msgIndex,
    Object error,
  ) async {
    AppLogger.instance.warning(
      'Runtime capability failed, falling back to direct call',
      error: error,
    );
    try {
      final contextMessages = List<ChatMessage>.from(_conversation.chatHistory);
      final systemPrompt = _buildSystemPrompt();
      final hasSystemMsg = contextMessages.any((m) => m.role == 'system');
      if (!hasSystemMsg) {
        contextMessages.insert(
          0,
          ChatMessage(role: 'system', content: systemPrompt),
        );
      }
      final skillsList = _skillRegistry.all
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'description': s.description,
              'channel': s.channel.name,
            },
          )
          .toList();
      await _streamAIDirect(contextMessages, skillsList, msgIndex);
    } catch (e2) {
      _eventHandler.completeStreamWithError(msgIndex, e2);
    }
  }

  String _buildSystemPrompt() {
    final remotePrompt = RemoteConfigService.instance.getValue<String>(
      'system_prompt',
    );
    final skills = _skillRegistry.all;
    final skillList = skills
        .map((s) => '- ${s.name} (${s.id}): ${s.description}')
        .join('\n');
    final agentLang = _agentLanguage;
    final langSuffix = agentLang != null && agentLang.isNotEmpty
        ? '\n- Respond in $agentLang'
        : '';

    if (remotePrompt != null && remotePrompt.isNotEmpty) {
      return remotePrompt.replaceAll(
            '{skills}',
            skillList.isNotEmpty ? skillList : 'No tools currently available.',
          ) +
          langSuffix;
    }

    return '''You are OMNI, the AI assistant for Omnivium. You are helpful, accurate, and transparent about your reasoning.

Available tools:
${skillList.isNotEmpty ? skillList : 'No tools currently available.'}

Guidelines:
- Always think step by step before answering
- If you need to use a tool, explain why
- Be honest about uncertainty
- Remember user preferences and context across conversations$langSuffix''';
  }

  String? _agentLanguage;
  void setAgentLanguage(String lang) {
    _agentLanguage = lang;
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

  void deleteMessagePair(int assistantIndex) {
    _conversation.removeMessagePair(assistantIndex);
    _immediateNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _throttleTimer?.cancel();
    _cardRuntime.dispose();
    _streamingController.dispose();
    super.dispose();
  }
}

class _SkillPluginHandler implements PluginHandler {
  final Skill _skill;

  _SkillPluginHandler(this._skill);

  @override
  Future<HandlerResult> handleMessage(
    RuntimeMessage message,
    CapabilityContext context,
  ) async {
    return HandlerResult.ok();
  }

  @override
  Future<HandlerResult> handleEvent(
    RuntimeEvent event,
    CapabilityContext context,
  ) async {
    return HandlerResult.ok();
  }

  @override
  Future<CapabilityResult> invokeCapability(
    String capabilityId,
    dynamic params,
    CapabilityContext context,
  ) async {
    if (capabilityId == 'skill.${_skill.id}.execute') {
      final permission = await _checkPermission(capabilityId);
      if (permission == 'deny') {
        return CapabilityResult.fail(
          RuntimeError(
            code: 'PERMISSION_DENIED',
            message: 'Capability $capabilityId is denied by user',
          ),
        );
      }
      if (permission == 'confirm') {
        final granted = await _requestConfirmation(capabilityId);
        if (!granted) {
          return CapabilityResult.fail(
            RuntimeError(
              code: 'PERMISSION_DENIED',
              message: 'User denied $capabilityId',
            ),
          );
        }
      }
      try {
        final result = await _skill.execute(
          params is Map<String, dynamic> ? params : {'input': params},
        );
        return CapabilityResult.ok(result);
      } catch (e) {
        return CapabilityResult.fail(
          RuntimeError(code: 'SKILL_ERROR', message: e.toString()),
        );
      }
    }
    return CapabilityResult.fail(
      RuntimeError(
        code: 'UNKNOWN_CAPABILITY',
        message: 'Unknown: $capabilityId',
      ),
    );
  }

  static Future<String> _checkPermission(String capabilityId) async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString('omnivium_perm_$capabilityId');
    if (override != null) return override;
    return prefs.getString('omnivium_agent_permission') ?? 'confirm';
  }

  static Future<bool> _requestConfirmation(String capabilityId) async {
    final completer = Completer<bool>();
    void handler(Map<String, dynamic>? data) {
      final granted = data?['granted'] as bool? ?? false;
      if (!completer.isCompleted) completer.complete(granted);
      NotificationCenter.removeObserver(
        Event.capabilityConfirm,
        callback: handler,
      );
    }

    NotificationCenter.observe(Event.capabilityConfirm, handler);
    NotificationCenter.post(
      Event.capabilityConfirm,
      data: {'capabilityId': capabilityId, 'pending': true},
    );
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => false,
    );
  }
}
