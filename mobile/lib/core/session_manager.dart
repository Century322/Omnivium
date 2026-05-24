import 'package:flutter/material.dart';
import 'agent/agent_orchestrator.dart';
import 'session_provider.dart';
import 'app_logger.dart';
import 'notification_center.dart' as nc;

class SessionManager extends ChangeNotifier {
  final SessionProvider _provider;
  bool _disposed = false;

  SessionManager({required AgentOrchestrator orchestrator})
    : _provider = SessionProvider(orchestrator: orchestrator) {
    _provider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    if (!_disposed) notifyListeners();
  }

  List<ConversationSession> get sessions => _provider.sessions;
  List<ConversationSession> get archivedSessions => _provider.archivedSessions;
  String? get activeSessionId => _provider.activeSessionId;

  void startAutoSave() => _provider.startAutoSave();

  String createSession() {
    final id = _provider.createSession();
    _onSessionLifecycle('create', id);
    return id;
  }

  void switchSession(String id) {
    _provider.switchSession(id);
    _onSessionLifecycle('switch', id);
  }

  void closeActiveSession() {
    final id = _provider.activeSessionId;
    _provider.closeActiveSession();
    if (id != null) _onSessionLifecycle('close', id);
  }

  void deleteSession(String id) {
    _provider.deleteSession(id);
    _onSessionLifecycle('delete', id);
  }

  void archiveSession(String id) => _provider.archiveSession(id);
  void unarchiveSession(String id) => _provider.unarchiveSession(id);
  void updateSessionTitle(String id, String title) =>
      _provider.updateSessionTitle(id, title);
  void saveCurrentSession() => _provider.saveCurrentSession();
  Future<void> loadSessions() => _provider.loadSessions();
  Future<void> clearAllSessions() => _provider.clearAllSessions();
  void toggleFavoriteSession(String id) => _provider.toggleFavoriteSession(id);
  void togglePinSession(String id) => _provider.togglePinSession(id);
  void toggleMuteSession(String id) => _provider.toggleMuteSession(id);

  void _onSessionLifecycle(String action, String id) {
    AppLogger.instance.info('SessionManager: $action session $id');
    nc.NotificationCenter.post(
      nc.Event.sessionChanged,
      data: {'action': action, 'id': id},
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    super.dispose();
  }
}
