import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/di/app_di.dart';
import '../../../core/matrix/matrix_cubit.dart';
import '../../../core/matrix/friend_chat_cubit.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';
import '../link_preview_card.dart';
import 'chat_components.dart';

class FriendMessageBubble extends StatelessWidget {
  final FriendMessageData message;
  final int index;
  final VoidCallback onLongPress;
  final bool isRead;
  final Widget? messageContent;

  const FriendMessageBubble({
    super.key,
    required this.message,
    required this.index,
    required this.onLongPress,
    this.isRead = false,
    this.messageContent,
  });

  @override
  Widget build(BuildContext context) {
    final msg = message;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onLongPress,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: msg.isImage || msg.isFile
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.isMe ? AppColors.acc(context) : AppColors.sf(context),
              borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (msg.isVoice && msg.url != null)
                  VoiceMessagePlayer(url: msg.url ?? '', isMe: msg.isMe)
                else if (msg.isImage && msg.url != null)
                  ImageBubble(url: msg.url ?? '', isMe: msg.isMe)
                else if (msg.isFile)
                  FileBubble(fileName: msg.content, isMe: msg.isMe)
                else ...[
                  if (msg.hasReply) _buildReplyPreview(context, msg),
                  if (msg.forwardFrom != null) _buildForwardBadge(context, msg),
                  messageContent ?? _buildDefaultContent(context, msg),
                  _buildLinkPreviews(context, msg.content),
                ],
                if (msg.timestamp != null) _buildTimestamp(context, msg),
                if (msg.isMe) _buildReadStatus(context),
              ])))));
  }

  Widget _buildReplyPreview(BuildContext context, FriendMessageData msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: msg.isMe ? AppColors.bg(context).withValues(alpha: 0.15) : AppColors.accBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppColors.acc(context), width: 3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg.replyToSender ?? '', style: TextStyle(color: AppColors.acc(context), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(msg.replyToContent ?? '',
              style: TextStyle(color: msg.isMe ? AppColors.bg(context).withValues(alpha: 0.7) : AppColors.textTertiary(context), fontSize: 12),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ]));
  }

  Widget _buildForwardBadge(BuildContext context, FriendMessageData msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: msg.isMe ? AppColors.bg(context).withValues(alpha: 0.1) : AppColors.sfAlt(context),
        borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.forward, size: 12, color: AppColors.textTertiary(context)),
          const SizedBox(width: 4),
          Text('${localeProvider.t("forwarded_from")} ${msg.forwardFrom}',
              style: TextStyle(color: AppColors.textTertiary(context), fontSize: 11, fontStyle: FontStyle.italic)),
        ]));
  }

  Widget _buildDefaultContent(BuildContext context, FriendMessageData msg) {
    final displayText = _stripReplyFallback(msg.content);
    final hasFormatting = displayText.contains('**') || displayText.contains('*') || displayText.contains('`') ||
        displayText.contains('```') || displayText.contains('#') || displayText.contains('[') ||
        displayText.contains('>') || msg.formattedContent != null;

    if (hasFormatting) {
      return MarkdownBody(
        data: displayText,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: msg.isMe ? AppColors.bg(context) : AppColors.textSecondary(context), fontSize: 15, fontWeight: msg.isMe ? FontWeight.w500 : FontWeight.w400),
          code: TextStyle(color: msg.isMe ? AppColors.bg(context) : AppColors.acc(context), backgroundColor: msg.isMe ? AppColors.bg(context).withValues(alpha: 0.15) : AppColors.sfAlt(context), fontSize: 13),
          codeblockDecoration: BoxDecoration(color: msg.isMe ? AppColors.bg(context).withValues(alpha: 0.1) : AppColors.sfAlt(context), borderRadius: BorderRadius.circular(8)),
          blockquote: TextStyle(color: msg.isMe ? AppColors.bg(context).withValues(alpha: 0.7) : AppColors.textTertiary(context), fontSize: 14),
          blockquoteDecoration: BoxDecoration(border: Border(left: BorderSide(color: AppColors.acc(context), width: 3))),
          listBullet: TextStyle(color: msg.isMe ? AppColors.bg(context) : AppColors.textSecondary(context), fontSize: 15)));
    }

    return Text(displayText,
        style: TextStyle(color: msg.isMe ? AppColors.bg(context) : AppColors.textSecondary(context), fontSize: 15, fontWeight: msg.isMe ? FontWeight.w500 : FontWeight.w400));
  }

  Widget _buildLinkPreviews(BuildContext context, String text) {
    final urlRegex = RegExp(r'https?://[^\s<>"{}|\\^`\[\]]+');
    final matches = urlRegex.allMatches(text);
    if (matches.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: matches.map((match) {
        final url = text.substring(match.start, match.end);
        return Padding(padding: const EdgeInsets.only(top: 6), child: LinkPreviewCard(url: url));
      }).toList());
  }

  Widget _buildTimestamp(BuildContext context, FriendMessageData msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatMessageTime(msg.timestamp ?? DateTime.now()),
              style: TextStyle(color: msg.isMe ? AppColors.bg(context).withValues(alpha: 0.5) : AppColors.textDisabled(context), fontSize: 10)),
          if (msg.isEdited) ...[
            const SizedBox(width: 4),
            Text('(${localeProvider.t("edited")})',
                style: TextStyle(color: msg.isMe ? AppColors.bg(context).withValues(alpha: 0.4) : AppColors.textDisabled(context), fontSize: 9, fontStyle: FontStyle.italic)),
          ],
        ]));
  }

  Widget _buildReadStatus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: isRead
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.checkCheck, size: 14, color: AppColors.acc(context).withValues(alpha: 0.7)),
              const SizedBox(width: 3),
              Text(localeProvider.t('read'), style: TextStyle(color: AppColors.acc(context).withValues(alpha: 0.7), fontSize: 11)),
            ])
          : Icon(LucideIcons.check, size: 14, color: AppColors.iconGray(context)));
  }

  String _stripReplyFallback(String content) {
    final lines = content.split('\n');
    final result = <String>[];
    var pastFallback = false;
    for (final line in lines) {
      if (!pastFallback && line.startsWith('> ')) continue;
      if (!pastFallback && !line.startsWith('> ')) pastFallback = true;
      if (pastFallback && line.isEmpty && result.isEmpty) continue;
      result.add(line);
    }
    return result.join('\n').trim();
  }

  String _formatMessageTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
