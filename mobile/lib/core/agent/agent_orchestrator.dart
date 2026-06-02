
import '../di/app_di.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../capability_system.dart';
import '../providers/ai_provider.dart';
import '../api_proxy_service.dart';
import '../app_logger.dart';
import '../notification_center.dart' as nc;
import '../database_service.dart';
import '../omni_model.dart';
import '../omni_objects.dart';
import '../action_executor.dart';
import '../planning_engine.dart';
import '../cross_app_action_engine.dart';
import '../note_service.dart';
import '../workspace_service.dart';
import '../agent_service.dart';
import '../matrix/matrix_cubit.dart';
import 'cognitive/cognitive_engine.dart';
import 'cognitive/understanding_engine.dart';
import 'runtime/agent_runtime.dart';

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

class OrchestratorState {
  final int version;
  const OrchestratorState(this.version);
}

class AgentOrchestrator extends Cubit<OrchestratorState> {
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
  AgentTask? _activeTask;

  DateTime _lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const _notifyThrottleMs = 50;
  bool _hasPendingNotify = false;
  bool _enabled = true;
  bool _disposed = false;
  Timer? _throttleTimer;
  int _version = 0;

  bool get isEnabled => _enabled;
  void setEnabled(bool v) {
    _enabled = v;
  }

  AgentOrchestrator() : super(const OrchestratorState(0)) {
    _eventHandler = StreamEventHandler(
      stateMachine: _stateMachine,
      streamingController: _streamingController,
      conversation: _conversation);
    _initRuntimeListener();
  }

  void _initRuntimeListener() {
    try {
      final runtime = getIt<CognitiveEngine>().agentRuntime;
      runtime.interruptStream.listen((event) {
        _handleRuntimeInterrupt(event);
      });
    } catch (_) {}
  }

