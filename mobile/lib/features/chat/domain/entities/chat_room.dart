import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room.freezed.dart';
part 'chat_room.g.dart';

@freezed
sealed class ChatRoom with _$ChatRoom {
  const factory ChatRoom({
    required String id,
    required String name,
    String? avatarUrl,
    @Default(false) bool isDirect,
    @Default(false) bool isGroup,
    @Default(0) int unreadCount,
    String? lastMessage,
    DateTime? lastMessageTime,
    @Default([]) List<String> memberIds,
    String? topic,
    @Default(false) bool isEncrypted,
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json);
}
