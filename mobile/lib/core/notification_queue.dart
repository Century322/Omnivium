import 'dart:async';
import 'push_notification_service.dart';
import 'notification_center.dart' as nc;

class NotificationQueue {
  static final NotificationQueue _instance = NotificationQueue._();
  static NotificationQueue get instance => _instance;
  NotificationQueue._();

  final Map<String, int> _dialogUnreadCounts = {};
  final Map<String, String> _dialogLastMessage = {};
  final Map<String, String> _dialogLastSender = {};
  final Set<String> _activeDialogs = {};
  Timer? _delayTimer;
  final List<_PendingNotification> _pending = [];

  static const int _maxNotificationsPerDialog = 5;
  static const Duration _delayDuration = Duration(seconds: 2);

  void markDialogActive(String dialogId) {
    _activeDialogs.add(dialogId);
  }

  void markDialogInactive(String dialogId) {
    _activeDialogs.remove(dialogId);
  }

  void enqueue({
    required String dialogId,
    required String sender,
    required String message,
    String channelId = 'messages',
    Map<String, dynamic>? data,
  }) {
    if (_activeDialogs.contains(dialogId)) {
      _dialogUnreadCounts[dialogId] = (_dialogUnreadCounts[dialogId] ?? 0) + 1;
      _dialogLastMessage[dialogId] = message;
      _dialogLastSender[dialogId] = sender;
      return;
    }

    _pending.add(_PendingNotification(
      dialogId: dialogId,
      sender: sender,
      message: message,
      channelId: channelId,
      data: data,
    ));

    _delayTimer?.cancel();
    _delayTimer = Timer(_delayDuration, _flush);
  }

  void _flush() {
    if (_pending.isEmpty) return;

    final byDialog = <String, List<_PendingNotification>>{};
    for (final n in _pending) {
      byDialog.putIfAbsent(n.dialogId, () => []).add(n);
    }
    _pending.clear();

    for (final entry in byDialog.entries) {
      final dialogId = entry.key;
      final messages = entry.value;
      final count = _dialogUnreadCounts[dialogId] ?? 0;
      _dialogUnreadCounts[dialogId] = count + messages.length;

      final last = messages.last;
      _dialogLastMessage[dialogId] = last.message;
      _dialogLastSender[dialogId] = last.sender;

      final totalCount = _dialogUnreadCounts[dialogId]!;
      String title;
      String body;

      if (totalCount == 1) {
        title = last.sender;
        body = last.message;
      } else {
        title = last.sender;
        body = '$totalCount 条新消息';
      }

      PushNotificationService.instance.showLocalNotification(
        title: title,
        body: body,
        channelId: last.channelId,
        data: {'dialogId': dialogId, ...?last.data},
      );
    }

    nc.NotificationCenter.post(nc.Event.pushNotificationReceived);
  }

  void clearDialog(String dialogId) {
    _dialogUnreadCounts.remove(dialogId);
    _dialogLastMessage.remove(dialogId);
    _dialogLastSender.remove(dialogId);
    _pending.removeWhere((n) => n.dialogId == dialogId);
  }

  void clearAll() {
    _dialogUnreadCounts.clear();
    _dialogLastMessage.clear();
    _dialogLastSender.clear();
    _pending.clear();
    _delayTimer?.cancel();
  }

  int getUnreadCount(String dialogId) => _dialogUnreadCounts[dialogId] ?? 0;
  String? getLastMessage(String dialogId) => _dialogLastMessage[dialogId];
  String? getLastSender(String dialogId) => _dialogLastSender[dialogId];
}

class _PendingNotification {
  final String dialogId;
  final String sender;
  final String message;
  final String channelId;
  final Map<String, dynamic>? data;

  _PendingNotification({
    required this.dialogId,
    required this.sender,
    required this.message,
    required this.channelId,
    this.data,
  });
}
