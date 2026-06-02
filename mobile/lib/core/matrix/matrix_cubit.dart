import '../di/app_di.dart';
import '../app_logger.dart';
import '../call_service.dart';
import 'dart:async';
import 'dart:io' if (dart.library.html) '';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'matrix_service.dart';
import 'matrix_dtos.dart';
import 'package:matrix/matrix.dart';

class MatrixState {
  final bool isLoading;
  final String? error;
  final String? activeRoomId;
  final Map<String, bool> typingUsers;
  final List<Event> newEvents;

  const MatrixState({
    this.isLoading = false,
    this.error,
    this.activeRoomId,
    this.typingUsers = const {},
    this.newEvents = const [],
  });

  MatrixState copyWith({
    bool? isLoading,
    String? error,
    String? activeRoomId,
    Map<String, bool>? typingUsers,
    List<Event>? newEvents,
  }) {
    return MatrixState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      typingUsers: typingUsers ?? this.typingUsers,
      newEvents: newEvents ?? this.newEvents);
  }
}

class MatrixCubit extends Cubit<MatrixState> {
  MatrixCubit() : super(const MatrixState());

  final MatrixService _service = getIt<MatrixService>();
  StreamSubscription? _syncSub;

  bool get isLoggedIn => _service.isLoggedIn;
  String? get userId => _service.userId;
  String? get homeserver => _service.homeserver;
  List<Room> get rooms => _service.rooms;
  List<Room> get directChats => _service.directChats;
  List<Room> get groupChats => _service.groupChats;
  Client? get client => _service.client;

  bool get isLoading => state.isLoading;
  String? get error => state.error;
  String? get activeRoomId => state.activeRoomId;
  Room? get activeRoom {
    final roomId = state.activeRoomId;
    return roomId != null ? _service.getRoom(roomId) : null;
  }
  List<Event> get newEvents => state.newEvents;

  bool isUserTyping(String roomId, String senderId) {
    return state.typingUsers['${roomId}_$senderId'] ?? false;
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
      AppLogger.instance.warning('App error', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Map<String, String>? getMediaHeaders() {
    final c = _service.client;
    if (c == null) return null;
    final token = c.accessToken;
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token'};
    }
    return null;
  }

  void clearNewEvents() {
    emit(state.copyWith(newEvents: []));
  }

  static const _maxNewEvents = 100;

  void _addNewEvent(Event event) {
    final list = List<Event>.from(state.newEvents)..add(event);
    if (list.length > _maxNewEvents) {
      list.removeRange(0, list.length - _maxNewEvents);
    }
    emit(state.copyWith(newEvents: list));
  }

  Future<void> login(
    String username,
    String password,
    String homeserverUrl) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _service.login(username, password, homeserverUrl);
      _listenToSync();
      _initCallService();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
    emit(state.copyWith(isLoading: false));
  }

