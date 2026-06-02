import 'package:matrix/matrix.dart';
import '../../core/di/app_di.dart';
import '../../core/matrix/matrix_cubit.dart';
import '../../core/matrix/friend_chat_cubit.dart';

class FriendMessageParser {
  static List<FriendMessageData> parseTimeline(Timeline timeline) {
    final matrix = getIt<MatrixCubit>();
    final messages = <FriendMessageData>[];
    final eventMap = <String, Event>{};
    for (final event in timeline.events) {
      eventMap[event.eventId] = event;
    }
    for (final event in timeline.events) {
      if (event.type == EventTypes.Message && event.body.isNotEmpty) {
        final isMe = event.senderId == matrix.userId;
        final msgType = event.content['msgtype'] as String?;
        final url =
            event.content['url'] as String? ??
            (event.content['file'] is Map
                ? (event.content['file'] as Map<String, dynamic>)['url'] as String?
                : null);
        final audioDuration = event.content['info'] is Map
            ? (event.content['info'] as Map<String, dynamic>)['duration'] as int?
            : null;
        final relatesTo = event.content['m.relates_to'] as Map<String, dynamic>?;
        final replyToId = relatesTo != null && relatesTo['m.in_reply_to'] is Map
            ? (relatesTo['m.in_reply_to'] as Map<String, dynamic>)['event_id'] as String?
            : null;
        String? replyToContent;
        String? replyToSender;
        if (replyToId != null) {
          final replyEvent = eventMap[replyToId];
          if (replyEvent != null) {
            replyToContent = replyEvent.body;
            replyToSender = replyEvent.senderId;
          }
        }
        final formattedContent = event.content['formatted_body'] as String?;
        final forwardFrom = _extractForwardFrom(formattedContent);
        final isEdited = event.content['m.new_content'] != null ||
            (event.content['m.relates_to'] as Map<String, dynamic>?)?['rel_type'] == 'm.replace';
        messages.add(FriendMessageData(
          isMe: isMe,
          content: event.body,
          eventId: event.eventId,
          msgType: msgType,
          url: url,
          audioDuration: audioDuration,
          replyToId: replyToId,
          replyToContent: replyToContent,
          replyToSender: replyToSender,
          formattedContent: formattedContent,
          senderId: event.senderId,
          timestamp: event.originServerTs,
          isEdited: isEdited,
          forwardFrom: forwardFrom,
        ));
      }
    }
    return messages;
  }

  static String? _extractForwardFrom(String? formattedBody) {
    if (formattedBody == null) return null;
    final forwardRegex = RegExp(r'Forwarded from:\s*(.+?)(?:<br|</blockquote>|$)', caseSensitive: false);
    final match = forwardRegex.firstMatch(formattedBody);
    return match?.group(1)?.trim();
  }
}
