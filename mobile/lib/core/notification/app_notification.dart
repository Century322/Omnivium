enum NotificationType { message, invite, system, mention }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? roomId;
  final String? senderId;
  final DateTime timestamp;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.roomId,
    this.senderId,
    required this.timestamp,
    this.read = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? roomId,
    String? senderId,
    DateTime? timestamp,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }

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

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    type: _parseType(json['type']),
    roomId: json['roomId'] as String?,
    senderId: json['senderId'] as String?,
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
    read: json['read'] as bool? ?? false,
  );

  static NotificationType _parseType(dynamic value) {
    if (value is String) {
      return NotificationType.values.where((e) => e.name == value).firstOrNull ?? NotificationType.system;
    }
    return NotificationType.system;
  }
}
