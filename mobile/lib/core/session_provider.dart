import 'app_logger.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'agent/agent_orchestrator.dart';
import 'app_data_gateway.dart';
import 'supabase_sync_service.dart';
import 'notification_center.dart' as nc;

class SessionMessage {
  final String role;
  final String content;
  const SessionMessage({required this.role, required this.content});
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
  factory SessionMessage.fromJson(Map<String, dynamic> json) =>
      SessionMessage(role: json['role'], content: json['content']);
}

class ConversationSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final List<SessionMessage> messages;
  final bool isArchived;
  final bool isFavorite;
  final bool isPinned;
  final bool isMuted;
  const ConversationSession({
    required this.id,
    required this.title,
    required this.createdAt,
    DateTime? lastActiveAt,
    this.messages = const [],
    this.isArchived = false,
    this.isFavorite = false,
    this.isPinned = false,
    this.isMuted = false,
  }) : lastActiveAt = lastActiveAt ?? createdAt;
  ConversationSession copyWith({
    String? title,
    List<SessionMessage>? messages,
    bool? isArchived,
    bool? isFavorite,
    bool? isPinned,
    bool? isMuted,
    DateTime? lastActiveAt,
  }) => ConversationSession(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    messages: messages ?? this.messages,
    isArchived: isArchived ?? this.isArchived,
    isFavorite: isFavorite ?? this.isFavorite,
    isPinned: isPinned ?? this.isPinned,
    isMuted: isMuted ?? this.isMuted,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'lastActiveAt': lastActiveAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
    'isArchived': isArchived,
    'isFavorite': isFavorite,
    'isPinned': isPinned,
    'isMuted': isMuted,
  };
  factory ConversationSession.fromJson(Map<String, dynamic> json) =>
      ConversationSession(
        id: json['id'],
        title: json['title'],
        createdAt: DateTime.parse(json['createdAt']),
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.parse(json['lastActiveAt'])
            : (json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'])
                  : DateTime.now()),
        messages:
            (json['messages'] as List?)
                ?.map((m) => SessionMessage.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        isArchived: json['isArchived'] ?? false,
        isFavorite: json['isFavorite'] ?? false,
        isPinned: json['isPinned'] ?? false,
        isMuted: json['isMuted'] ?? false,
      );
}

class SessionProvider extends ChangeNotifier {
  final AgentOrchestrator _orchestrator;
  SessionProvider({required AgentOrchestrator orchestrator})
    : _orchestrator = orchestrator;

