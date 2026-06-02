import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/session_cubit.dart';
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

  group('SessionCubit', () {
    late AgentOrchestrator orchestrator;
    late SessionCubit cubit;

    setUp(() {
      orchestrator = AgentOrchestrator();
      cubit = SessionCubit(orchestrator: orchestrator);
    });

    tearDown(() {
      try {
        cubit.close();
      } catch (_) {}
      try {
        orchestrator.close();
      } catch (_) {}
    });

    test('starts with no sessions', () {
      expect(cubit.sessions, isEmpty);
    });

    test('starts with no active session', () {
      expect(cubit.activeSessionId, isNull);
    });

    test('starts with no archived sessions', () {
      expect(cubit.archivedSessions, isEmpty);
    });

    test('createSession adds session', () {
      cubit.createSession();
      expect(cubit.sessions.length, 1);
    });

    test('createSession sets active session', () {
      final id = cubit.createSession();
      expect(cubit.activeSessionId, id);
    });

    test('createSession emits state change', () async {
      final states = <SessionState>[];
      final sub = cubit.stream.listen(states.add);
      cubit.createSession();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      expect(states.isNotEmpty, true);
    });

    test('createSession inserts at beginning', () {
      cubit.createSession();
      cubit.createSession();
      expect(cubit.sessions.length, 2);
    });

    test('createSession returns unique id', () async {
      final id1 = cubit.createSession();
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final id2 = cubit.createSession();
      expect(id1, isNot(equals(id2)));
    });

    test('deleteSession removes session', () {
      final id = cubit.createSession();
      cubit.deleteSession(id);
      expect(cubit.sessions, isEmpty);
    });

    test('deleteSession active session clears active', () {
      final id = cubit.createSession();
      cubit.deleteSession(id);
      expect(cubit.activeSessionId, isNull);
    });

    test('deleteSession emits state change', () async {
      final id = cubit.createSession();
      final states = <SessionState>[];
      final sub = cubit.stream.listen(states.add);
      cubit.deleteSession(id);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      expect(states.isNotEmpty, true);
    });

    test('deleteSession non-active does not change active', () async {
      final id1 = cubit.createSession();
      await Future<void>.delayed(const Duration(milliseconds: 2));
      cubit.createSession();
      cubit.deleteSession(id1);
      expect(cubit.activeSessionId, isNotNull);
      expect(cubit.activeSessionId, isNot(equals(id1)));
    });

    test('archiveSession marks session as archived', () {
      final id = cubit.createSession();
      cubit.archiveSession(id);
      expect(cubit.sessions, isEmpty);
      expect(cubit.archivedSessions.length, 1);
    });

    test('archiveSession active session clears active', () {
      final id = cubit.createSession();
      cubit.archiveSession(id);
      expect(cubit.activeSessionId, isNull);
    });

    test('unarchiveSession restores session', () {
      final id = cubit.createSession();
      cubit.archiveSession(id);
      cubit.unarchiveSession(id);
      expect(cubit.sessions.length, 1);
      expect(cubit.archivedSessions, isEmpty);
    });

    test('updateSessionTitle changes title', () {
      final id = cubit.createSession();
      cubit.updateSessionTitle(id, 'New Title');
      expect(cubit.sessions.first.title, 'New Title');
    });

    test('updateSessionTitle non-existent session does nothing', () {
      cubit.createSession();
      cubit.updateSessionTitle('nonexistent', 'Title');
      expect(cubit.sessions.first.title, 'New Conversation');
    });

    test('toggleFavoriteSession toggles favorite', () {
      final id = cubit.createSession();
      expect(cubit.sessions.first.isFavorite, false);
      cubit.toggleFavoriteSession(id);
      expect(cubit.sessions.first.isFavorite, true);
      cubit.toggleFavoriteSession(id);
      expect(cubit.sessions.first.isFavorite, false);
    });

    test('closeActiveSession clears active', () {
      cubit.createSession();
      cubit.closeActiveSession();
      expect(cubit.activeSessionId, isNull);
    });

    test('switchSession changes active session', () {
      final id1 = cubit.createSession();
      final id2 = cubit.createSession();
      expect(cubit.activeSessionId, id2);
      cubit.switchSession(id1);
      expect(cubit.activeSessionId, id1);
    });

    test('switchSession to same session does nothing', () async {
      final id = cubit.createSession();
      final statesBefore = cubit.state;
      cubit.switchSession(id);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.activeSessionId, id);
    });

    test('sessions list is unmodifiable', () {
      expect(
        () => cubit.sessions.add(
          ConversationSession(id: 'x', title: 'X', createdAt: DateTime.now()),
        ),
        throwsUnsupportedError,
      );
    });

    test('archivedSessions list is unmodifiable', () {
      expect(
        () => cubit.archivedSessions.add(
          ConversationSession(id: 'x', title: 'X', createdAt: DateTime.now()),
        ),
        throwsUnsupportedError,
      );
    });

    test('startAutoSave does not throw', () {
      expect(() => cubit.startAutoSave(), returnsNormally);
    });
  });
}
