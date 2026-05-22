import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/session_provider.dart';
import 'package:omnivium/core/agent/agent_orchestrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionMessage', () {
    test('creates with role and content', () {
      const msg = SessionMessage(role: 'user', content: 'Hello');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
    });

    test('toJson returns correct map', () {
      const msg = SessionMessage(role: 'assistant', content: 'Hi there');
      final json = msg.toJson();
      expect(json['role'], 'assistant');
      expect(json['content'], 'Hi there');
    });

    test('fromJson creates correct object', () {
      final json = {'role': 'system', 'content': 'You are helpful'};
      final msg = SessionMessage.fromJson(json);
      expect(msg.role, 'system');
      expect(msg.content, 'You are helpful');
    });

    test('toJson and fromJson round-trip', () {
      const msg = SessionMessage(role: 'user', content: 'Test message');
      final json = msg.toJson();
      final restored = SessionMessage.fromJson(json);
      expect(restored.role, msg.role);
      expect(restored.content, msg.content);
    });

    test('handles empty content', () {
      const msg = SessionMessage(role: 'user', content: '');
      expect(msg.content, '');
    });

    test('handles long content', () {
      final msg = SessionMessage(role: 'user', content: 'A' * 10000);
      expect(msg.content.length, 10000);
    });
  });

  group('ConversationSession', () {
    test('creates with required fields', () {
      final session = ConversationSession(
        id: 's1',
        title: 'Test',
        createdAt: DateTime(2024),
      );
      expect(session.id, 's1');
      expect(session.title, 'Test');
      expect(session.messages, isEmpty);
      expect(session.isArchived, false);
      expect(session.isFavorite, false);
    });

    test('creates with all fields', () {
      final session = ConversationSession(
        id: 's1',
        title: 'Test',
        createdAt: DateTime(2024),
        messages: const [SessionMessage(role: 'user', content: 'Hi')],
        isArchived: true,
        isFavorite: true,
      );
      expect(session.messages.length, 1);
      expect(session.isArchived, true);
      expect(session.isFavorite, true);
    });

    test('copyWith updates title', () {
      final session = ConversationSession(
        id: 's1',
        title: 'Old',
        createdAt: DateTime(2024),
      );
      final updated = session.copyWith(title: 'New');
      expect(updated.title, 'New');
      expect(updated.id, 's1');
    });

    test('copyWith updates messages', () {
      final session = ConversationSession(
        id: 's1',
        title: 'Test',
        createdAt: DateTime(2024),
      );
      final updated = session.copyWith(
        messages: const [SessionMessage(role: 'user', content: 'Hi')],
      );
      expect(updated.messages.length, 1);
    });

    test('copyWith updates isArchived', () {
      final session = ConversationSession(
        id: 's1',
        title: 'Test',
        createdAt: DateTime(2024),
      );
      final updated = session.copyWith(isArchived: true);
      expect(updated.isArchived, true);
    });

    test('copyWith updates isFavorite', () {
      final session = ConversationSession(
        id: 's1',
        title: 'Test',
        createdAt: DateTime(2024),
      );
      final updated = session.copyWith(isFavorite: true);
      expect(updated.isFavorite, true);
    });

    test('copyWith preserves unchanged fields', () {
      final session = ConversationSession(
        id: 's1',
        title: 'Test',
        createdAt: DateTime(2024),
        isArchived: true,
        isFavorite: true,
      );
      final updated = session.copyWith(title: 'New');
      expect(updated.isArchived, true);
      expect(updated.isFavorite, true);
      expect(updated.id, 's1');
    });

    test('toJson returns correct map', () {
      final session = ConversationSession(
        id: 's1',
        title: 'Test',
        createdAt: DateTime(2024, 1, 15),
        messages: const [SessionMessage(role: 'user', content: 'Hi')],
        isArchived: true,
        isFavorite: false,
      );
      final json = session.toJson();
      expect(json['id'], 's1');
      expect(json['title'], 'Test');
      expect(json['isArchived'], true);
      expect(json['isFavorite'], false);
      expect(json['messages'], isA<List>());
    });

    test('fromJson creates correct object', () {
      final json = {
        'id': 's1',
        'title': 'Test',
        'createdAt': '2024-01-15T00:00:00.000',
        'messages': [
          {'role': 'user', 'content': 'Hi'},
        ],
        'isArchived': true,
        'isFavorite': false,
      };
      final session = ConversationSession.fromJson(json);
      expect(session.id, 's1');
      expect(session.title, 'Test');
      expect(session.messages.length, 1);
      expect(session.isArchived, true);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 's1',
        'title': 'Test',
        'createdAt': '2024-01-15T00:00:00.000',
      };
      final session = ConversationSession.fromJson(json);
      expect(session.messages, isEmpty);
      expect(session.isArchived, false);
      expect(session.isFavorite, false);
    });

    test('toJson and fromJson round-trip', () {
      final session = ConversationSession(
        id: 's1',
        title: 'Test',
        createdAt: DateTime(2024, 1, 15),
        messages: const [SessionMessage(role: 'user', content: 'Hi')],
        isArchived: true,
        isFavorite: true,
      );
      final json = session.toJson();
      final restored = ConversationSession.fromJson(json);
      expect(restored.id, session.id);
      expect(restored.title, session.title);
      expect(restored.messages.length, session.messages.length);
      expect(restored.isArchived, session.isArchived);
      expect(restored.isFavorite, session.isFavorite);
    });
  });

  group('SessionProvider', () {
    late AgentOrchestrator orchestrator;
    late SessionProvider provider;

    setUp(() {
      orchestrator = AgentOrchestrator();
      provider = SessionProvider(orchestrator: orchestrator);
    });

    tearDown(() {
      try {
        provider.dispose();
      } catch (_) {}
      try {
        orchestrator.dispose();
      } catch (_) {}
    });

    test('starts with no sessions', () {
      expect(provider.sessions, isEmpty);
    });

    test('starts with no active session', () {
      expect(provider.activeSessionId, isNull);
    });

    test('starts with no archived sessions', () {
      expect(provider.archivedSessions, isEmpty);
    });

    test('createSession adds session', () {
      provider.createSession();
      expect(provider.sessions.length, 1);
    });

    test('createSession sets active session', () {
      final id = provider.createSession();
      expect(provider.activeSessionId, id);
    });

    test('createSession notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);
      provider.createSession();
      expect(notified, true);
    });

    test('createSession inserts at beginning', () {
      provider.createSession();
      provider.createSession();
      expect(provider.sessions.length, 2);
    });

    test('createSession returns unique id', () async {
      final id1 = provider.createSession();
      await Future.delayed(const Duration(milliseconds: 2));
      final id2 = provider.createSession();
      expect(id1, isNot(equals(id2)));
    });

    test('deleteSession removes session', () {
      final id = provider.createSession();
      provider.deleteSession(id);
      expect(provider.sessions, isEmpty);
    });

    test('deleteSession active session clears active', () {
      final id = provider.createSession();
      provider.deleteSession(id);
      expect(provider.activeSessionId, isNull);
    });

    test('deleteSession notifies listeners', () {
      final id = provider.createSession();
      var notified = false;
      provider.addListener(() => notified = true);
      provider.deleteSession(id);
      expect(notified, true);
    });

    test('deleteSession non-active does not change active', () async {
      final id1 = provider.createSession();
      await Future.delayed(const Duration(milliseconds: 2));
      provider.createSession();
      provider.deleteSession(id1);
      expect(provider.activeSessionId, isNotNull);
      expect(provider.activeSessionId, isNot(equals(id1)));
    });

    test('archiveSession marks session as archived', () {
      final id = provider.createSession();
      provider.archiveSession(id);
      expect(provider.sessions, isEmpty);
      expect(provider.archivedSessions.length, 1);
    });

    test('archiveSession active session clears active', () {
      final id = provider.createSession();
      provider.archiveSession(id);
      expect(provider.activeSessionId, isNull);
    });

    test('archiveSession notifies listeners', () {
      final id = provider.createSession();
      var notified = false;
      provider.addListener(() => notified = true);
      provider.archiveSession(id);
      expect(notified, true);
    });

    test('unarchiveSession restores session', () {
      final id = provider.createSession();
      provider.archiveSession(id);
      provider.unarchiveSession(id);
      expect(provider.sessions.length, 1);
      expect(provider.archivedSessions, isEmpty);
    });

    test('unarchiveSession notifies listeners', () {
      final id = provider.createSession();
      provider.archiveSession(id);
      var notified = false;
      provider.addListener(() => notified = true);
      provider.unarchiveSession(id);
      expect(notified, true);
    });

    test('updateSessionTitle changes title', () {
      final id = provider.createSession();
      provider.updateSessionTitle(id, 'New Title');
      expect(provider.sessions.first.title, 'New Title');
    });

    test('updateSessionTitle notifies listeners', () {
      final id = provider.createSession();
      var notified = false;
      provider.addListener(() => notified = true);
      provider.updateSessionTitle(id, 'New Title');
      expect(notified, true);
    });

    test('updateSessionTitle non-existent session does nothing', () {
      provider.createSession();
      provider.updateSessionTitle('nonexistent', 'Title');
      expect(provider.sessions.first.title, 'New Conversation');
    });

    test('toggleFavoriteSession toggles favorite', () {
      final id = provider.createSession();
      expect(provider.sessions.first.isFavorite, false);
      provider.toggleFavoriteSession(id);
      expect(provider.sessions.first.isFavorite, true);
      provider.toggleFavoriteSession(id);
      expect(provider.sessions.first.isFavorite, false);
    });

    test('toggleFavoriteSession notifies listeners', () {
      final id = provider.createSession();
      var notified = false;
      provider.addListener(() => notified = true);
      provider.toggleFavoriteSession(id);
      expect(notified, true);
    });

    test('closeActiveSession clears active', () {
      provider.createSession();
      provider.closeActiveSession();
      expect(provider.activeSessionId, isNull);
    });

    test('closeActiveSession notifies listeners', () {
      provider.createSession();
      var notified = false;
      provider.addListener(() => notified = true);
      provider.closeActiveSession();
      expect(notified, true);
    });

    test('switchSession changes active session', () {
      final id1 = provider.createSession();
      final id2 = provider.createSession();
      expect(provider.activeSessionId, id2);
      provider.switchSession(id1);
      expect(provider.activeSessionId, id1);
    });

    test('switchSession to same session does nothing', () {
      final id = provider.createSession();
      var notified = false;
      provider.addListener(() => notified = true);
      provider.switchSession(id);
      expect(notified, false);
    });

    test('switchSession notifies listeners', () async {
      final id1 = provider.createSession();
      await Future.delayed(const Duration(milliseconds: 2));
      provider.createSession();
      provider.switchSession(id1);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.activeSessionId, id1);
    });

    test('sessions list is unmodifiable', () {
      expect(
        () => provider.sessions.add(
          ConversationSession(id: 'x', title: 'X', createdAt: DateTime.now()),
        ),
        throwsUnsupportedError,
      );
    });

    test('archivedSessions list is unmodifiable', () {
      expect(
        () => provider.archivedSessions.add(
          ConversationSession(id: 'x', title: 'X', createdAt: DateTime.now()),
        ),
        throwsUnsupportedError,
      );
    });

    test('startAutoSave does not throw', () {
      expect(() => provider.startAutoSave(), returnsNormally);
    });
  });
}
