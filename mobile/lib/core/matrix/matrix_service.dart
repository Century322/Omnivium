
import '../di/app_di.dart';
import '../app_logger.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart' hide Event;
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_center.dart' show NotificationCenter, Event;
import '../vodozemac_init.dart';
import '../secure_storage_service.dart';
import '../note_service.dart';
import '../encryption_service.dart';

import '../identity_bridge.dart';

class MatrixService {
  static final MatrixService _instance = MatrixService._();
  static MatrixService get instance => _instance;
  MatrixService._();

  Client? _client;
  DatabaseApi? _database;
  Database? _rawDb;
  final _lock = _AsyncLock();

  Client? get client => _client;
  bool get isLoggedIn => _client != null && requireClient.isLogged();
  Client get requireClient {
    final c = _client;
    if (c == null) throw StateError('Matrix client not initialized');
    return c;
  }

  String? get userId => _client?.userID;
  String? get homeserver => _client?.homeserver?.toString();

  static const _homeserverKey = 'omnivium_matrix_homeserver';
  static const _tokenKey = 'omnivium_matrix_token';
  static const _userIdKey = 'omnivium_matrix_user_id';
  static const _deviceIdKey = 'omnivium_matrix_device_id';
  static const _deviceNameKey = 'omnivium_matrix_device_name';

  final _secure = getIt<SecureStorageService>();

  NativeImplementations _getNativeImplementations() {
    if (kIsWeb) {
      return NativeImplementationsDummy();
    }
    return NativeImplementationsIsolate(compute, vodozemacInit: initVodozemac);
  }

  Future<void> _closeDatabase() async {
    final db = _database;
    if (db != null) {
      try {
        await db.close();
      } catch (e) {
        AppLogger.instance.warning('Failed to close Matrix database', error: e);
      }
      _database = null;
    }
    final rawDb = _rawDb;
    if (rawDb != null && rawDb.isOpen) {
      try {
        await rawDb.close();
      } catch (e) {
        AppLogger.instance.warning('Failed to close raw database', error: e);
      }
      _rawDb = null;
    }
  }

  Future<Client> _createClient(String homeserverUrl) async {
    return await _lock.synchronized(() async {
      if (_client != null) {
        final currentHomeserver = requireClient.homeserver?.toString();
        if (currentHomeserver == homeserverUrl ||
            currentHomeserver == '$homeserverUrl/') {
          return requireClient;
        }
      }
      await _closeDatabase();

      final client = Client(
        'Omnivium',
        database: await _getDatabase(),
        nativeImplementations: _getNativeImplementations());
      await client.checkHomeserver(Uri.parse(homeserverUrl));
      _client = client;
      return client;
    });
  }

  Future<void> login(
    String username,
    String password,
    String homeserverUrl) async {
    final client = await _createClient(homeserverUrl);
    await client.login(
      LoginType.mLoginPassword,
      password: password,
      identifier: AuthenticationUserIdentifier(user: username));
    await _saveCredentials(client);
    client.backgroundSync = true;
    await getIt<IdentityBridge>().onMatrixLinked(client.userID ?? '');
    NotificationCenter.post(
      Event.loginSuccess,
      data: {'matrix_user_id': client.userID});
  }

  Future<void> loginWithToken(String token, String homeserverUrl) async {
    final client = await _createClient(homeserverUrl);
    await client.login(LoginType.mLoginToken, token: token);
    await _saveCredentials(client);
    client.backgroundSync = true;
    await getIt<IdentityBridge>().onMatrixLinked(client.userID ?? '');
    NotificationCenter.post(
      Event.loginSuccess,
      data: {'matrix_user_id': client.userID});
  }

  Future<void> register(
    String username,
    String password,
    String homeserverUrl) async {
    final client = await _createClient(homeserverUrl);
    await client.register(username: username, password: password);
    await _saveCredentials(client);
    client.backgroundSync = true;
    final matrixId = client.userID ?? '';
    await getIt<IdentityBridge>().onRegistration(
      username,
      matrixId: matrixId.isNotEmpty ? matrixId : null);
    await getIt<IdentityBridge>().onMatrixLinked(matrixId);
  }

