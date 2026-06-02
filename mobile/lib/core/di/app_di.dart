import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import '../notification/notification_cubit.dart';
import '../session_cubit.dart';
import '../quick_command_cubit.dart';
import '../note_cubit.dart';
import '../matrix/matrix_cubit.dart';
import '../navigation_cubit.dart';
import '../model_cubit.dart';
import '../../presentation/theme/theme_cubit.dart';
import '../../presentation/theme/locale_cubit.dart';
import '../agent/agent_orchestrator.dart';
import '../agent/agent_reminder_service.dart' show ReminderService;
import '../agent/embedding_service.dart';
import '../agent/cognitive/cognitive_engine.dart';
import '../agent/cognitive/entity_store.dart';
import '../agent/cognitive/goal_store.dart';
import '../agent/cognitive/understanding_engine.dart';
import '../agent/cognitive/working_memory.dart';
import '../agent/cognitive/attention_engine.dart';
import '../agent/cognitive/recall_engine.dart';
import '../agent/cognitive/speaker_graph.dart';
import '../agent/cognitive/episodic_memory.dart';
import '../agent/cognitive/procedural_memory.dart';
import '../agent/cognitive/perception_engine.dart';
import '../agent/cognitive/reasoning_engine.dart';
import '../agent/cognitive/prediction_engine.dart';
import '../agent/cognitive/self_evolution.dart';
import '../agent/cognitive/multi_agent_society.dart';
import '../agent/runtime/agent_runtime.dart';
import '../agent/runtime/context_assembly_engine.dart';
import '../agent/runtime/conflict_resolver.dart';
import '../agent/runtime/identity_engine.dart';
import '../agent/runtime/priority_manager.dart';
import '../agent/runtime/task_scheduler.dart';
import '../runtime/sdk/omnivium_sdk.dart';
import '../runtime/vocabulary/runtime_event.dart';
import '../runtime/vocabulary/runtime_identity.dart';
import '../notification_center.dart' show NotificationCenter, Event;
import '../identity_bridge.dart';
import '../voice_service.dart';
import '../app_logger.dart';
import '../secure_storage_service.dart';
import '../database_service.dart';
import '../connectivity_service.dart';
import '../api_proxy_service.dart';
import '../auth_service.dart';
import '../supabase_sync_service.dart';
import '../remote_config_service.dart';
import '../push_notification_service.dart';
import '../deep_link_service.dart';
import '../matrix/matrix_service.dart' show MatrixService;
import '../call_service.dart';
import '../note_service.dart';
import '../encryption_service.dart';
import '../analytics_service.dart';
import '../totp_service.dart';
import '../password_key_service.dart';
import '../app_lock_service.dart';
import '../biometric_service.dart';
import '../app_data_gateway.dart';
import '../permission_service.dart';
import '../providers/ai_provider.dart' show ChatService;
import '../app_capability_service.dart';
import '../remote_ui_engine.dart' show RemoteUIActionHandler;
import '../omni_model.dart';
import '../cognitive_plugin.dart';
import '../state_service.dart';
import '../workspace_service.dart';
import '../tool_memory.dart';
import '../skill_bridge.dart';
import '../skills/skill_registry.dart';
import '../skills/action_handler_skill.dart';
import '../agent_service.dart';
import '../action_executor.dart';
import '../planning_engine.dart';
import '../action_handlers.dart';
import '../capability_system.dart';
import '../capability_definitions.dart';
import '../world_state_service.dart';
import '../capability_graph.dart';
import '../cross_app_action_engine.dart';
import '../workspace_graph.dart';
import '../event_store.dart';
import '../knowledge_layer.dart';
import '../file_download_service.dart';
import '../lite_mode.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/chat/domain/repositories/i_chat_repository.dart';
import '../../features/chat/domain/usecases/send_message_usecase.dart';
import '../../features/chat/domain/usecases/get_messages_usecase.dart';
import '../../features/chat/domain/usecases/get_rooms_usecase.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/contacts/domain/repositories/i_contacts_repository.dart';
import '../../features/contacts/domain/usecases/contacts_usecases.dart';
import '../../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/agent/domain/repositories/i_agent_repository.dart';
import '../../features/agent/data/repositories/agent_repository_impl.dart';
import '../../features/agent/presentation/bloc/agent_bloc.dart';
import '../../features/call/domain/repositories/i_call_repository.dart';
import '../../features/call/presentation/bloc/call_bloc.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/call/data/repositories/call_repository_impl.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  _registerCoreServices();
  _registerRepositories();
  _registerUseCases();
  _registerBlocs();
  AppLogger.instance.info('Dependencies initialized');
}

