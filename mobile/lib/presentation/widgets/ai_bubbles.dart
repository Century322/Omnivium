import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/agent/agent_orchestrator.dart';
import 'image_viewer.dart';

class UserBubble extends StatelessWidget {
  final String content;
  final VoidCallback? onLongPress;
  const UserBubble({super.key, required this.content, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.acc(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: AppColors.bg(context),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class AiTextBubble extends StatelessWidget {
  final String content;
  final bool isStreaming;
  final VoidCallback? onLongPress;
  const AiTextBubble({
    super.key,
    required this.content,
    this.isStreaming = false,
    this.onLongPress,
  });

  static List<String> extractImageUrls(String text) {
    final regex = RegExp(
      r'https?://\S+\.(jpg|jpeg|png|gif|webp|bmp)(\?\S*)?',
      caseSensitive: false,
    );
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  static String removeImageUrls(String text, List<String> urls) {
    var result = text;
    for (final url in urls) {
      result = result.replaceAll(url, '');
    }
    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = extractImageUrls(content);
    final textContent = imageUrls.isEmpty
        ? content
        : removeImageUrls(content, imageUrls);
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (textContent.isNotEmpty)
                    Text(
                      textContent,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  for (final url in imageUrls) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewer(imageUrl: url),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          width: 200,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            width: 200,
                            height: 150,
                            color: AppColors.sfAlt(context),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.acc(context),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            width: 200,
                            height: 80,
                            color: AppColors.sfAlt(context),
                            child: Icon(
                              LucideIcons.imageOff,
                              color: AppColors.iconGray(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isStreaming)
              Container(
                width: 2,
                height: 16,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: AppColors.acc(context),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ExecutionLogBubble extends StatelessWidget {
  final AgentLogEntry log;
  const ExecutionLogBubble({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final isSuccess = log.success == true;
    final isRunning = log.isRunning;
    final duration = log.duration.inMilliseconds;
    return Container(
      margin: const EdgeInsets.only(left: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sfAlt(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRunning)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.acc(context).withValues(alpha: 0.7),
              ),
            )
          else
            Icon(
              isSuccess ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
              size: 14,
              color: isSuccess ? AppColors.ok(context) : AppColors.dng(context),
            ),
          const SizedBox(width: 8),
          Icon(
            LucideIcons.wrench,
            size: 12,
            color: AppColors.sec(context).withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            log.skillName,
            style: TextStyle(
              color: AppColors.textHint(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isRunning) ...[
            const SizedBox(width: 8),
            Text(
              '${duration}ms',
              style: TextStyle(
                color: AppColors.iconGray(context),
                fontSize: 11,
              ),
            ),
          ],
          if (isRunning) ...[
            const SizedBox(width: 8),
            Text(
              localeProvider.t('execution_running'),
              style: TextStyle(color: AppColors.acc(context), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class AiActionRow extends StatelessWidget {
  final String content;
  final int msgIndex;
  final VoidCallback onRegenerate;
  final VoidCallback onCopy;
  final VoidCallback onSpeak;
  final VoidCallback onShare;
  final VoidCallback onMore;

  const AiActionRow({
    super.key,
    required this.content,
    required this.msgIndex,
    required this.onRegenerate,
    required this.onCopy,
    required this.onSpeak,
    required this.onShare,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _actionIcon(
          context,
          LucideIcons.rotateCcw,
          localeProvider.t('regenerate'),
          onTap: onRegenerate,
        ),
        const SizedBox(width: 20),
        _actionIcon(
          context,
          LucideIcons.clipboardCopy,
          localeProvider.t('copy'),
          onTap: onCopy,
        ),
        const SizedBox(width: 20),
        _actionIcon(
          context,
          LucideIcons.headphones,
          localeProvider.t('listen'),
          onTap: onSpeak,
        ),
        const SizedBox(width: 20),
        _actionIcon(
          context,
          LucideIcons.share,
          localeProvider.t('share'),
          onTap: onShare,
        ),
        const Spacer(),
        _actionIcon(
          context,
          LucideIcons.moreVertical,
          localeProvider.t('more'),
          onTap: onMore,
        ),
      ],
    );
  }

  static Widget _actionIcon(
    BuildContext context,
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.sec(context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: AppColors.sec(context), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
