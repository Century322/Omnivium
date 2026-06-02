import 'package:freezed_annotation/freezed_annotation.dart';

part 'unified_message.freezed.dart';
part 'unified_message.g.dart';

enum MessageType { aiChat, friendChat, groupChat, post, system }

enum MessageFormat { text, image, video, audio, file, card }

@freezed
sealed class UnifiedMessage with _$UnifiedMessage {
  const UnifiedMessage._();

  const factory UnifiedMessage({
    required String id,
    required String senderId,
    required String content,
    required MessageType type,
    required MessageFormat format,
    required DateTime timestamp,
    String? replyToId,
    String? sourceContext,
    @Default({}) Map<String, dynamic> metadata,
  }) = _UnifiedMessage;

  factory UnifiedMessage.fromJson(Map<String, dynamic> json) =>
      _$UnifiedMessageFromJson(json);

  bool get isMine => metadata['is_mine'] as bool? ?? false;
  String? get senderName => metadata['sender_name'] as String?;
  String? get senderAvatarUrl => metadata['sender_avatar_url'] as String?;
  String? get roomId => metadata['room_id'] as String?;
  String? get model => metadata['model'] as String?;
  bool get isEdited => metadata['is_edited'] as bool? ?? false;
  bool get isRecalled => metadata['is_recalled'] as bool? ?? false;
  String? get mediaUrl => metadata['media_url'] as String?;
  String? get mediaFileName => metadata['media_file_name'] as String?;
  int? get mediaFileSize => metadata['media_file_size'] as int?;
  int? get mediaDuration => metadata['media_duration'] as int?;
}
