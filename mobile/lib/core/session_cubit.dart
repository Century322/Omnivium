import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'agent/agent_orchestrator.dart';
import 'app_data_gateway.dart';
import 'supabase_sync_service.dart';
import 'app_logger.dart';
import 'notification_center.dart' as nc;

part 'session_cubit.freezed.dart';
part 'session_cubit.g.dart';

@freezed
sealed class SessionMessage with _$SessionMessage {
  const SessionMessage._();
  const factory SessionMessage({
    required String role,
    required String content,
  }) = _SessionMessage;
  factory SessionMessage.fromJson(Map<String, dynamic> json) =>
      _$SessionMessageFromJson(json);
}

@freezed
sealed class ConversationSession with _$ConversationSession {
  const ConversationSession._();
  const factory ConversationSession({
    required String id,
    required String title,
    required DateTime createdAt,
    DateTime? lastActiveAt,
    @Default([]) List<SessionMessage> messages,
    @Default(false) bool isArchived,
    @Default(false) bool isFavorite,
    @Default(false) bool isPinned,
    @Default(false) bool isMuted,
  }) = _ConversationSession;

  DateTime get effectiveLastActiveAt => lastActiveAt ?? createdAt;

  factory ConversationSession.fromJson(Map<String, dynamic> json) =>
      _$ConversationSessionFromJson(json);
}

class SessionState {
  final List<ConversationSession> sessions;
  final List<ConversationSession> archivedSessions;
  final String? activeSessionId;

  const SessionState({
    this.sessions = const [],
    this.archivedSessions = const [],
    this.activeSessionId,
  });

  SessionState copyWith({
    List<ConversationSession>? sessions,
    List<ConversationSession>? archivedSessions,
    String? activeSessionId,
  }) {
    return SessionState(
      sessions: sessions ?? this.sessions,
      archivedSessions: archivedSessions ?? this.archivedSessions,
      activeSessionId: activeSessionId ?? this.activeSessionId);
  }
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit({required AgentOrchestrator orchestrator})
    : _orchestrator = orchestrator,
      super(const SessionState());

  final AgentOrchestrator _orchestrator;
  final List<ConversationSession> _sessions = [];
  bool _disposed = false;
  Timer? _autoSaveTimer;
  int _syncCounter = 0;

  static const _activeSessionKey = 'omnivium_active_session';

