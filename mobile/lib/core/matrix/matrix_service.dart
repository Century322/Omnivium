import '../app_logger.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:sqflite/sqflite.dart';
import '../auth_service.dart';
import '../vodozemac_init.dart';
import '../secure_storage_service.dart';

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
  bool get isLoggedIn => _client != null && _client!.isLogged();
  String? get userId => _client?.userID;
  String? get homeserver => _client?.homeserver?.toString();

  static const _homeserverKey = 'omnivium_matrix_homeserver';
  static const _tokenKey = 'omnivium_matrix_token';
  static const _userIdKey = 'omnivium_matrix_user_id';
  static const _deviceIdKey = 'omnivium_matrix_device_id';
  static const _deviceNameKey = 'omnivium_matrix_device_name';

  final _secure = SecureStorageService.instance;

  NativeImplementations _getNativeImplementations() {
    if (kIsWeb) {
      return NativeImplementationsDummy();
    }
    return NativeImplementationsIsolate(
      compute,
      vodozemacInit: initVodozemac,
    );
  }

  Future<void> _closeDatabase() async {
    if (_database != null) {
      try {
        await _database!.close();
      } catch (e) {
        AppLogger.instance.warning('Failed to close Matrix database', error: e);
      }
      _database = null;
    }
    if (_rawDb != null && _rawDb!.isOpen) {
      try {
        await _rawDb!.close();
      } catch (e) {
        AppLogger.instance.warning('Failed to close raw database', error: e);
      }
      _rawDb = null;
    }
  }

  Future<Client> _createClient(String homeserverUrl) async {
    return await _lock.synchronized(() async {
      if (_client != null) {
        final currentHomeserver = _client!.homeserver?.toString();
        if (currentHomeserver == homeserverUrl || currentHomeserver == '$homeserverUrl/') {
          return _client!;
        }
      }
      await _closeDatabase();

      final client = Client(
        'Omnivium',
        database: await _getDatabase(),
        nativeImplementations: _getNativeImplementations(),
      );
      await client.checkHomeserver(Uri.parse(homeserverUrl));
      _client = client;
      return client;
    });
  }

  Future<void> login(String username, String password, String homeserverUrl) async {
    final client = await _createClient(homeserverUrl);
    await client.login(
      LoginType.mLoginPassword,
      password: password,
      identifier: AuthenticationUserIdentifier(user: username),
    );
    await _saveCredentials(client);
    client.backgroundSync = true;
    await IdentityBridge.instance.onMatrixLinked(client.userID ?? '');
  }

  Future<void> loginWithToken(String token, String homeserverUrl) async {
    final client = await _createClient(homeserverUrl);
    await client.login(
      LoginType.mLoginToken,
      token: token,
    );
    await _saveCredentials(client);
    client.backgroundSync = true;
    await IdentityBridge.instance.onMatrixLinked(client.userID ?? '');
  }

  Future<void> register(String username, String password, String homeserverUrl) async {
    final client = await _createClient(homeserverUrl);
    await client.register(username: username, password: password);
    await _saveCredentials(client);
    client.backgroundSync = true;
  }

  Future<bool> tryRestoreSession() async {
    final token = await _secure.read(_tokenKey);
    final userId = await _secure.read(_userIdKey);
    final homeserver = await _secure.read(_homeserverKey);
    final deviceId = await _secure.read(_deviceIdKey);
    final deviceName = await _secure.read(_deviceNameKey);
    if (token == null || userId == null || homeserver == null) return false;

    return await _lock.synchronized(() async {
      try {
        if (_client != null && _client!.isLogged()) {
          return true;
        }

        await _closeDatabase();

        final client = Client(
          'Omnivium',
          database: await _getDatabase(),
          nativeImplementations: _getNativeImplementations(),
        );
        try {
          await client.checkHomeserver(Uri.parse(homeserver));
          await client.init(
            newToken: token,
            newUserID: userId,
            newHomeserver: Uri.parse(homeserver),
            newDeviceName: deviceName ?? 'Omnivium',
            newDeviceID: deviceId ?? '',
          );
        } catch (e) {
          AppLogger.instance.warning('Session restore failed', error: e);
          client.dispose();
          await _closeDatabase();
          return false;
        }
        _client = client;
        client.backgroundSync = true;
        return true;
      } catch (e, stackTrace) {
        AppLogger.instance.warning('Session restore failed', error: e, stackTrace: stackTrace);
        await _closeDatabase();
        return false;
      }
    });
  }

  Future<void> logout() async {
    AuthService.instance.onMatrixLogout();
    try {
      await _client?.logout();
    } catch (e, stackTrace) {
      AppLogger.instance.error('Logout failed', error: e, stackTrace: stackTrace);
    }
    _client?.dispose();
    _client = null;
    await _closeDatabase();
    await _secure.delete(_tokenKey);
    await _secure.delete(_userIdKey);
    await _secure.delete(_homeserverKey);
    await _secure.delete(_deviceIdKey);
    await _secure.delete(_deviceNameKey);
  }

  Future<void> _saveCredentials(Client client) async {
    if (client.accessToken != null) await _secure.write(_tokenKey, client.accessToken!);
    if (client.userID != null) await _secure.write(_userIdKey, client.userID!);
    if (client.homeserver != null) await _secure.write(_homeserverKey, client.homeserver!.toString());
    if (client.deviceID != null) await _secure.write(_deviceIdKey, client.deviceID!);
    await _secure.write(_deviceNameKey, client.clientName);
  }

  Future<DatabaseApi> _getDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/omnivium.db';
    _rawDb = await openDatabase(path);
    _database = await MatrixSdkDatabase.init(
      'Omnivium',
      database: _rawDb!,
    );
    return _database!;
  }

  List<Room> get rooms {
    if (_client == null) return [];
    return _client!.rooms.where((r) => !r.isSpace).toList()
      ..sort((a, b) {
        final aTime = a.lastEvent?.originServerTs ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastEvent?.originServerTs ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
  }

  Room? getRoom(String roomId) => _client?.getRoomById(roomId);

  Future<String> createDirectChat(String userId) async {
    if (_client == null) throw StateError('Not logged in');
    return await _client!.startDirectChat(userId, enableEncryption: true);
  }

  Future<String> createGroupChat(String name, {List<String>? invite, List<String>? userIds}) async {
    if (_client == null) throw StateError('Not logged in');
    return await _client!.createRoom(
      preset: CreateRoomPreset.privateChat,
      name: name,
      invite: invite ?? userIds,
      initialState: [
        StateEvent(
          type: 'm.room.encryption',
          stateKey: '',
          content: {'algorithm': 'm.megolm.v1.aes-sha2'},
        ),
      ],
    );
  }

  Future<void> sendMessage(String roomId, String text) async {
    final room = getRoom(roomId);
    if (room == null) return;
    await room.sendTextEvent(text);
  }

  Future<List<Profile>> searchUsers(String query) async {
    if (_client == null || query.isEmpty) return [];
    try {
      final result = await _client!.searchUserDirectory(query, limit: 20);
      return result.results;
    } catch (e, stackTrace) {
      AppLogger.instance.warning('Search users failed', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<Profile?> getUserProfile(String userId) async {
    if (_client == null) return null;
    try {
      return await _client!.getProfileFromUserId(userId);
    } catch (e, stackTrace) {
      AppLogger.instance.warning('Get user profile failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  List<Room> get directChats {
    if (_client == null) return [];
    return _client!.rooms.where((r) => r.isDirectChat && !r.isSpace).toList();
  }

  List<Room> get groupChats {
    if (_client == null) return [];
    return _client!.rooms.where((r) => !r.isDirectChat && !r.isSpace).toList();
  }

  Stream<SyncUpdate>? get onSync {
    return _client?.onSync.stream;
  }
}

class _AsyncLock {
  final _queue = <Completer<void>>[];
  bool _locked = false;

  Future<T> synchronized<T>(Future<T> Function() action) async {
    final completer = Completer<void>();
    _queue.add(completer);
    if (_locked) {
      await completer.future;
    }
    _locked = true;
    try {
      return await action();
    } finally {
      _locked = false;
      _queue.remove(completer);
      if (_queue.isNotEmpty) {
        _queue.first.complete();
      }
    }
  }
}
