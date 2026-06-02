import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum MessageType { text, image, file, audio, video }

@freezed
sealed class ChatMessage with _$ChatMessage {
  const ChatMessage._();

  const factory ChatMessage({
    required String id,
    required String roomId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String content,
    @Default(MessageType.text) MessageType type,
    required DateTime timestamp,
    String? replyToId,
    String? replyToContent,
    String? replyToSender,
    @Default(false) bool isEdited,
    @Default(false) bool isRecalled,
    String? mediaUrl,
    String? mediaFileName,
    int? mediaFileSize,
    int? mediaDuration,
    Map<String, dynamic>? metadata,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  bool get isMine => metadata?['is_mine'] as bool? ?? false;
}
