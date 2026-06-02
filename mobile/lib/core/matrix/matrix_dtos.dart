class RoomInfo {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool isDirectChat;
  final String? directChatMatrixId;
  final bool isEncrypted;
  final bool isMuted;
  final bool isFavourite;
  final int notificationCount;
  final int memberCount;
  final String? topic;
  final EventInfo? lastEvent;

  const RoomInfo({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.isDirectChat = false,
    this.directChatMatrixId,
    this.isEncrypted = false,
    this.isMuted = false,
    this.isFavourite = false,
    this.notificationCount = 0,
    this.memberCount = 0,
    this.topic,
    this.lastEvent,
  });
}

class MemberInfo {
  final String id;
  final String displayName;
  final String? avatarUrl;

  const MemberInfo({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });
}

class EventInfo {
  final String eventId;
  final String senderId;
  final String body;
  final String? plaintextBody;
  final String? formattedBody;
  final Map<String, dynamic> content;
  final DateTime timestamp;
  final String type;
  final String? msgType;

  const EventInfo({
    required this.eventId,
    required this.senderId,
    required this.body,
    this.plaintextBody,
    this.formattedBody,
    this.content = const {},
    required this.timestamp,
    required this.type,
    this.msgType,
  });
}

class ProfileInfo {
  final String userId;
  final String? displayName;
  final String? avatarUrl;

  const ProfileInfo({
    required this.userId,
    this.displayName,
    this.avatarUrl,
  });
}

class SearchMessageResult {
  final String roomName;
  final String roomId;
  final String eventId;
  final String body;

  const SearchMessageResult({
    required this.roomName,
    required this.roomId,
    required this.eventId,
    required this.body,
  });
}

class FileEventResult {
  final String name;
  final String senderId;
  final String roomId;
  final String roomName;
  final DateTime timestamp;
  final String msgType;
  final String mxcUrl;
  final String? thumbnailMxcUrl;
  final int? size;
  final String? mimeType;

  const FileEventResult({
    required this.name,
    required this.senderId,
    required this.roomId,
    required this.roomName,
    required this.timestamp,
    required this.msgType,
    required this.mxcUrl,
    this.thumbnailMxcUrl,
    this.size,
    this.mimeType,
  });
}