Future<void> initSubProviders() async {
  await _connectRuntime();
  _startTaskScheduler();
  try {
    await getIt<NotificationCubit>().init();
  } catch (e, stackTrace) {
    AppLogger.instance.error('NotificationCubit init failed', error: e, stackTrace: stackTrace);
  }
  try {
    await getIt<SessionCubit>().loadSessions();
  } catch (e, stackTrace) {
    AppLogger.instance.error('SessionCubit init failed', error: e, stackTrace: stackTrace);
  }
  try {
    await getIt<QuickCommandCubit>().init();
  } catch (e, stackTrace) {
    AppLogger.instance.error('QuickCommandCubit init failed', error: e, stackTrace: stackTrace);
  }
  try {
    await getIt<NoteCubit>().init();
  } catch (e, stackTrace) {
    AppLogger.instance.error('NoteCubit init failed', error: e, stackTrace: stackTrace);
  }
  getIt<NotificationCubit>().listenToMatrix(getIt<MatrixCubit>());
}

void _startTaskScheduler() {
  try {
    final scheduler = getIt<TaskScheduler>();
    final db = getIt<DatabaseService>();

    scheduler.registerJob(ScheduledJob(
      id: 'memory_decay',
      name: 'Memory Decay',
      interval: const Duration(hours: 24),
      callback: () async {
        final cognitive = getIt<CognitiveEngine>();
        await cognitive.runDecay(db);
      },
    ));

    scheduler.registerJob(ScheduledJob(
      id: 'goal_deadline_check',
      name: 'Goal Deadline Check',
      interval: const Duration(hours: 6),
      callback: () async {},
    ));

    scheduler.start();
    AppLogger.instance.info('TaskScheduler started with default jobs');
  } catch (e, stackTrace) {
    AppLogger.instance.error('TaskScheduler start failed', error: e, stackTrace: stackTrace);
  }
}

Future<void> _connectRuntime() async {
  final sdk = OmniviumSDK.instance;
  if (!sdk.isInitialized) return;
  getIt<AgentOrchestrator>().connectRuntime(sdk);
  final bridge = getIt<IdentityBridge>();
  if (bridge.isBound) {
    sdk.container.updateIdentity(RuntimeIdentity.forPlugin(bridge.nodeId));
  }
  _registerCognitivePlugin(sdk);
  _registerObjectActions();
  _subscribeRuntimeEvents(sdk);
  await _bridgeSkills(sdk);
  await _initAgentService();
  _registerActionHandlers();
  ReminderService.instance.startChecking();
}

