import 'remote_config_service.dart';
import 'agent/agent_orchestrator.dart';
import 'agent/agent_reminder_service.dart' show ReminderService;
import 'matrix/matrix_provider.dart';
import 'notification/notification_provider.dart';
import 'navigation_provider.dart';
import 'model_provider.dart';
import 'session_manager.dart';
import 'quick_command_provider.dart';
import 'note_provider.dart';
import 'voice_service.dart';
import 'app_logger.dart';
import 'runtime/sdk/omnivium_sdk.dart';
import 'runtime/vocabulary/runtime_event.dart';
import 'runtime/vocabulary/runtime_identity.dart';
import 'notification_center.dart' as nc;
import 'identity_bridge.dart';

class AppProvider {
  RemoteConfigService get remoteConfig => RemoteConfigService.instance;
  bool getFeatureFlag(String key, {bool defaultValue = false}) =>
      remoteConfig.getFeatureFlag(key, defaultValue: defaultValue);

  final NavigationProvider _navigation = NavigationProvider();
  final AgentOrchestrator _orchestrator = AgentOrchestrator();
  final MatrixProvider _matrix = MatrixProvider();
  final NotificationProvider _notification = NotificationProvider();
  final QuickCommandProvider _quickCommands = QuickCommandProvider();
  final NoteProvider _notes = NoteProvider();
  late final ModelProvider _model;
  late final SessionManager _session;

  AppProvider() {
    _model = ModelProvider(orchestrator: _orchestrator);
    _session = SessionManager(orchestrator: _orchestrator);
    _connectRuntime();
  }

  OmniviumSDK? get _sdk =>
      OmniviumSDK.instance.isInitialized ? OmniviumSDK.instance : null;

  bool _runtimeConnected = false;

  void _connectRuntime() {
    if (_runtimeConnected) return;
    final sdk = _sdk;
    if (sdk == null) return;
    _runtimeConnected = true;
    _orchestrator.connectRuntime(sdk);
    _bridgeEventBus(sdk);
    _bridgeIdentity(sdk);
    ReminderService.instance.startChecking();
  }

  void _bridgeIdentity(OmniviumSDK sdk) {
    final bridge = IdentityBridge.instance;
    if (bridge.isBound) {
      sdk.container.updateIdentity(RuntimeIdentity.forPlugin(bridge.nodeId));
    }
  }

  void _bridgeEventBus(OmniviumSDK sdk) {
    final eventTypes = ['plugin', 'sandbox', 'capability'];
    for (final prefix in eventTypes) {
      sdk.container.eventBus.subscribe(prefix, (RuntimeEvent event) async {
        final eventType = event.type;
        final data = event.payload;
        if (eventType.startsWith('plugin.')) {
          nc.NotificationCenter.post(
            nc.Event.settingsUpdated,
            data: {'source': 'runtime', 'type': eventType},
          );
        } else if (eventType.startsWith('sandbox.')) {
          nc.NotificationCenter.post(
            nc.Event.securityAlert,
            data: {'source': 'runtime', 'type': eventType, ...?data},
          );
        } else if (eventType.startsWith('capability.')) {
          nc.NotificationCenter.post(
            nc.Event.agentSkillInvoked,
            data: {'source': 'runtime', 'type': eventType, ...?data},
          );
        }
      }, permission: EventPermission.observe);
    }
  }

  NavigationProvider get navigation => _navigation;
  ModelProvider get model => _model;
  SessionManager get session => _session;
  MatrixProvider get matrix => _matrix;
  AgentOrchestrator get orchestrator => _orchestrator;
  NotificationProvider get notification => _notification;
  QuickCommandProvider get quickCommands => _quickCommands;
  NoteProvider get notes => _notes;

  void activateModel(String modelId) {
    _model.switchModel(modelId);
  }

  Future<void> initSubProviders() async {
    _connectRuntime();
    try {
      await _notification.init();
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'NotificationProvider init failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    try {
      await _model.loadModels();
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'ModelProvider init failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    try {
      await _session.loadSessions();
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'SessionProvider init failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    try {
      await _quickCommands.init();
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'QuickCommandProvider init failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    try {
      await _notes.init();
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'NoteProvider init failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    _notification.listenToMatrix(_matrix);
  }

  void dispose() {
    _navigation.dispose();
    _model.dispose();
    _session.dispose();
    _matrix.dispose();
    _orchestrator.dispose();
    _notification.dispose();
    _quickCommands.dispose();
    _notes.dispose();
    VoiceService.instance.dispose();
  }
}