  void _handleRuntimeInterrupt(InterruptEvent event) {
    if (_activeTask == null) return;
    final action = getIt<CognitiveEngine>().agentRuntime.handleInterrupt(event);
    if (action == InterruptAction.paused) {
      _conversation.addThought(
        ThoughtType.analysis,
        'Task paused by interrupt: ${event.reason}');
      _throttledNotify();
    }
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
      _version++;
      emit(OrchestratorState(_version));
    } else if (!_hasPendingNotify) {
      _hasPendingNotify = true;
      _throttleTimer?.cancel();
      _throttleTimer = Timer(
        Duration(milliseconds: _notifyThrottleMs - elapsed),
        () {
          if (_hasPendingNotify && !_disposed) {
            _hasPendingNotify = false;
            _lastNotifyTime = DateTime.now();
            _version++;
            emit(OrchestratorState(_version));
          }
        });
    }
  }

  void _immediateNotify() {
    if (_disposed) return;
    _hasPendingNotify = false;
    _lastNotifyTime = DateTime.now();
    _version++;
    emit(OrchestratorState(_version));
    nc.NotificationCenter.post(
      nc.Event.agentStateChanged,
      data: {'state': _stateMachine.state.name});
  }

  AgentState get agentState => _stateMachine.state;
  SkillRegistry get skillRegistry => _skillRegistry;
  StreamingController get streamingController => _streamingController;
  CardRuntime get cardRuntime => _cardRuntime;
  ContextBudgetManager get budgetManager => _conversation.budgetManager;
  List<ConversationMessage> get messages => _conversation.messages;
  List<AgentLogEntry> get executionLogs => List.unmodifiable(_executionLogs);
  List<ThoughtStep> get currentThoughts => _conversation.currentThoughts;
  String get currentModel => _currentModel;
  bool get isIdle => agentState == AgentState.idle;
  bool get isThinking => agentState == AgentState.thinking;
  bool get isReflecting => agentState == AgentState.reflecting;
  bool get isMemorizing => agentState == AgentState.memorizing;
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
    getIt<ChatService>().setModel(model);
  }

  void registerSkill(Skill skill) {
    _skillRegistry.register(skill);
    _registerSkillAsRuntimeCapability(skill);
  }

  Future<void> _registerSkillAsRuntimeCapability(Skill skill) async {
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
            permission: 'auto'),
        ]);
      final registered = await sdk.container.registerPlugin(
        descriptor,
        _SkillPluginHandler(skill));
      if (registered) {
        await sdk.container.activatePlugin(descriptor.id);
      } else {
        AppLogger.instance.warning(
          'Skill registration: plugin limit reached, skipping ${skill.id}');
      }
    } catch (e) {
      AppLogger.instance.warning(
        'Skill registration: failed to register skill as runtime capability',
        error: e);
    }
  }

  void setModel(String model) {
    _currentModel = model;
    _immediateNotify();
  }

  Object? createCard(String type, {Map<String, dynamic>? data, Duration? ttl}) {
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

    try {
      final runtime = getIt<CognitiveEngine>().agentRuntime;
      _activeTask = runtime.submitTask(
        description: input.length > 100 ? '${input.substring(0, 97)}...' : input,
        priority: TaskPriority.normal,
        interruptPolicy: InterruptPolicy.pause,
        metadata: {'source': 'user_message', 'input': input},
      );
    } catch (_) {}

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
      'Understanding input: "${input.length > 50 ? '${input.substring(0, 50)}...' : input}"');
    _throttledNotify();

    UnderstandingResult? understanding;
    try {
      final cognitive = getIt<CognitiveEngine>();
      understanding = await cognitive.understand(input);
      _conversation.addThought(
        ThoughtType.analysis,
        'Understood: intent=${understanding.intent.name}, emotion=${understanding.emotion.name}, importance=${understanding.importance}, entities=${understanding.entities.map((e) => e.name).join(",")}');
      _throttledNotify();
    } catch (e) {
      AppLogger.instance.warning('Understanding error', error: e);
    }

    _stateMachine.transition(AgentState.planning);
    _conversation.addThought(ThoughtType.planning, 'Assembling context and recalling memories...');
    _throttledNotify();

    _stateMachine.transition(AgentState.executing);
    _throttledNotify();

    final assistantResponse = await _streamAIResponse(input, understanding: understanding);

    await _cognitiveReflect(input, assistantResponse, understanding: understanding);
  }

  Future<String> _cognitiveReflect(String userInput, String? assistantResponse, {UnderstandingResult? understanding}) async {
    if (assistantResponse == null || assistantResponse.isEmpty) return '';

    _stateMachine.transition(AgentState.reflecting);
    _conversation.addThought(
      ThoughtType.reflection,
      'Reflecting on conversation...');
    _throttledNotify();

    try {
      final cognitive = getIt<CognitiveEngine>();
      final db = getIt<DatabaseService>();

      final preAnalyzedUser = understanding?.toJson();

      await cognitive.reflect(
        userInput,
        assistantResponse,
        workspaceId: cognitive.activeWorkspaceId,
        db: db,
        preAnalyzedUser: preAnalyzedUser,
      );

      await _executeActions(assistantResponse);
      await _executePlan(assistantResponse);
      await _executeChain(assistantResponse);

      _stateMachine.transition(AgentState.memorizing);
      _conversation.addThought(
        ThoughtType.memory,
        'Memory updated');
      _throttledNotify();
    } catch (e) {
      AppLogger.instance.warning('Cognitive reflection failed', error: e);
    }

    _stateMachine.transition(AgentState.completed);
    _completeActiveTask(success: true, output: assistantResponse);
    _stateMachine.transition(AgentState.idle);
    _immediateNotify();
    return assistantResponse;
  }

  void _completeActiveTask({required bool success, String? output}) {
    if (_activeTask == null) return;
    try {
      final runtime = getIt<CognitiveEngine>().agentRuntime;
      runtime.completeCurrentTask(AgentTaskResult(
        success: success,
        output: output,
      ));
    } catch (_) {}
    _activeTask = null;
  }

  Future<String?> _streamAIResponse(String input, {UnderstandingResult? understanding}) async {
    if (!getIt<ApiProxyService>().isConfigured) {
      _conversation.addStaticAssistant(
        'AI is not configured. Please check your settings.');
      _completeActiveTask(success: false, output: 'AI not configured');
      _stateMachine.reset();
      _immediateNotify();
      return null;
    }

    _eventHandler.reset();
    final msgIndex = _conversation.addStreamingAssistant();
    _immediateNotify();

    try {
      List<ChatMessage> contextMessages = List.from(_conversation.chatHistory);

      final systemPrompt = await _buildSystemPrompt(understanding: understanding);
      final hasSystemMsg = contextMessages.any((m) => m.role == 'system');
      if (!hasSystemMsg) {
        contextMessages.insert(
          0,
          ChatMessage(role: 'system', content: systemPrompt));
      }

      final skillsList = _skillRegistry.all
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'description': s.description,
              'channel': s.channel.name,
            })
          .toList();

      final capResult = await getIt<AppCapabilityService>().invoke(
        'agent.chat',
        params: {
          'messages': contextMessages
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
          'model': _currentModel,
          'skills': skillsList,
        },
        timeoutMs: 30000);

      if (capResult.status == CapabilityStatus.success) {
        final data = capResult.data;
        if (data != null) {
          final typedData = data as Map<String, dynamic>;
          if (typedData.containsKey('stream')) {
            final agentStream = typedData['stream'] as AgentStream;
            await for (final event in agentStream.events) {
              final result = _eventHandler.handleEvent(event, msgIndex);
              if (result.shouldNotify) _throttledNotify();
              if (result.isComplete) break;
            }
          } else if (typedData.containsKey('content')) {
            _conversation.updateStreamingContent(
              msgIndex,
              typedData['content'] as String);
          }
        }
      } else {
        await _streamAIDirect(contextMessages, skillsList, msgIndex);
      }
    } catch (e) {
      await _streamAIDirectFallback(input, msgIndex, e);
    }

    _eventHandler.completeStream(msgIndex);
    final response = _eventHandler.streamingBuffer;
    return response.isNotEmpty ? response : _getLastAssistantContent();
  }

  Future<void> _streamAIDirect(
    List<ChatMessage> contextMessages,
    List<Map<String, dynamic>> skillsList,
    int msgIndex) async {
    final agentStream = await getIt<ChatService>().agentChat(
      contextMessages,
      model: _currentModel,
      skills: skillsList);

    await for (final event in agentStream.events) {
      final result = _eventHandler.handleEvent(event, msgIndex);
      if (result.shouldNotify) _throttledNotify();
      if (result.isComplete) break;
    }
  }

  Future<void> _streamAIDirectFallback(
    String input,
    int msgIndex,
    Object error,
  ) async {
    AppLogger.instance.warning(
      'Runtime capability failed, falling back to direct call',
      error: error);
    try {
      final contextMessages = List<ChatMessage>.from(_conversation.chatHistory);
      final systemPrompt = await _buildSystemPrompt();
      final hasSystemMsg = contextMessages.any((m) => m.role == 'system');
      if (!hasSystemMsg) {
        contextMessages.insert(
          0,
          ChatMessage(role: 'system', content: systemPrompt));
      }
      final skillsList = _skillRegistry.all
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'description': s.description,
              'channel': s.channel.name,
            })
          .toList();
      await _streamAIDirect(contextMessages, skillsList, msgIndex);
    } catch (e2) {
      _eventHandler.completeStreamWithError(msgIndex, e2);
    }
  }

  String? _getLastAssistantContent() {
    for (int i = _conversation.messages.length - 1; i >= 0; i--) {
      final msg = _conversation.messages[i];
      if (msg.role == 'assistant' && !msg.isStreaming) {
        return msg.content;
      }
    }
    return null;
  }

  Future<String> _buildSystemPrompt({UnderstandingResult? understanding}) async {
    final remotePrompt = getIt<RemoteConfigService>().getValue<String>(
      'system_prompt');
    final skills = _skillRegistry.all;
    final skillList = skills
        .map((s) => '- ${s.name} (${s.id}): ${s.description}')
        .join('\n');
    final agentLang = _agentLanguage;
    final langSuffix = agentLang != null && agentLang.isNotEmpty
        ? '\n- Respond in $agentLang'
        : '';

    final memoryContext = await _buildMemoryContext(understanding: understanding);
    final capabilityContext = _buildCapabilityContext();

    if (remotePrompt != null && remotePrompt.isNotEmpty) {
      final base = remotePrompt.replaceAll(
            '{skills}',
            skillList.isNotEmpty ? skillList : 'No tools currently available.');
      return base + langSuffix + memoryContext + capabilityContext;
    }

    return '''You are OMNI, the AI assistant for Omnivium. You are helpful, accurate, and transparent about your reasoning.

Available tools:
${skillList.isNotEmpty ? skillList : 'No tools currently available.'}

$capabilityContext

You can operate on the following objects in the system:

[Available Objects & Actions]
${_buildActionContext()}

When the user asks you to perform an action (share, send, delete, create, etc.), identify the target object and use the corresponding action. If you need to perform an action, include an action request in your response using this format:
<<<ACTION>>>
{"actionId": "the action id", "objectType": "the object type", "objectId": "the object id or name", "params": {}}
<<<END_ACTION>>>

If the user's request requires multiple steps or is a complex task, create a plan instead of individual actions. Use this format:
<<<PLAN>>>
{
  "title": "Plan title",
  "description": "What this plan accomplishes",
  "steps": [
    {"id": "step1", "description": "First step description", "actionId": "action.id", "objectType": "type", "objectId": "id or name", "params": {}, "dependsOn": []},
    {"id": "step2", "description": "Second step", "actionId": "action.id", "objectType": "type", "objectId": "id or name", "params": {}, "dependsOn": ["step1"]}
  ]
}
<<<END_PLAN>>>

Plans are executed step by step, respecting dependencies. Use plans when:
- The task has 3+ steps
- Steps depend on each other
- You need to create agents or resources before using them
- The user asks you to "do" something complex

For cross-application workflows that chain multiple actions together with data flow between steps, use this format:
<<<CHAIN>>>
{
  "title": "Workflow title",
  "steps": [
    {
      "name": "Step name",
      "actionId": "action.id",
      "objectType": "type",
      "objectId": "id",
      "params": {},
      "inputMappings": [{"source": "previous_step.output_key", "target": "param_name"}]
    }
  ]
}
<<</CHAIN>>>

Use chains when:
- You need to pass data from one action's output to another action's input
- The workflow spans multiple domains (e.g., search → share → notify)
- You need automated multi-step execution

Guidelines:
- Always think step by step before answering
- If you need to use a tool, explain why
- Be honest about uncertainty
- Remember user preferences and context across conversations
- When the user asks you to do something (not just answer a question), try to identify the appropriate action
- Use entity.search to find objects by name or content before acting on them
- Use cognitive.recall to retrieve past conversations and memories

[Reminder System]
You can set, list, and cancel reminders for the user. Use these actions:
- reminder.set: Set a reminder. Params: {"time": "natural language time", "title": "reminder title", "description": "details"}
  Time examples: "10分钟后", "30分钟后", "1小时后", "明天9点", "下午3点", "明天下午2:30", "every 30 minutes", "每天"
- reminder.list: List all active reminders. No params needed.
- reminder.cancel: Cancel a reminder. Params: {"reminderId": "id from reminder.list"}

When the user says "提醒我...", "帮我记着...", "X分钟后叫我", "remind me...", "set a timer...", use reminder.set.

[Interoperability]
You can share and analyze content across the app:
- message.share_to_friend: Share a message to a friend. Params: {"content": "text to share"}
- message.analyze: Let AI analyze a message's content and find related memories. Params: {"content": "text to analyze"}
- message.summarize: Summarize recent messages in a chat room. Params: {"roomId": "room id"}

Users can trigger you directly in any chat by typing "@AI" or "@omni" followed by their question (e.g., "@AI summarize this chat", "@omni remind me in 10 minutes"). When you see a message starting with @AI/@omni, treat it as a direct command to you.

[Additional Actions]
- friend.add: Add a friend. Params: {"userId": "matrix user ID"}
- model.switch: Switch AI model. Params: {"modelId": "model id or name"} (e.g., "gpt-4", "claude-3", "gemini-pro")
- message.share_to_ai: Share a message to AI for analysis. Params: {"content": "text"}
$langSuffix

$memoryContext''';
  }

  Future<String> _buildMemoryContext({UnderstandingResult? understanding}) async {
    try {
      final cognitive = getIt<CognitiveEngine>();
      return await cognitive.buildMemoryContext(understanding: understanding);
    } catch (_) {
      return '';
    }
  }

  String _buildActionContext() {
    final registry = OmniObjectRegistry.instance;
    final buffer = StringBuffer();
    for (final type in OmniObjectType.values) {
      final actions = registry.getActionsForType(type);
      if (actions.isEmpty) continue;
      buffer.writeln('${type.name}:');
      for (final action in actions) {
        final destructive = action.isDestructive ? ' [DESTRUCTIVE]' : '';
        buffer.writeln('  - ${action.id}: ${action.description}$destructive');
      }
    }
    return buffer.toString();
  }

  String _buildCapabilityContext() {
    try {
      final capRegistry = getIt<CapabilityRegistry>();
      if (!capRegistry.isInitialized) return '';
      return '\n[Available Capabilities]\n${capRegistry.buildCapabilityContext()}';
    } catch (_) {
      return '';
    }
  }

  Future<List<ActionResult>> _executeActions(String response) async {
    final results = <ActionResult>[];
    final startMarker = '<<<ACTION>>>';
    final endMarker = '<<<END_ACTION>>>';
    var searchFrom = 0;

    while (true) {
      final startIdx = response.indexOf(startMarker, searchFrom);
      if (startIdx < 0) break;
      final endIdx = response.indexOf(endMarker, startIdx);
      if (endIdx < 0) break;

      final actionJson = response.substring(startIdx + startMarker.length, endIdx).trim();
      searchFrom = endIdx + endMarker.length;

      try {
        final json = jsonDecode(actionJson) as Map<String, dynamic>;
        final actionId = json['actionId'] as String? ?? '';
        final objectTypeStr = json['objectType'] as String? ?? '';
        final objectId = json['objectId'] as String? ?? '';
        final params = json['params'] as Map<String, dynamic>? ?? {};

        final objectType = OmniObjectType.values.firstWhere(
          (e) => e.name == objectTypeStr,
          orElse: () => OmniObjectType.message,
        );

        final registry = OmniObjectRegistry.instance;
        var targetObj = registry.getObject(objectId);
        targetObj ??= registry.findObject(objectId);

        if (targetObj == null) {
          targetObj = await _resolveObjectFromServices(objectId, objectType, params);
          if (targetObj != null) {
            registry.registerObject(targetObj);
          }
        }

        if (targetObj == null) {
          results.add(ActionResult.failure(actionId, objectId, 'Object not found: $objectId'));
          continue;
        }

        final actions = registry.getActionsForObject(targetObj);
        final action = actions.firstWhere(
          (a) => a.id == actionId,
          orElse: () => OmniAction(
            id: actionId,
            name: actionId,
            description: 'Dynamic action',
            objectTypeId: objectType.name,
            capabilityId: actionId,
          ),
        );

        final result = await ActionExecutor.instance.execute(action, targetObj, params);
        results.add(result);
      } catch (e) {
        AppLogger.instance.warning('Action execution failed', error: e);
      }
    }

    return results;
  }

  Future<OmniObject?> _resolveObjectFromServices(
    String objectId,
    OmniObjectType objectType,
    Map<String, dynamic> params,
  ) async {
    try {
      switch (objectType) {
        case OmniObjectType.chatRoom:
          return _resolveChatRoom(objectId, params);
        case OmniObjectType.message:
          return _resolveMessage(objectId, params);
        case OmniObjectType.note:
          return _resolveNote(objectId, params);
        case OmniObjectType.project:
          return _resolveProject(objectId, params);
        case OmniObjectType.file:
          return _resolveFile(objectId, params);
        case OmniObjectType.agent:
          return _resolveAgent(objectId, params);
        default:
          return null;
      }
    } catch (e) {
      AppLogger.instance.warning('Failed to resolve object from services', error: e);
      return null;
    }
  }

  OmniObject? _resolveChatRoom(String roomId, Map<String, dynamic> params) {
    try {
      final matrixCubit = getIt<MatrixCubit>();
      final rooms = matrixCubit.rooms;
      final cleanId = roomId.replaceFirst('room_', '');
      for (final room in rooms) {
        if (room.id == cleanId || room.displayName.toLowerCase().contains(roomId.toLowerCase())) {
          return ChatRoomObject(
            roomId: room.id,
            name: room.displayName ?? 'Chat',
            isDirect: room.isDirect ?? false,
            isGroup: !(room.isDirect ?? true),
            memberIds: [],
            unreadCount: room.notificationCount ?? 0,
          );
        }
      }
      if (roomId.isNotEmpty && !roomId.startsWith('room_')) {
        return ChatRoomObject(
          roomId: cleanId,
          name: params['name'] as String? ?? roomId,
          isDirect: true,
          isGroup: false,
          memberIds: [],
          unreadCount: 0,
        );
      }
    } catch (_) {}
    return null;
  }

  OmniObject? _resolveMessage(String messageId, Map<String, dynamic> params) {
    try {
      final content = params['content'] as String? ?? '';
      final roomId = params['roomId'] as String? ?? '';
      final senderId = params['senderId'] as String? ?? '';
      if (messageId.startsWith('msg_') && content.isNotEmpty) {
        return ChatMessageObject(
          messageId: messageId.replaceFirst('msg_', ''),
          roomId: roomId,
          senderId: senderId,
          content: content,
          timestamp: DateTime.now(),
          isOwn: senderId.isEmpty || senderId == 'me',
        );
      }
    } catch (_) {}
    return null;
  }

  OmniObject? _resolveNote(String noteId, Map<String, dynamic> params) {
    try {
      final noteService = getIt<NoteService>();
      final notes = noteService.getNotes();
      final cleanId = noteId.replaceFirst('note_', '');
      for (final note in notes) {
        if (note.id == cleanId || note.title.toLowerCase().contains(noteId.toLowerCase())) {
          return NoteObject(
            noteId: note.id,
            title: note.title,
            content: note.content ?? '',
            type: note.type?.name ?? 'text',
            isDone: note.isDone ?? false,
            updatedAt: note.updatedAt ?? DateTime.now(),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  OmniObject? _resolveProject(String projectId, Map<String, dynamic> params) {
    try {
      final ws = getIt<WorkspaceService>();
      if (!ws.isInitialized) return null;
      final workspaces = ws.workspaces;
      final cleanId = projectId.replaceFirst('project_', '');
      for (final w in workspaces) {
        if (w.id == cleanId || w.name.toLowerCase().contains(projectId.toLowerCase())) {
          return ProjectObject(
            projectId: w.id,
            name: w.name,
            domain: w.domain ?? 'project',
            status: 'active',
            entityNames: w.entities.map((e) => e.name).toList(),
            goalCount: w.goals.length,
            lastActiveAt: DateTime.now(),
            recentTimeline: const [],
          );
        }
      }
    } catch (_) {}
    return null;
  }

  OmniObject? _resolveFile(String fileId, Map<String, dynamic> params) {
    try {
      final path = params['path'] as String? ?? '';
      final name = params['name'] as String? ?? fileId.replaceFirst('file_', '');
      if (fileId.isNotEmpty || path.isNotEmpty) {
        return FileObject(
          fileId: fileId.replaceFirst('file_', ''),
          name: name.isNotEmpty ? name : path.split('/').last,
          path: path,
          mimeType: params['mimeType'] as String? ?? 'application/octet-stream',
          modifiedAt: DateTime.now(),
        );
      }
    } catch (_) {}
    return null;
  }

  OmniObject? _resolveAgent(String agentId, Map<String, dynamic> params) {
    try {
      final agentService = getIt<AgentService>();
      final agents = agentService.getAllAgents();
      final cleanId = agentId.replaceFirst('agent_', '');
      for (final agent in agents) {
        if (agent.id == cleanId || agent.name.toLowerCase().contains(agentId.toLowerCase())) {
          return AgentObject(
            agentId: agent.id,
            name: agent.name,
            role: agent.role.name,
            status: agent.lifecycle.name,
            capabilities: agent.capabilities,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _executePlan(String response) async {
    final startMarker = '<<<PLAN>>>';
    final endMarker = '<<<END_PLAN>>>';
    final startIdx = response.indexOf(startMarker);
    if (startIdx < 0) return;
    final endIdx = response.indexOf(endMarker, startIdx);
    if (endIdx < 0) return;

    final planJson = response.substring(startIdx + startMarker.length, endIdx).trim();
    try {
      final json = jsonDecode(planJson) as Map<String, dynamic>;
      final planningEngine = getIt<PlanningEngine>();
      if (!planningEngine.isInitialized) await planningEngine.init();

      final plan = planningEngine.parsePlanFromJson(json);
      if (plan == null) return;

      final created = await planningEngine.createAndApprove(
        title: plan.title,
        description: plan.description,
        projectId: plan.projectId,
        steps: plan.steps,
      );

      await planningEngine.executePlan(created.id);
      AppLogger.instance.info('Plan executed: ${created.title} (${created.id})');
    } catch (e) {
      AppLogger.instance.warning('Plan execution failed', error: e);
    }
  }

  Future<void> _executeChain(String response) async {
    final startMarker = '<<<CHAIN>>>';
    final endMarker = '<<</CHAIN>>>';
    final startIdx = response.indexOf(startMarker);
    if (startIdx < 0) return;
    final endIdx = response.indexOf(endMarker, startIdx);
    if (endIdx < 0) return;

    try {
      final crossApp = getIt<CrossAppActionEngine>();
      if (!crossApp.isInitialized) await crossApp.init();

      final chain = crossApp.parseChainFromAIOutput(
        response,
        workspaceId: getIt<CognitiveEngine>().activeWorkspaceId,
      );
      if (chain == null) return;

      final result = await crossApp.executeChain(chain.id);
      AppLogger.instance.info(
        'Chain executed: ${chain.title} (${result.status.name}, ${result.completedSteps}/${result.totalSteps})',
      );
    } catch (e) {
      AppLogger.instance.warning('Chain execution failed', error: e);
    }
  }

  String? _agentLanguage;
  void setAgentLanguage(String lang) {
    _agentLanguage = lang;
  }

  void interrupt() {
    if (_activeTask != null) {
      _completeActiveTask(success: false, output: 'Interrupted by user');
    }
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
  Future<void> close() {
    _disposed = true;
    _throttleTimer?.cancel();
    _cardRuntime.dispose();
    _streamingController.dispose();
    return super.close();
  }
}

class _SkillPluginHandler implements PluginHandler {
  final Skill _skill;

  _SkillPluginHandler(this._skill);

  @override
  Future<HandlerResult> handleMessage(
    RuntimeMessage message,
    CapabilityContext context) async {
    return HandlerResult.ok();
  }

  @override
  Future<HandlerResult> handleEvent(
    RuntimeEvent event,
    CapabilityContext context) async {
    return HandlerResult.ok();
  }

  @override
  Future<CapabilityResult> invokeCapability(
    String capabilityId,
    dynamic params,
    CapabilityContext context) async {
    if (capabilityId == 'skill.${_skill.id}.execute') {
      final permission = await _checkPermission(capabilityId);
      if (permission == 'deny') {
        return CapabilityResult.fail(
          RuntimeError(
            code: 'PERMISSION_DENIED',
            message: 'Capability $capabilityId is denied by user'));
      }
      if (permission == 'confirm') {
        final granted = await _requestConfirmation(capabilityId);
        if (!granted) {
          return CapabilityResult.fail(
            RuntimeError(
              code: 'PERMISSION_DENIED',
              message: 'User denied $capabilityId'));
        }
      }
      try {
        final result = await _skill.execute(
          params is Map<String, dynamic> ? params : {'input': params});
        return CapabilityResult.ok(result);
      } catch (e) {
        return CapabilityResult.fail(
          RuntimeError(code: 'SKILL_ERROR', message: e.toString()));
      }
    }
    return CapabilityResult.fail(
      RuntimeError(
        code: 'UNKNOWN_CAPABILITY',
        message: 'Unknown: $capabilityId'));
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
        callback: handler);
    }

    NotificationCenter.observe(Event.capabilityConfirm, handler);
    NotificationCenter.post(
      Event.capabilityConfirm,
      data: {'capabilityId': capabilityId, 'pending': true});
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => false);
  }
}
