import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import '../../../core/di/app_di.dart';
import '../../../core/matrix/matrix_cubit.dart';
import '../../../core/app_logger.dart';
import '../home_components.dart';

mixin FriendChatMatrixHandler on State {
  String get chatTargetId;
  List<FriendMessageData> get friendMessages;
  set friendMessages(List<FriendMessageData> value);
  ScrollController get scrollController;
  Future<CachedPresence?>? get presenceFutureValue;
  set presenceFutureValue(Future<CachedPresence?>? value);
  bool get isOtherTypingValue;
  set isOtherTypingValue(bool value);

  void onMatrixChanged() {
    if (!mounted) return;
    if (chatTargetId.isEmpty) return;
    final matrix = getIt<MatrixCubit>();
    final typingUserIds = matrix.getTypingUserIds(chatTargetId);
    final nowTyping = typingUserIds.isNotEmpty;
    if (nowTyping != isOtherTypingValue) {
      isOtherTypingValue = nowTyping;
    }
    final newEvents = matrix.newEvents;
    final relevantEvents = newEvents.where((e) {
      return e.roomId == chatTargetId;
    }).toList();
    if (relevantEvents.isNotEmpty) {
      final newMessages = <FriendMessageData>[];
      for (final event in relevantEvents) {
        if (event.type == EventTypes.Message && event.body.isNotEmpty) {
          final eventId = event.eventId;
          if (friendMessages.any((m) => m.eventId == eventId)) continue;
          final isMe = event.senderId == matrix.userId;
          final msgType = event.content['msgtype'] as String?;
          final url =
              event.content['url'] as String? ??
              (event.content['file'] is Map
                  ? (event.content['file'] as Map<String, dynamic>)['url'] as String?
                  : null);
          final audioDuration = event.content['info'] is Map
              ? (event.content['info'] as Map<String, dynamic>)['duration'] as int?
              : null;
          newMessages.add(FriendMessageData(
            isMe: isMe,
            content: event.body,
            msgType: msgType,
            url: url,
            audioDuration: audioDuration,
            eventId: eventId));
        }
      }
      if (newMessages.isNotEmpty) {
        friendMessages = [...friendMessages, ...newMessages];
      }
      matrix.clearNewEvents();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        scrollToLatest();
      });
    } else {
      setState(() {});
    }
  }

  void scrollToLatest() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut);
  }

  void markRoomAsRead(String roomId) {
    final matrix = getIt<MatrixCubit>();
    final lastEventId = matrix.getLastEventId(roomId);
    if (lastEventId != null) {
      matrix.markAsRead(roomId, lastEventId);
    }
  }

  Future<CachedPresence?> getPresence() async {
    if (chatTargetId.isEmpty) return null;
    final matrix = getIt<MatrixCubit>();
    final client = matrix.client;
    if (client == null) return null;
    final memberIds = matrix.getRoomMemberIds(chatTargetId);
    final otherUserId = memberIds.where((id) => id != matrix.userId).firstOrNull;
    if (otherUserId == null) return null;
    try {
      return await client.fetchCurrentPresence(
        otherUserId,
        fetchOnlyFromCached: true);
    } catch (e, stackTrace) {
      AppLogger.instance.warning('App error', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