  final List<ConversationSession> _sessions = [];
  bool _disposed = false;
  List<ConversationSession> get sessions => List.unmodifiable(
    _sessions.where((s) => !s.isArchived).toList()..sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return b.lastActiveAt.compareTo(a.lastActiveAt);
    }),
  );
  List<ConversationSession> get archivedSessions =>
      List.unmodifiable(_sessions.where((s) => s.isArchived));
  String? _activeSessionId;
  String? get activeSessionId => _activeSessionId;

  Timer? _autoSaveTimer;
  int _syncCounter = 0;

  void startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      saveCurrentSession();
      _syncCounter++;
      if (_syncCounter % 2 == 0) {
        _mergeCloudSessions().then((_) {
          if (!_disposed) notifyListeners();
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
      (s) => s.lastActiveAt.isBefore(cutoff) && !s.isPinned && !s.isFavorite,
    );
    _saveSessions();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
      nc.NotificationCenter.post(nc.Event.sessionChanged);
    }
  }

  String createSession() {
    final id = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final session = ConversationSession(
      id: id,
      title: 'New Conversation',
      createdAt: now,
      lastActiveAt: now,
    );
    _sessions.insert(0, session);
    _activeSessionId = id;
    _orchestrator.clearConversation();
    _notify();
    nc.NotificationCenter.post(nc.Event.sessionCreated, data: {'id': id});
    return id;
  }

  void switchSession(String id) {
    if (_activeSessionId == id) return;
    if (_orchestrator.isStreaming) {
      _orchestrator.stopStreaming();
    }
    _saveCurrentSessionMessages();
    _activeSessionId = id;
    _orchestrator.clearConversation();
    _restoreSessionMessages(id);
    _notify();
    nc.NotificationCenter.post(nc.Event.activeSessionChanged, data: {'id': id});
  }

  void closeActiveSession() {
    if (_activeSessionId != null) {
      if (_orchestrator.isStreaming) {
        _orchestrator.stopStreaming();
      }
      _saveCurrentSessionMessages();
      _cleanEmptySessions();
    }
    _activeSessionId = null;
    _orchestrator.clearConversation();
    _saveSessions();
    _notify();
  }

  void deleteSession(String id) {
    _sessions.removeWhere((s) => s.id == id);
    if (_activeSessionId == id) {
      _activeSessionId = null;
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
      if (_activeSessionId == id) {
        _activeSessionId = null;
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
    if (_activeSessionId == null) return;
    final idx = _sessions.indexWhere((s) => s.id == _activeSessionId);
    if (idx < 0) return;
    final msgs = _orchestrator.messages;
    if (msgs.isEmpty) return;
    final title = msgs.first.content.substring(
      0,
      msgs.first.content.length.clamp(0, 20),
    );
    _sessions[idx] = _sessions[idx].copyWith(
      title: title,
      messages: msgs
          .map((m) => SessionMessage(role: m.role, content: m.content))
          .toList(),
      lastActiveAt: DateTime.now(),
    );
    _saveSessions();
  }

  void _cleanEmptySessions() {
    _sessions.removeWhere(
      (s) => s.messages.isEmpty && s.id != _activeSessionId,
    );
  }

  void _restoreSessionMessages(String id) {
    final session = _sessions.where((s) => s.id == id).firstOrNull;
    if (session == null || session.messages.isEmpty) return;
    for (final msg in session.messages) {
      _orchestrator.restoreMessage(msg.role, msg.content);
    }
  }

  static const _activeSessionKey = 'omnivium_active_session';

  Future<void> _saveSessions() async {
    final db = AppDataGateway.instance.db;
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
      if (_activeSessionId != null) {
        await db.putCache(_activeSessionKey, _activeSessionId!);
      } else {
        await db.deleteCache(_activeSessionKey);
      }
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _syncSessionToCloud(ConversationSession session) {
    final sync = SupabaseSyncService.instance;
    if (!sync.isAvailable) return;
    sync.upsertSession({
      'id': session.id,
      'title': session.title,
      'is_archived': session.isArchived,
      'is_favorite': session.isFavorite,
      'messages': session.messages.map((m) => m.toJson()).toList(),
      'created_at': session.createdAt.toIso8601String(),
      'updated_at': session.lastActiveAt.toIso8601String(),
    });
  }

  void _deleteSessionFromCloud(String id) {
    final sync = SupabaseSyncService.instance;
    if (!sync.isAvailable) return;
    sync.deleteSession(id);
  }

  Future<void> _mergeCloudSessions() async {
    final sync = SupabaseSyncService.instance;
    if (!sync.isAvailable) return;
    try {
      final cloudSessions = await sync.fetchSessions();
      final db = AppDataGateway.instance.db;
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
              error: e,
            );
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
                error: e,
              );
            }
          }
        }
      }
    } catch (e) {
      AppLogger.instance.info('Cloud session merge failed: $e');
    }
  }

  Future<void> loadSessions() async {
    final db = AppDataGateway.instance.db;
    final allSessions = db.getAllSessions();
    if (allSessions.isNotEmpty) {
      _sessions.clear();
      for (final data in allSessions) {
        try {
          _sessions.add(ConversationSession.fromJson(data));
        } catch (e, stackTrace) {
          AppLogger.instance.error(
            'Operation failed',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('omnivium_sessions');
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List;
          _sessions.clear();
          for (final item in list) {
            final session = ConversationSession.fromJson(
              item as Map<String, dynamic>,
            );
            _sessions.add(session);
            await db.putSession(session.id, session.toJson());
          }
          await prefs.remove('omnivium_sessions');
        } catch (e, stackTrace) {
          AppLogger.instance.error(
            'Operation failed',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
    }
    await _mergeCloudSessions();
    final activeId = db.getCache(_activeSessionKey);
    if (activeId != null) {
      _activeSessionId = activeId;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _activeSessionId = prefs.getString(_activeSessionKey);
      if (_activeSessionId != null) {
        await db.putCache(_activeSessionKey, _activeSessionId!);
        await prefs.remove(_activeSessionKey);
      }
    }
    if (_activeSessionId != null) {
      _restoreSessionMessages(_activeSessionId!);
    }
    _notify();
  }

  Future<void> clearAllSessions() async {
    _sessions.clear();
    _activeSessionId = null;
    final db = AppDataGateway.instance.db;
    await db.sessions.clear();
    await db.deleteCache(_activeSessionKey);
    _notify();
  }

  void toggleFavoriteSession(String id) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    _sessions[idx] = _sessions[idx].copyWith(
      isFavorite: !_sessions[idx].isFavorite,
    );
    _saveSessions();
    _notify();
  }

  void togglePinSession(String id) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    _sessions[idx] = _sessions[idx].copyWith(
      isPinned: !_sessions[idx].isPinned,
    );
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
}
