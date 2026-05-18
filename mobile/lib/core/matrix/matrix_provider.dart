import '../app_logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'matrix_service.dart';
import 'package:matrix/matrix.dart';

class MatrixProvider extends ChangeNotifier {
  final MatrixService _service = MatrixService.instance;
  StreamSubscription? _syncSub;
  bool _disposed = false;

  bool get isLoggedIn => _service.isLoggedIn;
  String? get userId => _service.userId;
  String? get homeserver => _service.homeserver;
  List<Room> get rooms => _service.rooms;
  List<Room> get directChats => _service.directChats;
  List<Room> get groupChats => _service.groupChats;
  Client? get client => _service.client;

  final Map<String, bool> _typingUsers = {};
  bool isUserTyping(String roomId, String senderId) {
    return _typingUsers['${roomId}_$senderId'] ?? false;
  }

  String? getMediaUrl(String mxcUri) {
    if (!mxcUri.startsWith('mxc://')) return mxcUri;
    final c = _service.client;
    if (c == null) return null;
    try {
      final parts = mxcUri.replaceFirst('mxc://', '').split('/');
      if (parts.length < 2) return null;
      return '${c.homeserver}/_matrix/media/v3/download/${parts[0]}/${parts[1]}';
    } catch (e, stackTrace) {
    AppLogger.instance.warning('Operation failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _activeRoomId;
  String? get activeRoomId => _activeRoomId;
  Room? get activeRoom => _activeRoomId != null ? _service.getRoom(_activeRoomId!) : null;

  final List<Event> _newEvents = [];
  List<Event> get newEvents => List.unmodifiable(_newEvents);
  void clearNewEvents() => _newEvents.clear();

  Future<void> login(String username, String password, String homeserverUrl) async {
    _isLoading = true;
    _error = null;
    if (!_disposed) notifyListeners();
    try {
      await _service.login(username, password, homeserverUrl);
      _listenToSync();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> register(String username, String password, String homeserverUrl) async {
    _isLoading = true;
    _error = null;
    if (!_disposed) notifyListeners();
    try {
      await _service.register(username, password, homeserverUrl);
      _listenToSync();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    if (!_disposed) notifyListeners();
  }

  Future<bool> tryRestoreSession() async {
    _isLoading = true;
    if (!_disposed) notifyListeners();
    final ok = await _service.tryRestoreSession();
    if (ok) _listenToSync();
    _isLoading = false;
    if (!_disposed) notifyListeners();
    return ok;
  }

  Future<void> logout() async {
    _syncSub?.cancel();
    await _service.logout();
    _activeRoomId = null;
    if (!_disposed) notifyListeners();
  }

  void setActiveRoom(String roomId) {
    _activeRoomId = roomId;
    if (!_disposed) notifyListeners();
  }

  void clearActiveRoom() {
    _activeRoomId = null;
    if (!_disposed) notifyListeners();
  }

  Future<String> createDirectChat(String userId) async {
    final roomId = await _service.createDirectChat(userId);
    if (!_disposed) notifyListeners();
    return roomId;
  }

  Future<String> createGroupChat(String name, {List<String>? userIds}) async {
    final roomId = await _service.createGroupChat(name, invite: userIds);
    if (!_disposed) notifyListeners();
    return roomId;
  }

  Future<void> sendMessage(String roomId, String text) async {
    await _service.sendMessage(roomId, text);
  }

  Future<void> sendTypingNotification(String roomId, {required bool isTyping}) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      await room.setTyping(isTyping, timeout: isTyping ? 5000 : 0);
    } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
  }

  Future<void> sendImage(String roomId, String filePath, String fileName) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      final bytes = await File(filePath).readAsBytes();
      final file = MatrixFile.fromMimeType(bytes: bytes, name: fileName, mimeType: 'image/${fileName.split('.').last}');
      await room.sendFileEvent(file);
    } catch (e, stackTrace) { AppLogger.instance.error('Send image failed', error: e, stackTrace: stackTrace); }
  }

  Future<void> sendFile(String roomId, String filePath, String fileName) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      final bytes = await File(filePath).readAsBytes();
      final file = MatrixFile(bytes: bytes, name: fileName);
      await room.sendFileEvent(file);
    } catch (e, stackTrace) { AppLogger.instance.error('Send file failed', error: e, stackTrace: stackTrace); }
  }

  Future<List<Profile>> searchUsers(String query) async {
    return await _service.searchUsers(query);
  }

  Future<Profile?> getUserProfile(String userId) async {
    return await _service.getUserProfile(userId);
  }

  void _listenToSync() {
    _syncSub?.cancel();
    _syncSub = _service.client?.onSync.stream.listen((update) {
      final joined = update.rooms?.join;
      if (joined != null && joined.isNotEmpty) {
        for (final entry in joined.entries) {
          final timeline = entry.value.timeline;
          if (timeline != null) {
            for (final eventMap in timeline.events ?? []) {
              try {
                final room = _service.client?.getRoomById(entry.key);
                if (room != null) {
                  final event = Event.fromMatrixEvent(eventMap, room);
                  if (event.type == EventTypes.Message && event.senderId != userId) {
                    _newEvents.add(event);
                  }
                }
              } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
            }
          }

          final ephemeral = entry.value.ephemeral;
          if (ephemeral != null) {
            for (final event in ephemeral) {
              try {
                if (event.type == 'm.typing') {
                  final content = event.content;
                  final userIds = content['user_ids'] as List? ?? [];
                  final roomId = entry.key;
                  _typingUsers.removeWhere((k, _) => k.startsWith('${roomId}_'));
                  for (final uid in userIds) {
                    if (uid != userId) {
                      _typingUsers['${roomId}_$uid'] = true;
                    }
                  }
                }
              } catch (e, stackTrace) { AppLogger.instance.error('Operation failed', error: e, stackTrace: stackTrace); }
            }
          }
        }
      }
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _syncSub?.cancel();
    super.dispose();
  }
}