Future<void> _initAgentService() async {
  try {
    final stateService = getIt<StateService>();
    if (!stateService.isInitialized) await stateService.init();
    final agentService = getIt<AgentService>();
    if (!agentService.isInitialized) await agentService.init();
    final planningEngine = getIt<PlanningEngine>();
    if (!planningEngine.isInitialized) await planningEngine.init();
    final capRegistry = getIt<CapabilityRegistry>();
    if (!capRegistry.isInitialized) {
      await capRegistry.init();
      CapabilityDefinitions.registerAll(capRegistry);
      await capRegistry.persist();
    }
    final worldState = getIt<WorldStateService>();
    if (!worldState.isInitialized) {
      await worldState.init();
      await worldState.refreshFromSources();
    }
    final capGraph = getIt<CapabilityGraph>();
    if (!capGraph.isInitialized) {
      await capGraph.init();
      capGraph.buildFromRegistry(capRegistry);
      await capGraph.persist();
    }
    final crossApp = getIt<CrossAppActionEngine>();
    if (!crossApp.isInitialized) await crossApp.init();
    final wsGraph = getIt<WorkspaceGraph>();
    if (!wsGraph.isInitialized) {
      await wsGraph.init();
      await wsGraph.buildFromSources();
    }
    final eventStore = getIt<EventStore>();
    if (!eventStore.isInitialized) await eventStore.init();
    final knowledge = getIt<KnowledgeLayerService>();
    if (!knowledge.isInitialized) await knowledge.init();
  } catch (e, st) {
    AppLogger.instance.error('AgentService init failed', error: e, stackTrace: st);
  }
}

void _registerActionHandlers() {
  ActionHandlerRegistry.registerAll();
  _registerActionHandlerSkills();
}

void _registerActionHandlerSkills() {
  try {
    final skillRegistry = getIt<SkillRegistry>();
    final skills = [
      ActionHandlerSkill(actionId: 'chatroom.send_message', objectType: OmniObjectType.chatRoom, name: 'Send Message', description: 'Send a message to a chat room', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'message.forward', objectType: OmniObjectType.message, name: 'Forward Message', description: 'Forward a message to another room', permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'message.delete', objectType: OmniObjectType.message, name: 'Delete Message', description: 'Delete a message', isDestructive: true, permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'message.share_to_plaza', objectType: OmniObjectType.message, name: 'Share to Plaza', description: 'Share a message to the public plaza', permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'chatroom.invite', objectType: OmniObjectType.chatRoom, name: 'Invite User', description: 'Invite a user to a chat room', permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'note.edit', objectType: OmniObjectType.note, name: 'Edit Note', description: 'Edit a note', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'note.create', objectType: OmniObjectType.note, name: 'Create Note', description: 'Create a new note', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'note.delete', objectType: OmniObjectType.note, name: 'Delete Note', description: 'Delete a note', isDestructive: true, permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'note.toggle_done', objectType: OmniObjectType.note, name: 'Toggle Done', description: 'Toggle note completion status', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'agent.assign_task', objectType: OmniObjectType.agent, name: 'Assign Task', description: 'Assign a task to an agent', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'agent.pause', objectType: OmniObjectType.agent, name: 'Pause Agent', description: 'Pause an agent', permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'agent.resume', objectType: OmniObjectType.agent, name: 'Resume Agent', description: 'Resume a paused agent', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'agent.destroy', objectType: OmniObjectType.agent, name: 'Destroy Agent', description: 'Destroy an agent permanently', isDestructive: true, permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'agent.spawn', objectType: OmniObjectType.agent, name: 'Spawn Agent', description: 'Spawn a child agent', permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'agent.team.create', objectType: OmniObjectType.agent, name: 'Create Team', description: 'Create an agent team', permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'file.open', objectType: OmniObjectType.file, name: 'Open File', description: 'Open a file', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'file.share', objectType: OmniObjectType.file, name: 'Share File', description: 'Share a file', permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'file.delete', objectType: OmniObjectType.file, name: 'Delete File', description: 'Delete a file', isDestructive: true, permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'project.open', objectType: OmniObjectType.project, name: 'Open Project', description: 'Open a project', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'project.create_task', objectType: OmniObjectType.project, name: 'Create Task', description: 'Create a task in a project', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'project.archive', objectType: OmniObjectType.project, name: 'Archive Project', description: 'Archive a project', permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'plan.create', objectType: OmniObjectType.project, name: 'Create Plan', description: 'Create an execution plan', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'entity.search', objectType: OmniObjectType.message, name: 'Search', description: 'Search for entities across the system', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'cognitive.recall', objectType: OmniObjectType.agent, name: 'Recall', description: 'Recall memories and past conversations', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'reminder.set', objectType: OmniObjectType.agent, name: 'Set Reminder', description: 'Set a reminder with natural language time', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'reminder.list', objectType: OmniObjectType.agent, name: 'List Reminders', description: 'List all active reminders', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'reminder.cancel', objectType: OmniObjectType.agent, name: 'Cancel Reminder', description: 'Cancel a reminder', permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'friend.add', objectType: OmniObjectType.chatRoom, name: 'Add Friend', description: 'Add a friend by user ID', permission: PermissionLevel.confirm),
      ActionHandlerSkill(actionId: 'model.switch', objectType: OmniObjectType.agent, name: 'Switch Model', description: 'Switch the AI model', permission: PermissionLevel.auto),
      ActionHandlerSkill(actionId: 'message.share_to_ai', objectType: OmniObjectType.message, name: 'Share to AI', description: 'Share a message to AI for analysis', permission: PermissionLevel.auto),
    ];
    for (final skill in skills) {
      skillRegistry.register(skill);
    }
    AppLogger.instance.info('Registered ${skills.length} ActionHandler skills');
  } catch (e) {
    AppLogger.instance.warning('Failed to register ActionHandler skills', error: e);
  }
}

