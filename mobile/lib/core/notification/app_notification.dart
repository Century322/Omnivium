import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

enum NotificationType { message, invite, system, mention }

NotificationType _parseType(dynamic value) {
  if (value is String) {
    return NotificationType.values
            .where((e) => e.name == value)
            .firstOrNull ??
        NotificationType.system;
  }
  return NotificationType.system;
}

@freezed
class AppNotification with _$AppNotification {
  const AppNotification._();

  const factory AppNotification({
    required String id,
    required String title,
    required String body,
    required NotificationType type,
    String? roomId,
    String? senderId,
    required DateTime timestamp,
    @Default(false) bool read,
  }) = _AppNotification;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.name,
    'roomId': roomId,
    'senderId': senderId,
    'timestamp': timestamp.toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: _parseType(json['type']),
        roomId: json['roomId'] as String?,
        senderId: json['senderId'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        read: json['read'] as bool? ?? false);
}