  List<ConversationSession> get sessions => List.unmodifiable(
    _sessions.where((s) => !s.isArchived).toList()..sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return b.effectiveLastActiveAt.compareTo(a.effectiveLastActiveAt);
    }));
  List<ConversationSession> get archivedSessions =>
      List.unmodifiable(_sessions.where((s) => s.isArchived));
  String? get activeSessionId => state.activeSessionId;

  void _emitState() {
    if (_disposed) return;
    emit(SessionState(
      sessions: List.unmodifiable(sessions),
      archivedSessions: List.unmodifiable(archivedSessions),
      activeSessionId: state.activeSessionId));
  }

  void _notify() {
    if (!_disposed) {
      _emitState();
      nc.NotificationCenter.post(nc.Event.sessionChanged);
    }
  }

  void startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      saveCurrentSession();
      _syncCounter++;
      if (_syncCounter % 2 == 0) {
        _mergeCloudSessions().then((_) {
          if (!_disposed) _emitState();
        });
      }
      if (_syncCounter % 12 == 0) {
        _cleanupIfDataRetentionOff();
      }
    });
  }

  Future<void> _cleanupIfDataRetentionOff() async {
    final prefs = await SharedPreferences.getInstance();
    final retention = prefs.getBool('omnivium_data_retention') ?? true;
    if (retention) return;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _sessions.removeWhere(
      (s) => s.lastActiveAt.isBefore(cutoff) && !s.isPinned && !s.isFavorite);
    _saveSessions();
    _emitState();
  }

  String createSession() {
    final id = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final session = ConversationSession(
      id: id,
      title: 'New Conversation',
      createdAt: now,
      lastActiveAt: now);
    _sessions.insert(0, session);
    emit(state.copyWith(activeSessionId: id));
    _orchestrator.clearConversation();
    _notify();
    nc.NotificationCenter.post(nc.Event.sessionCreated, data: {'id': id});
    _onSessionLifecycle('create', id);
    return id;
  }

  void switchSession(String id) {
    if (state.activeSessionId == id) return;
    if (_orchestrator.isStreaming) {
      _orchestrator.stopStreaming();
    }
    _saveCurrentSessionMessages();
    emit(state.copyWith(activeSessionId: id));
    _orchestrator.clearConversation();
    _restoreSessionMessages(id);
    _notify();
    nc.NotificationCenter.post(nc.Event.activeSessionChanged, data: {'id': id});
  }

  void closeActiveSession() {
    final id = state.activeSessionId;
    if (id != null) {
      if (_orchestrator.isStreaming) {
        _orchestrator.stopStreaming();
      }
      _saveCurrentSessionMessages();
      _cleanEmptySessions();
    }
    emit(state.copyWith(activeSessionId: null));
    _orchestrator.clearConversation();
    _saveSessions();
    _notify();
  }

  void deleteSession(String id) {
    _sessions.removeWhere((s) => s.id == id);
    if (state.activeSessionId == id) {
      emit(state.copyWith(activeSessionId: null));
      _orchestrator.clearConversation();
    }
    _saveSessions();
    _notify();
    nc.NotificationCenter.post(nc.Event.sessionDeleted, data: {'id': id});
  }

  void archiveSession(String id) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _sessions[idx] = _sessions[idx].copyWith(isArchived: true);
      if (state.activeSessionId == id) {
        emit(state.copyWith(activeSessionId: null));
        _orchestrator.clearConversation();
      }
      _saveSessions();
      _notify();
    }
  }

  void unarchiveSession(String id) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _sessions[idx] = _sessions[idx].copyWith(isArchived: false);
      _saveSessions();
      _notify();
    }
  }

  void updateSessionTitle(String id, String title) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _sessions[idx] = _sessions[idx].copyWith(title: title);
      _saveSessions();
      _notify();
    }
  }

  void saveCurrentSession() {
    _saveCurrentSessionMessages();
  }

  void _saveCurrentSessionMessages() {
    final activeId = state.activeSessionId;
    if (activeId == null) return;
    final idx = _sessions.indexWhere((s) => s.id == activeId);
    if (idx < 0) return;
    final msgs = _orchestrator.messages;
    if (msgs.isEmpty) return;
    final title = msgs.first.content.length > 20
        ? '${msgs.first.content.substring(0, msgs.first.content.runes.take(20).length)}...'
        : msgs.first.content;
    _sessions[idx] = _sessions[idx].copyWith(
      title: title,
      messages: msgs
          .map((m) => SessionMessage(role: m.role, content: m.content))
          .toList(),
      lastActiveAt: DateTime.now());
    _saveSessions();
  }

  void _cleanEmptySessions() {
    final now = DateTime.now();
    _sessions.removeWhere(
      (s) =>
          s.messages.isEmpty &&
          s.id != state.activeSessionId &&
          now.difference(s.effectiveLastActiveAt).inMinutes > 5);
  }

  void _restoreSessionMessages(String id) {
    final session = _sessions.where((s) => s.id == id).firstOrNull;
    if (session == null || session.messages.isEmpty) return;
    for (final msg in session.messages) {
      _orchestrator.restoreMessage(msg.role, msg.content);
    }
  }

  Future<void> _saveSessions() async {
    final db = getIt<AppDataGateway>().db;
    if (!db.isInitialized) return;
    try {
      for (final session in _sessions) {
        await db.putSession(session.id, session.toJson());
        _syncSessionToCloud(session);
      }
      final existingIds = _sessions.map((s) => s.id).toSet();
      for (final key in db.sessions.keys) {
        if (!existingIds.contains(key)) {
          await db.deleteSession(key);
          _deleteSessionFromCloud(key);
        }
      }
      final activeId = state.activeSessionId;
      if (activeId != null) {
        await db.putCache(_activeSessionKey, activeId);
      } else {
        await db.deleteCache(_activeSessionKey);
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error('App error', error: e, stackTrace: stackTrace);
    }
  }

  void _syncSessionToCloud(ConversationSession session) {
    final sync = getIt<SupabaseSyncService>();
    if (!sync.isAvailable) return;
    sync.upsertSession({
      'id': session.id,
      'title': session.title,
      'is_archived': session.isArchived,
      'is_favorite': session.isFavorite,
      'messages': session.messages.map((m) => m.toJson()).toList(),
      'created_at': session.createdAt.toIso8601String(),
      'updated_at': session.effectiveLastActiveAt.toIso8601String(),
    });
  }

  void _deleteSessionFromCloud(String id) {
    final sync = getIt<SupabaseSyncService>();
    if (!sync.isAvailable) return;
    sync.deleteSession(id);
  }

  Future<void> _mergeCloudSessions() async {
    final sync = getIt<SupabaseSyncService>();
    if (!sync.isAvailable) return;
    try {
      final cloudSessions = await sync.fetchSessions();
      final db = getIt<AppDataGateway>().db;
      for (final cloud in cloudSessions) {
        final id = cloud['id'] as String?;
        if (id == null) continue;
        final localIdx = _sessions.indexWhere((s) => s.id == id);
        if (localIdx < 0) {
          try {
            final session = ConversationSession.fromJson(cloud);
            _sessions.add(session);
            await db.putSession(session.id, session.toJson());
          } catch (e) {
            AppLogger.instance.warning(
              'Session sync: failed to add cloud session locally',
              error: e);
          }
        } else {
          final cloudUpdated = cloud['updated_at'] as String?;
          final localUpdated = _sessions[localIdx].lastActiveAt
              .toIso8601String();
          if (cloudUpdated != null &&
              cloudUpdated.compareTo(localUpdated) > 0) {
            try {
              final session = ConversationSession.fromJson(cloud);
              _sessions[localIdx] = session;
              await db.putSession(session.id, session.toJson());
            } catch (e) {
              AppLogger.instance.warning(
                'Session sync: failed to overwrite local session with cloud',
                error: e);
            }
          }
        }
      }
    } catch (e) {
      AppLogger.instance.info('Cloud session merge failed: $e');
    }
  }

  Future<void> loadSessions() async {
    final db = getIt<AppDataGateway>().db;
    final allSessions = db.getAllSessions();
    if (allSessions.isNotEmpty) {
      _sessions.clear();
      for (final data in allSessions) {
        try {
          _sessions.add(ConversationSession.fromJson(data));
        } catch (e, stackTrace) {
          AppLogger.instance.error(
            'App error',
            error: e,
            stackTrace: stackTrace);
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('omnivium_sessions');
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List<dynamic>;
          _sessions.clear();
          for (final item in list) {
            final session = ConversationSession.fromJson(
              item as Map<String, dynamic>);
            _sessions.add(session);
            await db.putSession(session.id, session.toJson());
          }
          await prefs.remove('omnivium_sessions');
        } catch (e, stackTrace) {
          AppLogger.instance.error(
            'App error',
            error: e,
            stackTrace: stackTrace);
        }
      }
    }
    await _mergeCloudSessions();
    final activeId = db.getCache(_activeSessionKey);
    if (activeId != null) {
      emit(state.copyWith(activeSessionId: activeId));
    } else {
      final prefs = await SharedPreferences.getInstance();
      final cachedActiveId = prefs.getString(_activeSessionKey);
      if (cachedActiveId != null) {
        emit(state.copyWith(activeSessionId: cachedActiveId));
        await db.putCache(_activeSessionKey, cachedActiveId);
        await prefs.remove(_activeSessionKey);
      }
    }
    final restoreId = state.activeSessionId;
    if (restoreId != null) {
      _restoreSessionMessages(restoreId);
    }
    _notify();
  }

  Future<void> clearAllSessions() async {
    _sessions.clear();
    emit(state.copyWith(activeSessionId: null));
    final db = getIt<AppDataGateway>().db;
    await db.sessions.clear();
    await db.deleteCache(_activeSessionKey);
    _notify();
  }

  void toggleFavoriteSession(String id) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    _sessions[idx] = _sessions[idx].copyWith(
      isFavorite: !_sessions[idx].isFavorite);
    _saveSessions();
    _notify();
  }

  void togglePinSession(String id) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    _sessions[idx] = _sessions[idx].copyWith(
      isPinned: !_sessions[idx].isPinned);
    _saveSessions();
    _notify();
  }

  void toggleMuteSession(String id) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    _sessions[idx] = _sessions[idx].copyWith(isMuted: !_sessions[idx].isMuted);
    _saveSessions();
    _notify();
  }

  void _onSessionLifecycle(String action, String id) {
    AppLogger.instance.info('SessionCubit: $action session $id');
    nc.NotificationCenter.post(
      nc.Event.sessionChanged,
      data: {'action': action, 'id': id});
  }

  @override
  Future<void> close() {
    _disposed = true;
    _autoSaveTimer?.cancel();
    return super.close();
  }
}