Future<void> _bridgeSkills(OmniviumSDK sdk) async {
  try {
    final toolMemory = getIt<ToolMemory>();
    if (!toolMemory.isInitialized) await toolMemory.init();
    await SkillBridge.registerSkillsAsPlugins();
  } catch (e, st) {
    AppLogger.instance.error('SkillBridge registration failed', error: e, stackTrace: st);
  }
}

void _registerCognitivePlugin(OmniviumSDK sdk) {
  try {
    final descriptor = CognitivePlugin.descriptor();
    final handler = CognitivePlugin.handler();
    sdk.container.registerPlugin(descriptor, handler).then((_) {
      sdk.container.activatePlugin(descriptor.id);
      AppLogger.instance.info('CognitivePlugin registered and activated');
    });
  } catch (e, stackTrace) {
    AppLogger.instance.error('CognitivePlugin registration failed', error: e, stackTrace: stackTrace);
  }
}

void _registerObjectActions() {
  final registry = OmniObjectRegistry.instance;
  for (final type in OmniObjectType.values) {
    switch (type) {
      case OmniObjectType.message:
        registry.registerAction(type, OmniAction(id: 'message.copy', name: '复制', description: '复制消息', objectTypeId: type.name, capabilityId: 'chat.message.copy', permission: 'auto'));
        registry.registerAction(type, OmniAction(id: 'message.forward', name: '转发', description: '转发消息', objectTypeId: type.name, capabilityId: 'chat.message.forward', permission: 'confirm'));
        registry.registerAction(type, OmniAction(id: 'message.share_to_plaza', name: '分享到广场', description: '分享到广场', objectTypeId: type.name, capabilityId: 'chat.message.shareToPlaza', permission: 'confirm'));
        registry.registerAction(type, OmniAction(id: 'message.delete', name: '删除', description: '删除消息', objectTypeId: type.name, capabilityId: 'chat.message.delete', isDestructive: true, permission: 'confirm'));
        break;
      case OmniObjectType.chatRoom:
        registry.registerAction(type, OmniAction(id: 'chatroom.send_message', name: '发送消息', description: '发送消息', objectTypeId: type.name, capabilityId: 'chat.room.sendMessage', permission: 'auto'));
        registry.registerAction(type, OmniAction(id: 'chatroom.invite', name: '邀请', description: '邀请成员', objectTypeId: type.name, capabilityId: 'chat.room.invite', permission: 'confirm'));
        registry.registerAction(type, OmniAction(id: 'chatroom.create_agent', name: '创建Agent', description: '创建Agent', objectTypeId: type.name, capabilityId: 'chat.room.createAgent', permission: 'confirm'));
        break;
      case OmniObjectType.agent:
        registry.registerAction(type, OmniAction(id: 'agent.assign_task', name: '分配任务', description: '分配任务', objectTypeId: type.name, capabilityId: 'agent.task.assign', permission: 'auto'));
        registry.registerAction(type, OmniAction(id: 'agent.pause', name: '暂停', description: '暂停Agent', objectTypeId: type.name, capabilityId: 'agent.lifecycle.pause', permission: 'confirm'));
        registry.registerAction(type, OmniAction(id: 'agent.resume', name: '恢复', description: '恢复Agent运行', objectTypeId: type.name, capabilityId: 'agent.lifecycle.resume', permission: 'auto'));
        registry.registerAction(type, OmniAction(id: 'agent.destroy', name: '销毁', description: '销毁Agent', objectTypeId: type.name, capabilityId: 'agent.lifecycle.destroy', isDestructive: true, permission: 'confirm'));
        break;
      case OmniObjectType.file:
        registry.registerAction(type, OmniAction(id: 'file.open', name: '打开', description: '打开文件', objectTypeId: type.name, capabilityId: 'file.open', permission: 'auto'));
        registry.registerAction(type, OmniAction(id: 'file.share', name: '分享', description: '分享文件', objectTypeId: type.name, capabilityId: 'file.share', permission: 'confirm'));
        registry.registerAction(type, OmniAction(id: 'file.delete', name: '删除', description: '删除文件', objectTypeId: type.name, capabilityId: 'file.delete', isDestructive: true, permission: 'confirm'));
        break;
      case OmniObjectType.note:
        registry.registerAction(type, OmniAction(id: 'note.edit', name: '编辑', description: '编辑笔记', objectTypeId: type.name, capabilityId: 'note.edit', permission: 'auto'));
        registry.registerAction(type, OmniAction(id: 'note.toggle_done', name: '切换完成', description: '标记完成/未完成', objectTypeId: type.name, capabilityId: 'note.toggleDone', permission: 'auto'));
        registry.registerAction(type, OmniAction(id: 'note.create', name: '创建笔记', description: '创建新笔记', objectTypeId: type.name, capabilityId: 'note.create', permission: 'auto'));
        registry.registerAction(type, OmniAction(id: 'note.delete', name: '删除', description: '删除笔记', objectTypeId: type.name, capabilityId: 'note.delete', isDestructive: true, permission: 'confirm'));
        break;
      case OmniObjectType.project:
        registry.registerAction(type, OmniAction(id: 'project.open', name: '打开项目', description: '恢复项目上下文', objectTypeId: type.name, capabilityId: 'project.open', permission: 'auto'));
        registry.registerAction(type, OmniAction(id: 'project.create_task', name: '创建任务', description: '在项目中创建任务', objectTypeId: type.name, capabilityId: 'project.createTask', permission: 'auto'));
        registry.registerAction(type, OmniAction(id: 'project.archive', name: '归档', description: '归档项目', objectTypeId: type.name, capabilityId: 'project.archive', permission: 'confirm'));
        registry.registerAction(type, OmniAction(id: 'plan.create', name: '创建计划', description: '为项目创建执行计划', objectTypeId: type.name, capabilityId: 'plan.create', permission: 'auto'));
        break;
      default:
        break;
    }
  }
  AppLogger.instance.info('Object actions registered');
}

