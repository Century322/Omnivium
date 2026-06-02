import '../di/app_di.dart';
import '../app_logger.dart';
import '../notification_center.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_notification.dart';
import '../matrix/matrix_cubit.dart';
import '../database_service.dart';
import '../../presentation/theme/locale_cubit.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
  });

  NotificationState copyWith({List<AppNotification>? notifications}) {
    final list = notifications ?? this.notifications;
    return NotificationState(
      notifications: list,
      unreadCount: list.where((n) => !n.read).length);
  }
}

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(const NotificationState());

  StreamSubscription? _syncSub;
  static const _maxNotifications = 100;
  static const _notificationsKey = 'omnivium_notifications';
  static int _pushCounter = 0;

  List<AppNotification> get notifications => state.notifications;
  int get unreadCount => state.unreadCount;

  Future<void> init() async {
    final db = getIt<DatabaseService>();
    final raw = db.getCache(_notificationsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        final notifications = <AppNotification>[];
        for (final item in list) {
          notifications.add(
            AppNotification.fromJson(item as Map<String, dynamic>));
        }
        if (notifications.length > _maxNotifications) {
          notifications.removeRange(_maxNotifications, notifications.length);
        }
        emit(state.copyWith(notifications: notifications));
      } catch (e, stackTrace) {
        AppLogger.instance.error('App error', error: e, stackTrace: stackTrace);
      }
    }
    NotificationCenter.observe(Event.pushNotification, _onPushNotification);
  }

  void _onPushNotification(Map<String, dynamic>? data) {
    if (data == null) return;
    _pushCounter++;
    final list = List<AppNotification>.from(state.notifications);
    list.insert(
      0,
      AppNotification(
        id: 'push_${DateTime.now().millisecondsSinceEpoch}_${_pushCounter}',
        title: data['title'] as String? ?? '',
        body: data['body'] as String? ?? '',
        type: NotificationType.system,
        timestamp: DateTime.now()));
    if (list.length > _maxNotifications) {
      list.removeRange(_maxNotifications, list.length);
    }
    emit(state.copyWith(notifications: list));
    _persist();
  }

  Future<void> _persist() async {
    final db = getIt<DatabaseService>();
    final json = jsonEncode(
      state.notifications.take(100).map((n) => n.toJson()).toList());
    await db.putCache(_notificationsKey, json);
  }

  void listenToMatrix(MatrixCubit MatrixCubit) {
    _syncSub?.cancel();
    _syncSub = MatrixCubit.client?.onSync.stream.listen((update) {
      final joined = update.rooms?.join;
      if (joined == null || joined.isEmpty) return;
      final list = List<AppNotification>.from(state.notifications);
      for (final entry in joined.entries) {
        final timeline = entry.value.timeline;
        if (timeline == null) continue;
        for (final eventMap in timeline.events ?? []) {
          try {
            final roomId = entry.key;
            final event = eventMap as Map<String, dynamic>;
            final senderId = event['sender'] as String? ?? '';
            final content = event['content'] as Map<String, dynamic>? ?? {};
            final body = content['body'] as String? ?? '';
            final type = event['type'] as String? ?? '';
            final ts = event['origin_server_ts'] as int? ?? 0;
            if (type == 'm.room.message' && body.isNotEmpty) {
              final room = MatrixCubit.client?.getRoomById(roomId);
              final roomName = room?.getLocalizedDisplayname() ?? roomId;
              final notifId = '${roomId}_${senderId}_$ts';
              final existing = list.any((n) => n.id == notifId);
              if (!existing) {
                list.insert(
                  0,
                  AppNotification(
                    id: notifId,
                    title: roomName,
                    body: body,
                    type: NotificationType.message,
                    roomId: roomId,
                    senderId: senderId,
                    timestamp: DateTime.fromMillisecondsSinceEpoch(ts)));
              }
            }
            if (type == 'm.room.member') {
              final userId = content['membership'] == 'invite' ? senderId : '';
              if (userId.isNotEmpty) {
                final notifId = '${roomId}_invite_$ts';
                final existing = list.any((n) => n.id == notifId);
                if (!existing) {
                  list.insert(
                    0,
                    AppNotification(
                      id: notifId,
                      title: localeProvider.t('friend_invite'),
                      body:
                          '$senderId ${localeProvider.t('invited_you_to_chat')}',
                      type: NotificationType.invite,
                      roomId: roomId,
                      senderId: senderId,
                      timestamp: DateTime.fromMillisecondsSinceEpoch(ts)));
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
      if (list.length > _maxNotifications) {
        list.removeRange(_maxNotifications, list.length);
      }
      emit(state.copyWith(notifications: list));
      _persist();
    });
  }

  void markAsRead(String id) {
    final list = List<AppNotification>.from(state.notifications);
    final idx = list.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(read: true);
      emit(state.copyWith(notifications: list));
      _persist();
    }
  }

  void markAllAsRead() {
    final list = List<AppNotification>.from(state.notifications);
    for (int i = 0; i < list.length; i++) {
      if (!list[i].read) {
        list[i] = list[i].copyWith(read: true);
      }
    }
    emit(state.copyWith(notifications: list));
    _persist();
  }

  void remove(String id) {
    final list = List<AppNotification>.from(state.notifications);
    list.removeWhere((n) => n.id == id);
    emit(state.copyWith(notifications: list));
    _persist();
  }

  void clear() {
    emit(state.copyWith(notifications: []));
    _persist();
  }

  @override
  Future<void> close() {
    _syncSub?.cancel();
    return super.close();
  }
}
