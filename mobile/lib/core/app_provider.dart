import 'remote_config_service.dart';
import 'agent/agent_orchestrator.dart';
import 'matrix/matrix_provider.dart';
import 'notification/notification_provider.dart';
import 'navigation_provider.dart';
import 'model_provider.dart';
import 'session_provider.dart';
import 'quick_command_provider.dart';
import 'note_provider.dart';
import 'voice_service.dart';
import 'app_logger.dart';

class AppProvider {
  RemoteConfigService get remoteConfig => RemoteConfigService.instance;
  bool getFeatureFlag(String key, {bool defaultValue = false}) => remoteConfig.getFeatureFlag(key, defaultValue: defaultValue);

  final NavigationProvider _navigation = NavigationProvider();
  final AgentOrchestrator _orchestrator = AgentOrchestrator();
  final MatrixProvider _matrix = MatrixProvider();
  final NotificationProvider _notification = NotificationProvider();
  final QuickCommandProvider _quickCommands = QuickCommandProvider();
  final NoteProvider _notes = NoteProvider();
  late final ModelProvider _model;
  late final SessionProvider _session;

  AppProvider() {
    _model = ModelProvider(orchestrator: _orchestrator);
    _session = SessionProvider(orchestrator: _orchestrator);
  }

  NavigationProvider get navigation => _navigation;
  ModelProvider get model => _model;
  SessionProvider get session => _session;
  MatrixProvider get matrix => _matrix;
  AgentOrchestrator get orchestrator => _orchestrator;
  NotificationProvider get notification => _notification;
  QuickCommandProvider get quickCommands => _quickCommands;
  NoteProvider get notes => _notes;

  void activateModel(String modelId) {
    _model.switchModel(modelId);
    _notification.listenToMatrix(_matrix);
  }

  Future<void> initSubProviders() async {
    try {
      await _model.loadModels();
    } catch (e, stackTrace) {
      AppLogger.instance.error('ModelProvider init failed', error: e, stackTrace: stackTrace);
    }
    try {
      await _session.loadSessions();
    } catch (e, stackTrace) {
      AppLogger.instance.error('SessionProvider init failed', error: e, stackTrace: stackTrace);
    }
    try {
      await _quickCommands.init();
    } catch (e, stackTrace) {
      AppLogger.instance.error('QuickCommandProvider init failed', error: e, stackTrace: stackTrace);
    }
    try {
      await _notes.init();
    } catch (e, stackTrace) {
      AppLogger.instance.error('NoteProvider init failed', error: e, stackTrace: stackTrace);
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