void _subscribeRuntimeEvents(OmniviumSDK sdk) {
  final eventTypes = ['plugin', 'sandbox', 'capability', 'state'];
  for (final prefix in eventTypes) {
    sdk.container.eventBus.subscribe(prefix, (RuntimeEvent event) async {
      final eventType = event.type;
      final data = event.payload;
      if (eventType.startsWith('plugin.')) {
        NotificationCenter.post(Event.settingsUpdated, data: {'source': 'runtime', 'type': eventType});
      } else if (eventType.startsWith('sandbox.')) {
        NotificationCenter.post(Event.securityAlert, data: {'source': 'runtime', 'type': eventType, if (data != null) ...data as Map<String, dynamic>});
      } else if (eventType.startsWith('capability.')) {
        NotificationCenter.post(Event.agentSkillInvoked, data: {'source': 'runtime', 'type': eventType, if (data != null) ...data as Map<String, dynamic>});
      } else if (eventType.startsWith('state.')) {
        NotificationCenter.post(Event.agentSkillInvoked, data: {'source': 'state', 'type': eventType, if (data != null) ...data as Map<String, dynamic>});
      }
    }, permission: EventPermission.observe);
  }
}

void disposeAll() {
  try { getIt<TaskScheduler>().dispose(); } catch (_) {}
  getIt<CognitiveEngine>().dispose();
  getIt<NavigationCubit>().close();
  getIt<ModelCubit>().close();
  getIt<SessionCubit>().close();
  getIt<MatrixCubit>().close();
  getIt<AgentOrchestrator>().close();
  getIt<NotificationCubit>().close();
  getIt<QuickCommandCubit>().close();
  getIt<NoteCubit>().close();
  getIt<ThemeCubit>().close();
  getIt<LocaleCubit>().close();
  getIt<VoiceService>().dispose();
}

