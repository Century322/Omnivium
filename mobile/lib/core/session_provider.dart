import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';
import 'agent/agent_orchestrator.dart';
import 'database_service.dart';

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
  const ConversationSession({
    required this.id,
    required this.title,
    required this.createdAt,
    DateTime? lastActiveAt,
    this.messages = const [],
    this.isArchived = false,
    this.isFavorite = false,
  }) : lastActiveAt = lastActiveAt ?? createdAt;
  ConversationSession copyWith({String? title, List<SessionMessage>? messages, bool? isArchived, bool? isFavorite, DateTime? lastActiveAt}) =>
      ConversationSession(id: id, title: title ?? this.title, createdAt: createdAt, lastActiveAt: lastActiveAt ?? this.lastActiveAt, messages: messages ?? this.messages, isArchived: isArchived ?? this.isArchived, isFavorite: isFavorite ?? this.isFavorite);
  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'createdAt': createdAt.toIso8601String(),
    'lastActiveAt': lastActiveAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(), 'isArchived': isArchived, 'isFavorite': isFavorite,
  };
  factory ConversationSession.fromJson(Map<String, dynamic> json) => ConversationSession(
    id: json['id'], title: json['title'], createdAt: DateTime.parse(json['createdAt']),
    lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt']) : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
    messages: (json['messages'] as List?)?.map((m) => SessionMessage.fromJson(m as Map<String, dynamic>)).toList() ?? [],
    isArchived: json['isArchived'] ?? false,
    isFavorite: json['isFavorite'] ?? false,
  );
}

class SessionProvider extends ChangeNotifier {
  final AgentOrchestrator _orchestrator;
  SessionProvider({required AgentOrchestrator orchestrator}) : _orchestrator = orchestrator;

  final List<ConversationSession> _sessions = [];
  bool _disposed = false;
  List<ConversationSession> get sessions => List.unmodifiable(
    _sessions.where((s) => !s.isArchived).toList()
      ..sort((a, b) {
        if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
        return b.lastActiveAt.compareTo(a.lastActiveAt);
      }),
  );
  List<ConversationSession> get archivedSessions => List.unmodifiable(_sessions.where((s) => s.isArchived));
  String? _activeSessionId;
  String? get activeSessionId => _activeSessionId;

  Timer? _autoSaveTimer;

  void startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) { saveCurrentSession(); });
  }

  @override
  void dispose() {
    _disposed = true;
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String createSession() {
    final id = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final session = ConversationSession(id: id, title: 'New Conversation', createdAt: now, lastActiveAt: now);
    _sessions.insert(0, session);
    _activeSessionId = id;
    _orchestrator.clearConversation();
    _notify();
    return id;
  }

  void switchSession(String id) {
    if (_activeSessionId == id) return;
    _saveCurrentSessionMessages();
    _activeSessionId = id;
    _orchestrator.clearConversation();
    _restoreSessionMessages(id);
    _notify();
  }

  void closeActiveSession() {
    if (_activeSessionId != null) {
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
    final title = msgs.first.content.substring(0, msgs.first.content.length.clamp(0, 20));
    _sessions[idx] = _sessions[idx].copyWith(
      title: title,
      messages: msgs.map((m) => SessionMessage(role: m.role, content: m.content)).toList(),
      lastActiveAt: DateTime.now(),
    );
    _saveSessions();
  }

  void _cleanEmptySessions() {
    _sessions.removeWhere((s) => s.messages.isEmpty && s.id != _activeSessionId);
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
    final db = DatabaseService.instance;
    if (!db.isInitialized) return;
    try {
      for (final session in _sessions) {
        await db.putSession(session.id, session.toJson());
      }
      final existingIds = _sessions.map((s) => s.id).toSet();
      for (final key in db.sessions.keys) {
        if (!existingIds.contains(key)) { await db.deleteSession(key); }
      }
      if (_activeSessionId != null) {
        await db.putCache(_activeSessionKey, _activeSessionId!);
      } else {
        await db.deleteCache(_activeSessionKey);
      }
    } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
  }

  Future<void> loadSessions() async {
    final db = DatabaseService.instance;
    final allSessions = db.getAllSessions();
    if (allSessions.isNotEmpty) {
      _sessions.clear();
      for (final data in allSessions) {
        try { _sessions.add(ConversationSession.fromJson(data)); } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('omnivium_sessions');
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List;
          _sessions.clear();
          for (final item in list) {
            final session = ConversationSession.fromJson(item as Map<String, dynamic>);
            _sessions.add(session);
            await db.putSession(session.id, session.toJson());
          }
          await prefs.remove('omnivium_sessions');
        } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
      }
    }
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
    if (_activeSessionId != null) { _restoreSessionMessages(_activeSessionId!); }
    _notify();
  }

  Future<void> clearAllSessions() async {
    _sessions.clear();
    _activeSessionId = null;
    final db = DatabaseService.instance;
    await db.sessions.clear();
    await db.deleteCache(_activeSessionKey);
    _notify();
  }

  void toggleFavoriteSession(String id) {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    _sessions[idx] = _sessions[idx].copyWith(isFavorite: !_sessions[idx].isFavorite);
    _saveSessions();
    _notify();
  }
}