  Future<bool> tryRestoreSession() async {
    var token = await _secure.read(_tokenKey);
    var userId = await _secure.read(_userIdKey);
    var homeserver = await _secure.read(_homeserverKey);
    var deviceId = await _secure.read(_deviceIdKey);
    var deviceName = await _secure.read(_deviceNameKey);

    if (token == null || userId == null || homeserver == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        token ??= prefs.getString(_tokenKey);
        userId ??= prefs.getString(_userIdKey);
        homeserver ??= prefs.getString(_homeserverKey);
        deviceId ??= prefs.getString(_deviceIdKey);
        deviceName ??= prefs.getString(_deviceNameKey);
      } catch (e) {
        AppLogger.instance.warning('Fallback credentials read failed', error: e);
      }
    }

    if (token == null || userId == null || homeserver == null) {
      AppLogger.instance.warning('Session restore skipped: missing credentials (token=${token != null}, userId=${userId != null}, hs=${homeserver != null})');
      return false;
    }

    return await _lock.synchronized(() async {
      try {
        if (_client != null && requireClient.isLogged()) {
          return true;
        }

        await _closeDatabase();

        final client = Client(
          'Omnivium',
          database: await _getDatabase(),
          nativeImplementations: _getNativeImplementations());
        try {
          await client.checkHomeserver(Uri.parse(homeserver!));
          await client.init(
            newToken: token!,
            newUserID: userId!,
            newHomeserver: Uri.parse(homeserver),
            newDeviceName: deviceName ?? 'Omnivium',
            newDeviceID: deviceId ?? '');
        } catch (e) {
          AppLogger.instance.warning(
            'Session restore network failed, trying offline',
            error: e);
          try {
            await client.init(
              newToken: token!,
              newUserID: userId!,
              newHomeserver: Uri.parse(homeserver!),
              newDeviceName: deviceName ?? 'Omnivium',
              newDeviceID: deviceId ?? '');
          } catch (e2) {
            AppLogger.instance.warning(
              'Offline session restore also failed',
              error: e2);
            client.dispose();
            await _closeDatabase();
            return false;
          }
        }
        _client = client;
        client.backgroundSync = true;
        final restoredUserId = client.userID ?? '';
        if (restoredUserId.isNotEmpty) {
          await getIt<IdentityBridge>().onMatrixLinked(restoredUserId);
          NotificationCenter.post(
            Event.loginSuccess,
            data: {'matrix_user_id': restoredUserId});
        }
        return true;
      } catch (e, stackTrace) {
        AppLogger.instance.warning(
          'Session restore failed',
          error: e,
          stackTrace: stackTrace);
        await _closeDatabase();
        return false;
      }
    });
  }

  Future<void> logout() async {
    NotificationCenter.post(Event.logout);
    getIt<NoteService>().reset();
    getIt<EncryptionService>().reset();
    try {
      await _client?.logout();
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Logout failed',
        error: e,
        stackTrace: stackTrace);
    }
    _client?.dispose();
    _client = null;
    await _closeDatabase();
    await _secure.delete(_tokenKey);
    await _secure.delete(_userIdKey);
    await _secure.delete(_homeserverKey);
    await _secure.delete(_deviceIdKey);
    await _secure.delete(_deviceNameKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_homeserverKey);
      await prefs.remove(_deviceIdKey);
      await prefs.remove(_deviceNameKey);
    } catch (e) {
      AppLogger.instance.warning('Clear backup credentials failed', error: e);
    }
  }

  Future<void> _saveCredentials(Client client) async {
    final token = client.accessToken;
    final uid = client.userID;
    final hs = client.homeserver;
    final did = client.deviceID;
    final dname = client.clientName;

    try {
      if (token != null) await _secure.write(_tokenKey, token);
      if (uid != null) await _secure.write(_userIdKey, uid);
      if (hs != null) await _secure.write(_homeserverKey, hs.toString());
      if (did != null) await _secure.write(_deviceIdKey, did);
      await _secure.write(_deviceNameKey, dname);
    } catch (e) {
      AppLogger.instance.warning('SecureStorage write failed', error: e);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null) await prefs.setString(_tokenKey, token);
      if (uid != null) await prefs.setString(_userIdKey, uid);
      if (hs != null) await prefs.setString(_homeserverKey, hs.toString());
      if (did != null) await prefs.setString(_deviceIdKey, did);
      await prefs.setString(_deviceNameKey, dname);
    } catch (e) {
      AppLogger.instance.warning('Backup credentials to SharedPreferences failed', error: e);
    }
  }

  Future<DatabaseApi> _getDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/omnivium.db';
    final rawDb = await openDatabase(path);
    _rawDb = rawDb;
    final database = await MatrixSdkDatabase.init('Omnivium', database: rawDb);
    _database = database;
    return database;
  }

  List<Room> get rooms {
    if (_client == null) return [];
    return requireClient.rooms.where((r) => !r.isSpace).toList()..sort((a, b) {
      final aTime =
          a.lastEvent?.originServerTs ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.lastEvent?.originServerTs ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  Room? getRoom(String roomId) => _client?.getRoomById(roomId);

  Future<String> createDirectChat(String userId) async {
    if (_client == null) throw StateError('Not logged in');
    return await requireClient.startDirectChat(userId, enableEncryption: true);
  }

  Future<String> createGroupChat(
    String name, {
    List<String>? invite,
    List<String>? userIds,
    String? topic,
  }) async {
    if (_client == null) throw StateError('Not logged in');
    final roomId = await requireClient.createRoom(
      preset: CreateRoomPreset.privateChat,
      name: name,
      invite: invite ?? userIds,
      topic: topic,
      initialState: [
        StateEvent(
          type: 'm.room.encryption',
          stateKey: '',
          content: {'algorithm': 'm.megolm.v1.aes-sha2'}),
      ]);
    try {
      final room = requireClient.getRoomById(roomId);
      if (room != null && !room.encrypted) {
        await room.enableEncryption();
      }
    } catch (e) {
      AppLogger.instance.warning(
        'Failed to enable encryption for group',
        error: e);
    }
    return roomId;
  }

  Future<void> sendMessage(String roomId, String text) async {
    final room = getRoom(roomId);
    if (room == null) return;
    await room.sendTextEvent(text);
  }

  Future<List<Profile>> searchUsers(String query) async {
    if (_client == null || query.isEmpty) return [];
    try {
      final result = await requireClient.searchUserDirectory(query, limit: 20);
      return result.results;
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Search users failed',
        error: e,
        stackTrace: stackTrace);
      return [];
    }
  }

  Future<Profile?> getUserProfile(String userId) async {
    if (_client == null) return null;
    try {
      return await requireClient.getProfileFromUserId(userId);
    } catch (e, stackTrace) {
      AppLogger.instance.warning(
        'Get user profile failed',
        error: e,
        stackTrace: stackTrace);
      return null;
    }
  }

  List<Room> get directChats {
    if (_client == null) return [];
    return requireClient.rooms
        .where((r) => r.isDirectChat && !r.isSpace)
        .toList();
  }

  List<Room> get groupChats {
    if (_client == null) return [];
    return requireClient.rooms
        .where((r) => !r.isDirectChat && !r.isSpace)
        .toList();
  }

  Stream<SyncUpdate>? get onSync {
    return _client?.onSync.stream;
  }
}

class _AsyncLock {
  Completer<void>? _completer;

  Future<T> synchronized<T>(Future<T> Function() action) async {
    while (_completer != null) {
      final c = _completer;
      if (c != null) await c.future;
    }
    _completer = Completer<void>();
    try {
      return await action();
    } finally {
      final c = _completer;
      _completer = null;
      c?.complete();
    }
  }
}