  Future<void> loginWithToken(String token, String homeserverUrl) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _service.loginWithToken(token, homeserverUrl);
      _listenToSync();
      _initCallService();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
    emit(state.copyWith(isLoading: false));
  }

  Future<void> register(
    String username,
    String password,
    String homeserverUrl) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _service.register(username, password, homeserverUrl);
      _listenToSync();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
    emit(state.copyWith(isLoading: false));
  }

  Future<bool> tryRestoreSession() async {
    emit(state.copyWith(isLoading: true));
    final ok = await _service.tryRestoreSession();
    if (ok) _listenToSync();
    emit(state.copyWith(isLoading: false));
    return ok;
  }

  Future<void> logout() async {
    _syncSub?.cancel();
    await _service.logout();
    emit(state.copyWith(activeRoomId: null));
  }

  void setActiveRoom(String roomId) {
    emit(state.copyWith(activeRoomId: roomId));
  }

  void clearActiveRoom() {
    emit(state.copyWith(activeRoomId: null));
  }

  Future<String> createDirectChat(String userId) async {
    final roomId = await _service.createDirectChat(userId);
    emit(state);
    return roomId;
  }

  Future<String> createGroupChat(
    String name, {
    List<String>? userIds,
    String? topic,
  }) async {
    final roomId = await _service.createGroupChat(
      name,
      invite: userIds,
      topic: topic);
    emit(state);
    return roomId;
  }

  Future<bool> sendMessage(String roomId, String text) async {
    try {
      await _service.sendMessage(roomId, text);
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Send message failed',
        error: e,
        stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> sendTypingNotification(
    String roomId, {
    required bool isTyping,
  }) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      await room.setTyping(isTyping, timeout: isTyping ? 5000 : 0);
    } catch (e, stackTrace) {
      AppLogger.instance.error('App error', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> sendImage(
    String roomId,
    String filePath,
    String fileName) async {
    if (kIsWeb) return;
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      final bytes = await File(filePath).readAsBytes();
      if (bytes.length > 20 * 1024 * 1024) {
        throw Exception('Image size exceeds 20MB limit');
      }
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'jpg';
      final mimeMap = {
        'jpg': 'jpeg',
        'jpeg': 'jpeg',
        'png': 'png',
        'gif': 'gif',
        'webp': 'webp',
      };
      final mimeType = 'image/${mimeMap[ext] ?? ext}';
      final file = MatrixFile.fromMimeType(
        bytes: bytes,
        name: fileName,
        mimeType: mimeType);
      await room.sendFileEvent(file);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Send image failed',
        error: e,
        stackTrace: stackTrace);
    }
  }

  Future<void> sendFile(String roomId, String filePath, String fileName) async {
    if (kIsWeb) return;
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      final bytes = await File(filePath).readAsBytes();
      if (bytes.length > 50 * 1024 * 1024) {
        throw Exception('File size exceeds 50MB limit');
      }
      final file = MatrixFile(bytes: bytes, name: fileName);
      await room.sendFileEvent(file);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Send file failed',
        error: e,
        stackTrace: stackTrace);
    }
  }

  Future<void> sendVideo(
    String roomId,
    String filePath,
    String fileName, {
    int? durationMs,
    int? width,
    int? height,
  }) async {
    if (kIsWeb) return;
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      final bytes = await File(filePath).readAsBytes();
      if (bytes.length > 100 * 1024 * 1024) {
        throw Exception('Video size exceeds 100MB limit');
      }
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'mp4';
      final mimeMap = {
        'mp4': 'mp4',
        'webm': 'webm',
        'mov': 'quicktime',
        'avi': 'x-msvideo',
        'mkv': 'x-matroska',
      };
      final mimeType = 'video/${mimeMap[ext] ?? ext}';
      final file = MatrixVideoFile(
        bytes: bytes,
        name: fileName,
        mimeType: mimeType,
        duration: durationMs,
        width: width,
        height: height);
      await room.sendFileEvent(file);
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Send video failed',
        error: e,
        stackTrace: stackTrace);
    }
  }

  Future<List<Profile>> searchUsers(String query) async {
    return await _service.searchUsers(query);
  }

  Future<Profile?> getUserProfile(String userId) async {
    return await _service.getUserProfile(userId);
  }

  Future<void> redactMessage(String roomId, String eventId, {String? reason}) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      await room.redactEvent(eventId, reason: reason);
    } catch (e, stackTrace) {
      AppLogger.instance.error('Redact message failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> editMessage(String roomId, String eventId, String newContent) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      final matrixEvent = room.getEventById(eventId);
      if (matrixEvent == null) return;
      final event = Event.fromMatrixEvent(matrixEvent, room: room);
      await room.editTextEvent(event, newText: newContent);
    } catch (e, stackTrace) {
      AppLogger.instance.error('Edit message failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> markAsRead(String roomId, String eventId) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      await room.setReadMarker(eventId, mRead: eventId);
    } catch (e, stackTrace) {
      AppLogger.instance.error('Mark as read failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> setMuteRoom(String roomId, bool muted) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      await room.setPushRuleState(muted ? PushRuleState.dontNotify : PushRuleState.notify);
    } catch (e, stackTrace) {
      AppLogger.instance.error('Set mute room failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> sendVoiceMessage(String roomId, String filePath, int durationMs) async {
    if (kIsWeb) return;
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      final bytes = await File(filePath).readAsBytes();
      final file = MatrixAudioFile(
        bytes: bytes,
        name: 'voice_message.m4a',
        duration: durationMs);
      await room.sendFileEvent(file);
    } catch (e, stackTrace) {
      AppLogger.instance.error('Send voice failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<String?> sendCustomEvent(String roomId, Map<String, dynamic> content, {String type = 'm.room.message'}) async {
    final room = _service.getRoom(roomId);
    if (room == null) return null;
    try {
      final eventId = await room.sendEvent(content, type: type);
      return eventId;
    } catch (e, stackTrace) {
      AppLogger.instance.error('Send custom event failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  String? getMediaUrl(String mxcUrl) => _service.getMediaUrl(mxcUrl);

  String? getRoomName(String roomId) {
    final room = _service.getRoom(roomId);
    return room?.displayName;
  }

  String? getRoomAvatar(String roomId) {
    final room = _service.getRoom(roomId);
    return room?.avatar;
  }

  bool isRoomEncrypted(String roomId) {
    final room = _service.getRoom(roomId);
    return room?.encrypted ?? false;
  }

  String? getLastEventId(String roomId) {
    final room = _service.getRoom(roomId);
    return room?.lastEvent?.eventId;
  }

  List<String> getRoomMemberIds(String roomId) {
    final room = _service.getRoom(roomId);
    if (room == null) return [];
    return room.getParticipants().map((u) => u.id).toList();
  }

  List<String> getTypingUserIds(String roomId) {
    final room = _service.getRoom(roomId);
    if (room == null) return [];
    final client = _service.client;
    return room.typingUsers
        .where((u) => u.id != client?.userID)
        .map((u) => u.id)
        .toList();
  }

  bool isRoomMuted(String roomId) {
    final room = _service.getRoom(roomId);
    if (room == null) return false;
    return room.pushRuleState == PushRuleState.dontNotify;
  }

  String? getRoomTopic(String roomId) {
    final room = _service.getRoom(roomId);
    return room?.topic;
  }

  int getRoomMemberCount(String roomId) {
    final room = _service.getRoom(roomId);
    return room?.getParticipants().length ?? 0;
  }

  String? getFingerprintKey() {
    return _service.client?.fingerprintKey;
  }

  bool isRoomJoined(String roomId) {
    final room = _service.getRoom(roomId);
    return room != null && room.membership == Membership.join;
  }

  int getRoomNotificationCount(String roomId) {
    final room = _service.getRoom(roomId);
    return room?.notificationCount ?? 0;
  }

  List<RoomInfo> getDirectChats() {
    final client = _service.client;
    if (client == null) return [];
    final rooms = client.rooms.where((r) => r.isDirectChat).toList();
    rooms.sort((a, b) => a.name.compareTo(b.name));
    return rooms.map(_roomToInfo).toList();
  }

  List<RoomInfo> getAllRooms() {
    final client = _service.client;
    if (client == null) return [];
    return client.rooms.map(_roomToInfo).toList();
  }

  RoomInfo? getRoomInfo(String roomId) {
    final room = _service.getRoom(roomId);
    if (room == null) return null;
    return _roomToInfo(room);
  }

  List<MemberInfo> getRoomMembers(String roomId) {
    final room = _service.getRoom(roomId);
    if (room == null) return [];
    return room.getParticipants()
        .map((u) => MemberInfo(
              id: u.id,
              displayName: u.calcDisplayname(),
              avatarUrl: u.avatarUrl?.toString(),
            ))
        .toList();
  }

  List<EventInfo> getRoomEvents(String roomId) {
    final room = _service.getRoom(roomId);
    if (room == null) return [];
    return room.lastEvent != null
        ? [_eventToInfo(room.lastEvent!)]
        : [];
  }

  List<ProfileInfo> searchUsersInfo(String query) async {
    final profiles = await searchUsers(query);
    return profiles
        .map((p) => ProfileInfo(
              userId: p.userId,
              displayName: p.displayName,
              avatarUrl: p.avatarUrl?.toString(),
            ))
        .toList();
  }

  Future<void> leaveRoom(String roomId) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      await room.leave();
    } catch (e, stackTrace) {
      AppLogger.instance.error('Leave room failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> inviteToRoom(String roomId, String userId) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      await room.invite(userId);
    } catch (e, stackTrace) {
      AppLogger.instance.error('Invite to room failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> setRoomName(String roomId, String name) async {
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      await room.setName(name);
    } catch (e, stackTrace) {
      AppLogger.instance.error('Set room name failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> setRoomAvatar(String roomId, String filePath) async {
    if (kIsWeb) return;
    final room = _service.getRoom(roomId);
    if (room == null) return;
    try {
      final bytes = await File(filePath).readAsBytes();
      final file = MatrixImageFile(bytes: bytes, name: 'avatar.png');
      await room.setAvatar(file);
    } catch (e, stackTrace) {
      AppLogger.instance.error('Set room avatar failed', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> ignoreUser(String userId) async {
    final client = _service.client;
    if (client == null) return;
    try {
      await client.ignoreUser(userId);
    } catch (e, stackTrace) {
      AppLogger.instance.error('Ignore user failed', error: e, stackTrace: stackTrace);
    }
  }

  String? getDirectChatUserId(String roomId) {
    final room = _service.getRoom(roomId);
    return room?.directChatMatrixID;
  }

  bool isRoomDirectChat(String roomId) {
    final room = _service.getRoom(roomId);
    return room?.isDirectChat ?? false;
  }

  bool isRoomFavourite(String roomId) {
    final room = _service.getRoom(roomId);
    return room?.isFavourite ?? false;
  }

  RoomInfo _roomToInfo(Room room) {
    return RoomInfo(
      id: room.id,
      displayName: room.getLocalizedDisplayname(),
      avatarUrl: room.avatar?.toString(),
      isDirectChat: room.isDirectChat,
      directChatMatrixId: room.directChatMatrixID,
      isEncrypted: room.encrypted,
      isMuted: room.pushRuleState == PushRuleState.dontNotify,
      isFavourite: room.isFavourite,
      notificationCount: room.notificationCount,
      memberCount: room.getParticipants().length,
      topic: room.topic,
      lastEvent: room.lastEvent != null ? _eventToInfo(room.lastEvent!) : null,
    );
  }

  EventInfo _eventToInfo(Event event) {
    return EventInfo(
      eventId: event.eventId,
      senderId: event.senderId,
      body: event.body,
      plaintextBody: event.plaintextBody,
      formattedBody: event.content['formatted_body'] as String?,
      content: event.content,
      timestamp: event.originServerTs,
      type: event.type,
      msgType: event.content['msgtype'] as String?,
    );
  }

  Future<List<SearchMessageResult>> searchMessages(String query, {int maxRooms = 10, int maxEventsPerRoom = 20}) async {
    final client = _service.client;
    if (client == null) return [];
    final results = <SearchMessageResult>[];
    final rooms = client.rooms;
    final roomsToSearch = rooms.length > maxRooms ? rooms.sublist(0, maxRooms) : rooms;
    for (final room in roomsToSearch) {
      try {
        final timeline = await room.getTimeline();
        var count = 0;
        for (final event in timeline.events) {
          if (count >= maxEventsPerRoom) break;
          if (event.body.toLowerCase().contains(query.toLowerCase())) {
            results.add(SearchMessageResult(
              roomName: room.getLocalizedDisplayname(),
              roomId: room.id,
              eventId: event.eventId,
              body: event.body));
            count++;
          }
        }
      } catch (_) {}
    }
    return results;
  }

  Future<List<FileEventResult>> getAllFileEvents() async {
    final client = _service.client;
    if (client == null) return [];
    final results = <FileEventResult>[];
    for (final room in client.rooms) {
      try {
        final timeline = await room.getTimeline();
        for (final event in timeline.events) {
          if (event.type == EventTypes.Message) {
            final content = event.content;
            final msgType = content['msgtype'] as String?;
            if (msgType == 'm.image' || msgType == 'm.video' || msgType == 'm.file') {
              final mxcUrl = content['url'] as String?;
              if (mxcUrl != null) {
                final info = content['info'] as Map<String, dynamic>?;
                results.add(FileEventResult(
                  name: event.body,
                  senderId: event.senderId,
                  roomId: room.id,
                  roomName: room.getLocalizedDisplayname(),
                  timestamp: event.originServerTs,
                  msgType: msgType ?? 'm.file',
                  mxcUrl: mxcUrl,
                  thumbnailMxcUrl: info?['thumbnail_url'] as String?,
                  size: info?['size'] as int?,
                  mimeType: info?['mimetype'] as String?,
                ));
              }
            }
          }
        }
      } catch (_) {}
    }
    return results;
  }

  String? getThumbnailUrl(String mxcUrl, {int width = 200, int height = 200}) {
    final client = _service.client;
    if (client == null) return null;
    try {
      return Uri.parse(mxcUrl).getThumbnailUri(client, width: width, height: height).toString();
    } catch (_) {
      return null;
    }
  }

  Future<Timeline?> getRoomTimeline(String roomId) async {
    final room = _service.getRoom(roomId);
    if (room == null) return null;
    try {
      return await room.getTimeline();
    } catch (e, stackTrace) {
      AppLogger.instance.error('Get timeline failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  void _listenToSync() {
    _syncSub?.cancel();
    _syncSub = _service.client?.onSync.stream.listen((update) {
      final joined = update.rooms?.join;
      final typingUsers = Map<String, bool>.from(state.typingUsers);
      if (joined != null && joined.isNotEmpty) {
        for (final entry in joined.entries) {
          final timeline = entry.value.timeline;
          if (timeline != null) {
            for (final eventMap in timeline.events ?? []) {
              try {
                final room = _service.client?.getRoomById(entry.key);
                if (room != null) {
                  final event = Event.fromMatrixEvent(eventMap, room);
                  if (event.type == EventTypes.Message &&
                      event.senderId != userId) {
                    _addNewEvent(event);
                  }
                }
              } catch (e, stackTrace) {
                AppLogger.instance.error(
                  'App error',
                  error: e,
                  stackTrace: stackTrace);
              }
            }
          }

          final ephemeral = entry.value.ephemeral;
          if (ephemeral != null) {
            for (final event in ephemeral) {
              try {
                if (event.type == 'm.typing') {
                  final content = event.content;
                  final userIds = content['user_ids'] as List<dynamic>? ?? [];
                  final roomId = entry.key;
                  typingUsers.removeWhere(
                    (k, _) => k.startsWith('${roomId}_'));
                  for (final uid in userIds) {
                    if (uid != userId) {
                      typingUsers['${roomId}_$uid'] = true;
                    }
                  }
                }
              } catch (e, stackTrace) {
                AppLogger.instance.error(
                  'App error',
                  error: e,
                  stackTrace: stackTrace);
              }
            }
          }
        }
      }
      emit(state.copyWith(typingUsers: typingUsers));
    });
  }

  void _initCallService() {
    final client = _service.client;
    if (client != null) {
      getIt<CallService>().init(client);
      AppLogger.instance.info('CallService initialized with Matrix client');
    }
  }

  @override
  Future<void> close() {
    _syncSub?.cancel();
    return super.close();
  }
}
