import 'app_logger.dart';
import 'auth_service.dart';

class SupabaseSyncService {
  static final SupabaseSyncService _instance = SupabaseSyncService._();
  static SupabaseSyncService get instance => _instance;
  SupabaseSyncService._();

  bool _initialized = false;
  String? _userId;
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  bool get isAvailable => _initialized && _userId != null;
  String get requireUserId {
    final id = _userId;
    if (id == null) throw StateError('SupabaseSyncService not initialized');
    return id;
  }

  Future<void> init() async {
    final auth = AuthService.instance;
    if (!auth.isAuthenticated) {
      _userId = null;
      _initialized = false;
      return;
    }
    _userId = auth.matrixUserId ?? auth.currentUser?.id;
    _initialized = _userId != null;
  }

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt < _maxRetries) {
          AppLogger.instance.info(
            'Supabase operation failed (attempt ${attempt + 1}/$_maxRetries): $e',
          );
          await Future.delayed(_retryDelay * (attempt + 1));
        } else {
          AppLogger.instance.error(
            'Supabase operation failed after $_maxRetries retries',
            error: e,
          );
          rethrow;
        }
      }
    }
    throw StateError('Unreachable');
  }

  Future<void> ensureTables() async {
    final client = AuthService.instance.client;
    if (client == null) return;
    try {
      await client.from('sessions').select('id').limit(1);
    } catch (e) {
      AppLogger.instance.info('Tables may not exist yet: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSessions() async {
    if (!isAvailable) return [];
    try {
      return await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return <Map<String, dynamic>>[];
        final response = await client
            .from('sessions')
            .select()
            .eq('user_id', requireUserId)
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      AppLogger.instance.info('Fetch sessions failed: $e');
      return [];
    }
  }

  Future<bool> upsertSession(Map<String, dynamic> session) async {
    if (!isAvailable) return false;
    try {
      await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return;
        final data = Map<String, dynamic>.from(session);
        data['user_id'] = _userId;
        await client.from('sessions').upsert(data, onConflict: 'id');
      });
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Upsert session failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> deleteSession(String id) async {
    if (!isAvailable) return;
    try {
      await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return;
        await client
            .from('sessions')
            .delete()
            .eq('id', id)
            .eq('user_id', requireUserId);
      });
    } catch (e) {
      AppLogger.instance.info('Delete session failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotes() async {
    if (!isAvailable) return [];
    try {
      return await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return <Map<String, dynamic>>[];
        final response = await client
            .from('notes')
            .select()
            .eq('user_id', requireUserId)
            .order('updated_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      AppLogger.instance.info('Fetch notes failed: $e');
      return [];
    }
  }

  Future<void> upsertNote(Map<String, dynamic> note) async {
    if (!isAvailable) return;
    try {
      await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return;
        final data = Map<String, dynamic>.from(note);
        data['user_id'] = _userId;
        await client.from('notes').upsert(data, onConflict: 'id');
      });
    } catch (e) {
      AppLogger.instance.info('Upsert note failed: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    if (!isAvailable) return;
    try {
      await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return;
        await client
            .from('notes')
            .delete()
            .eq('id', id)
            .eq('user_id', requireUserId);
      });
    } catch (e) {
      AppLogger.instance.info('Delete note failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMemories() async {
    if (!isAvailable) return [];
    try {
      return await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return <Map<String, dynamic>>[];
        final response = await client
            .from('memories')
            .select()
            .eq('user_id', requireUserId)
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      AppLogger.instance.info('Fetch memories failed: $e');
      return [];
    }
  }

  Future<void> upsertMemory(Map<String, dynamic> memory) async {
    if (!isAvailable) return;
    try {
      await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return;
        final data = Map<String, dynamic>.from(memory);
        data['user_id'] = _userId;
        await client.from('memories').upsert(data, onConflict: 'id');
      });
    } catch (e) {
      AppLogger.instance.info('Upsert memory failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchQuickCommands() async {
    if (!isAvailable) return [];
    try {
      return await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return <Map<String, dynamic>>[];
        final response = await client
            .from('quick_commands')
            .select()
            .eq('user_id', requireUserId)
            .order('sort_order', ascending: true);
        return List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      AppLogger.instance.info('Fetch quick commands failed: $e');
      return [];
    }
  }

  Future<void> upsertQuickCommand(Map<String, dynamic> command) async {
    if (!isAvailable) return;
    try {
      await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return;
        final data = Map<String, dynamic>.from(command);
        data['user_id'] = _userId;
        await client.from('quick_commands').upsert(data, onConflict: 'id');
      });
    } catch (e) {
      AppLogger.instance.info('Upsert quick command failed: $e');
    }
  }

  Future<void> deleteQuickCommand(String id) async {
    if (!isAvailable) return;
    try {
      await _withRetry(() async {
        final client = AuthService.instance.client;
        if (client == null) return;
        await client
            .from('quick_commands')
            .delete()
            .eq('id', id)
            .eq('user_id', requireUserId);
      });
    } catch (e) {
      AppLogger.instance.info('Delete quick command failed: $e');
    }
  }
}