Future<void> resetDependencies() async {
  await getIt.reset();
  AppLogger.instance.info('Dependencies reset');
}

void _registerCoreServices() {
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService.instance);
  getIt.registerLazySingleton<DatabaseService>(
    () => DatabaseService.instance);
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService.instance);
  getIt.registerLazySingleton<ApiProxyService>(
    () => ApiProxyService.instance);
  getIt.registerLazySingleton<AuthService>(() => AuthService.instance);
  getIt.registerLazySingleton<SupabaseSyncService>(
    () => SupabaseSyncService.instance);
  getIt.registerLazySingleton<RemoteConfigService>(
    () => RemoteConfigService.instance);
  getIt.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService.instance);
  getIt.registerLazySingleton<DeepLinkService>(
    () => DeepLinkService.instance);
  getIt.registerLazySingleton<VoiceService>(() => VoiceService.instance);
  getIt.registerLazySingleton<EmbeddingService>(
    () => EmbeddingService.instance);
  getIt.registerLazySingleton<EntityStore>(
    () => EntityStore(getIt()));
  getIt.registerLazySingleton<GoalStore>(
    () => GoalStore(getIt()));
  getIt.registerLazySingleton<WorkspaceService>(
    () => WorkspaceService(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton<StateService>(
    () => StateService(getIt()));
  getIt.registerLazySingleton<ToolMemory>(
    () => ToolMemory(getIt()));
  getIt.registerLazySingleton<SkillRegistry>(
    () => SkillRegistry());
  getIt.registerLazySingleton<AgentService>(
    () => AgentService(getIt()));
  getIt.registerLazySingleton<PlanningEngine>(
    () => PlanningEngine(getIt()));
  getIt.registerLazySingleton<CapabilityRegistry>(
    () => CapabilityRegistry(getIt()));
  getIt.registerLazySingleton<CapabilityExecutor>(
    () => CapabilityExecutor(getIt(), ActionExecutor.instance));
  getIt.registerLazySingleton<WorldStateService>(
    () => WorldStateService(getIt()));
  getIt.registerLazySingleton<CapabilityGraph>(
    () => CapabilityGraph(getIt()));
  getIt.registerLazySingleton<CrossAppActionEngine>(
    () => CrossAppActionEngine(getIt()));
  getIt.registerLazySingleton<WorkspaceGraph>(
    () => WorkspaceGraph(getIt()));
  getIt.registerLazySingleton<EventStore>(
    () => EventStore(getIt()));
  getIt.registerLazySingleton<KnowledgeLayerService>(
    () => KnowledgeLayerService(getIt()));
  getIt.registerLazySingleton<UnderstandingEngine>(
    () => UnderstandingEngine());
  getIt.registerLazySingleton<WorkingMemory>(
    () => WorkingMemory());
  getIt.registerLazySingleton<SpeakerGraph>(
    () => SpeakerGraph(getIt()));
  getIt.registerLazySingleton<EpisodicMemoryStore>(
    () => EpisodicMemoryStore(getIt()));
  getIt.registerLazySingleton<ProceduralMemoryStore>(
    () => ProceduralMemoryStore(getIt()));
  getIt.registerLazySingleton<CognitiveEngine>(
    () => CognitiveEngine(
      entityStore: getIt(),
      goalStore: getIt(),
      understandingEngine: getIt(),
      workingMemory: getIt(),
      speakerGraph: getIt(),
      episodicMemoryStore: getIt(),
      proceduralMemoryStore: getIt(),
      attentionEngine: AttentionEngine(
        workingMemory: getIt(),
        entityStore: getIt(),
        goalStore: getIt(),
      ),
      recallEngine: RecallEngine(
        entityStore: getIt(),
        goalStore: getIt(),
        workingMemory: getIt(),
        episodicMemoryStore: getIt(),
      ),
      perceptionEngine: PerceptionEngine(
        entityStore: getIt(),
        speakerGraph: getIt(),
      ),
      reasoningEngine: ReasoningEngine(
        entityStore: getIt(),
        goalStore: getIt(),
        workingMemory: getIt(),
      ),
      predictionEngine: PredictionEngine(
        entityStore: getIt(),
        goalStore: getIt(),
      ),
      selfEvolutionEngine: SelfEvolutionEngine(
        entityStore: getIt(),
        goalStore: getIt(),
        proceduralMemoryStore: getIt(),
      ),
      multiAgentSociety: MultiAgentSociety(getIt()),
      conflictResolver: ConflictResolver(
        entityStore: getIt(),
        goalStore: getIt(),
        db: getIt(),
      ),
      identityEngine: IdentityEngine(
        entityStore: getIt(),
        goalStore: getIt(),
        db: getIt(),
      ),
      contextAssemblyEngine: ContextAssemblyEngine(
        entityStore: getIt(),
        goalStore: getIt(),
        workingMemory: getIt(),
        attentionEngine: getIt(),
        recallEngine: getIt(),
        proceduralMemoryStore: getIt(),
      ),
      priorityManager: PriorityManager(
        goalStore: getIt(),
        entityStore: getIt(),
      ),
      agentRuntime: AgentRuntime(),
    ));
  getIt.registerLazySingleton<TaskScheduler>(
    () => TaskScheduler(
      runtime: getIt<CognitiveEngine>().agentRuntime,
      priorityManager: getIt<CognitiveEngine>().priorityManager,
      goalStore: getIt(),
    ));
  getIt.registerLazySingleton<AgentOrchestrator>(
    () => AgentOrchestrator());
  getIt.registerLazySingleton<ModelCubit>(
    () => ModelCubit(orchestrator: getIt()));
  getIt.registerLazySingleton<MatrixService>(() => MatrixService.instance);
  getIt.registerLazySingleton<CallService>(() => CallService.instance);
  getIt.registerLazySingleton<NoteService>(() => NoteService.instance);
  getIt.registerLazySingleton<EncryptionService>(
    () => EncryptionService.instance);
  getIt.registerLazySingleton<IdentityBridge>(
    () => IdentityBridge.instance);
  getIt.registerLazySingleton<NotificationCenter>(
    () => NotificationCenter.instance);
  getIt.registerLazySingleton<AnalyticsService>(
    () => AnalyticsService.instance);
  getIt.registerLazySingleton<TotpService>(() => TotpService.instance);
  getIt.registerLazySingleton<PasswordKeyService>(
    () => PasswordKeyService.instance);
  getIt.registerLazySingleton<AppLockService>(
    () => AppLockService.instance);
  getIt.registerLazySingleton<BiometricService>(
    () => BiometricService.instance);
  getIt.registerLazySingleton<AppLogger>(() => AppLogger.instance);
  getIt.registerLazySingleton<AppDataGateway>(
    () => AppDataGateway.instance);
  getIt.registerLazySingleton<PermissionService>(
    () => PermissionService.instance);
  getIt.registerLazySingleton<ChatService>(() => ChatService.instance);
  getIt.registerLazySingleton<AppCapabilityService>(
    () => AppCapabilityService.instance);
  getIt.registerLazySingleton<RemoteUIActionHandler>(
    () => RemoteUIActionHandler.instance);
  getIt.registerLazySingleton<FileDownloadService>(
    () => FileDownloadService.instance);
  getIt.registerLazySingleton<LiteMode>(() => LiteMode.instance);
  getIt.registerLazySingleton<NavigationCubit>(
    () => NavigationCubit());
  getIt.registerLazySingleton<MatrixCubit>(() => MatrixCubit());
  getIt.registerLazySingleton<NotificationCubit>(
    () => NotificationCubit());
  getIt.registerLazySingleton<QuickCommandCubit>(
    () => QuickCommandCubit());
  getIt.registerLazySingleton<NoteCubit>(() => NoteCubit());
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit());
  getIt.registerLazySingleton<SessionCubit>(
    () => SessionCubit(orchestrator: getIt()));
  getIt.registerLazySingleton(() => const FlutterSecureStorage());
}

