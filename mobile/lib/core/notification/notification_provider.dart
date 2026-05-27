import '../app_logger.dart';
import '../notification_center.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_notification.dart';
import '../matrix/matrix_provider.dart';
import '../database_service.dart';
import '../../presentation/theme/locale_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;
  StreamSubscription? _syncSub;
  bool _disposed = false;
  static const _maxNotifications = 100;

  static const _notificationsKey = 'omnivium_notifications';

  Future<void> init() async {
    final db = DatabaseService.instance;
    final raw = db.getCache(_notificationsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _notifications.clear();
        for (final item in list) {
          _notifications.add(
            AppNotification.fromJson(item as Map<String, dynamic>),
          );
        }
        if (_notifications.length > _maxNotifications) {
          _notifications.removeRange(_maxNotifications, _notifications.length);
        }
        if (!_disposed) notifyListeners();
      } catch (e, stackTrace) {
        AppLogger.instance.error(
          'App error',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    NotificationCenter.observe(Event.pushNotification, _onPushNotification);
  }

  static int _pushCounter = 0;

  void _onPushNotification(Map<String, dynamic>? data) {
    if (data == null) return;
    _pushCounter++;
    _notifications.insert(
      0,
      AppNotification(
        id: 'push_${DateTime.now().millisecondsSinceEpoch}_${_pushCounter}',
        title: data['title'] as String? ?? '',
        body: data['body'] as String? ?? '',
        type: NotificationType.system,
        timestamp: DateTime.now(),
      ),
    );
    if (_notifications.length > _maxNotifications) {
      _notifications.removeRange(_maxNotifications, _notifications.length);
    }
    _persist();
    if (!_disposed) notifyListeners();
  }

  Future<void> _persist() async {
    final db = DatabaseService.instance;
    final json = jsonEncode(
      _notifications.take(100).map((n) => n.toJson()).toList(),
    );
    await db.putCache(_notificationsKey, json);
  }

  void listenToMatrix(MatrixProvider matrixProvider) {
    _syncSub?.cancel();
    _syncSub = matrixProvider.client?.onSync.stream.listen((update) {
      final joined = update.rooms?.join;
      if (joined == null || joined.isEmpty) return;
      for (final entry in joined.entries) {
        final timeline = entry.value.timeline;
        if (timeline == null) continue;
        for (final eventMap in timeline.events ?? []) {
          try {
            final roomId = entry.key;
            final senderId = eventMap['sender'] as String? ?? '';
            final content = eventMap['content'] as Map<String, dynamic>? ?? {};
            final body = content['body'] as String? ?? '';
            final type = eventMap['type'] as String? ?? '';
            final ts = eventMap['origin_server_ts'] as int? ?? 0;
            if (type == 'm.room.message' && body.isNotEmpty) {
              final room = matrixProvider.client?.getRoomById(roomId);
              final roomName = room?.getLocalizedDisplayname() ?? roomId;
              final notifId = '${roomId}_${senderId}_$ts';
              final existing = _notifications.any((n) => n.id == notifId);
              if (!existing) {
                _notifications.insert(
                  0,
                  AppNotification(
                    id: notifId,
                    title: roomName,
                    body: body,
                    type: NotificationType.message,
                    roomId: roomId,
                    senderId: senderId,
                    timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
                  ),
                );
              }
            }
            if (type == 'm.room.member') {
              final userId = content['membership'] == 'invite' ? senderId : '';
              if (userId.isNotEmpty) {
                final notifId = '${roomId}_invite_$ts';
                final existing = _notifications.any((n) => n.id == notifId);
                if (!existing) {
                  _notifications.insert(
                    0,
                    AppNotification(
                      id: notifId,
                      title: localeProvider.t('friend_invite'),
                      body:
                          '$senderId ${localeProvider.t('invited_you_to_chat')}',
                      type: NotificationType.invite,
                      roomId: roomId,
                      senderId: senderId,
                      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
                    ),
                  );
                }
              }
            }
          } catch (e, stackTrace) {
            AppLogger.instance.error(
              'App error',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      }
      if (_notifications.length > _maxNotifications) {
        _notifications.removeRange(_maxNotifications, _notifications.length);
      }
      _persist();
      if (!_disposed) notifyListeners();
    });
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(read: true);
      _persist();
      if (!_disposed) notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].read) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
    }
    _persist();
    if (!_disposed) notifyListeners();
  }

  void remove(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _persist();
    if (!_disposed) notifyListeners();
  }

  void clear() {
    _notifications.clear();
    _persist();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _syncSub?.cancel();
    super.dispose();
  }
}
