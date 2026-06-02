// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UnifiedMessage _$UnifiedMessageFromJson(Map json) => $checkedCreate(
  '_UnifiedMessage',
  json,
  ($checkedConvert) {
    final val = _UnifiedMessage(
      id: $checkedConvert('id', (v) => v as String),
      senderId: $checkedConvert('sender_id', (v) => v as String),
      content: $checkedConvert('content', (v) => v as String),
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(_$MessageTypeEnumMap, v),
      ),
      format: $checkedConvert(
        'format',
        (v) => $enumDecode(_$MessageFormatEnumMap, v),
      ),
      timestamp: $checkedConvert(
        'timestamp',
        (v) => DateTime.parse(v as String),
      ),
      replyToId: $checkedConvert('reply_to_id', (v) => v as String?),
      sourceContext: $checkedConvert('source_context', (v) => v as String?),
      metadata: $checkedConvert(
        'metadata',
        (v) => (v as Map?)?.map((k, e) => MapEntry(k as String, e)) ?? const {},
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'senderId': 'sender_id',
    'replyToId': 'reply_to_id',
    'sourceContext': 'source_context',
  },
);

Map<String, dynamic> _$UnifiedMessageToJson(_UnifiedMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender_id': instance.senderId,
      'content': instance.content,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'format': _$MessageFormatEnumMap[instance.format]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'reply_to_id': instance.replyToId,
      'source_context': instance.sourceContext,
      'metadata': instance.metadata,
    };

const _$MessageTypeEnumMap = {
  MessageType.aiChat: 'aiChat',
  MessageType.friendChat: 'friendChat',
  MessageType.groupChat: 'groupChat',
  MessageType.post: 'post',
  MessageType.system: 'system',
};

const _$MessageFormatEnumMap = {
  MessageFormat.text: 'text',
  MessageFormat.image: 'image',
  MessageFormat.video: 'video',
  MessageFormat.audio: 'audio',
  MessageFormat.file: 'file',
  MessageFormat.card: 'card',
};