void _registerRepositories() {
  getIt.registerLazySingleton<IAuthRepository>(() => AuthRepositoryImpl(
    supabase: sp.Supabase.instance.client,
    localDataSource: AuthLocalDataSource(getIt()),
  ));
  getIt.registerLazySingleton<IChatRepository>(
    () => ChatRepositoryImpl(getIt()));
  getIt.registerLazySingleton<IContactsRepository>(
    () => ContactsRepositoryImpl(getIt()));
  getIt.registerLazySingleton<ISettingsRepository>(
    SettingsRepositoryImpl.new);
  getIt.registerLazySingleton<IAgentRepository>(
    () => AgentRepositoryImpl(getIt()));
  getIt.registerLazySingleton<ICallRepository>(
    () => CallRepositoryImpl(getIt()));
}

void _registerUseCases() {
  getIt.registerLazySingleton(() => LoginWithEmailUseCase(getIt()));
  getIt.registerLazySingleton(() => LoginWithGoogleUseCase(getIt()));
  getIt.registerLazySingleton(() => LoginWithAppleUseCase(getIt()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt()));
  getIt.registerLazySingleton(() => RestoreSessionUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton(() => GetRoomsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetMessagesUseCase(getIt()));
  getIt.registerLazySingleton(() => SendMessageUseCase(getIt()));
  getIt.registerLazySingleton(() => GetContactsUseCase(getIt()));
  getIt.registerLazySingleton(() => SearchUsersUseCase(getIt()));
  getIt.registerLazySingleton(() => SendFriendRequestUseCase(getIt()));
  getIt.registerLazySingleton(() => AcceptFriendRequestUseCase(getIt()));
  getIt.registerLazySingleton(() => GetPendingRequestsUseCase(getIt()));
}

void _registerBlocs() {
  getIt.registerFactory(() => AuthBloc(getIt()));
  getIt.registerFactory(() => ChatBloc(getIt(), getIt(), getIt(), getIt()));
  getIt.registerFactory(
    () => ContactsBloc(getIt(), getIt(), getIt(), getIt(), getIt()));
  getIt.registerFactory(() => SettingsBloc(getIt()));
  getIt.registerFactory(() => AgentBloc(getIt()));
  getIt.registerFactory(() => CallBloc(getIt()));
}
