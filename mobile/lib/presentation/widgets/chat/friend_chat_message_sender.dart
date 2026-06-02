import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/di/app_di.dart';
import '../../../core/matrix/matrix_cubit.dart';
import '../../../core/matrix/friend_chat_cubit.dart';
import '../../../core/agent/agent_orchestrator.dart';
import '../../../core/services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';

mixin FriendChatMessageSender on State {
  String get chatTargetId;

  void sendFriendMessage(
    BuildContext context, {
    required String text,
    required TextEditingController textController,
    FriendMessageData? replyingTo,
    VoidCallback? onClearedReply,
  }) {
    if (text.trim().isEmpty) return;
    final matrix = getIt<MatrixCubit>();
    if (!matrix.isLoggedIn || chatTargetId.isEmpty) return;

    final content = <String, dynamic>{'msgtype': 'm.text', 'body': text};
    if (replyingTo != null && replyingTo.eventId != null) {
      content['m.relates_to'] = {
        'm.in_reply_to': {'event_id': replyingTo.eventId},
      };
      final replyBody = replyingTo.content;
      final replySender = replyingTo.senderId ?? '';
      content['body'] = '> <$replySender> $replyBody\n\n$text';
    }

    getIt<MatrixCubit>().sendCustomEvent(chatTargetId, content).catchError((Object e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localeProvider.t('send_failed')),
            backgroundColor: AppColors.dng(context),
            duration: const Duration(seconds: 2)));
      }
      return '';
    });
    getIt<AnalyticsService>().logSendMessage(type: 'text');

    textController.clear();
    onClearedReply?.call();
    triggerAIIfNeeded(text);
  }

  void sendVoiceMessage(BuildContext context, String path, Duration duration) {
    final matrix = getIt<MatrixCubit>();
    if (!matrix.isLoggedIn || chatTargetId.isEmpty) return;
    matrix.sendAudioMessage(chatTargetId, path, duration).catchError((Object e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dng(context)));
      }
      return '';
    });
  }

  void sendFileMessage(BuildContext context, String prefix, String fileName, String? filePath) {
    if (filePath == null || filePath.isEmpty) return;
    final matrix = getIt<MatrixCubit>();
    if (!matrix.isLoggedIn || chatTargetId.isEmpty) return;
    matrix.sendFileMessage(chatTargetId, filePath, fileName).catchError((Object e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dng(context)));
      }
      return '';
    });
  }

  void triggerAIIfNeeded(String text) {
    final lower = text.toLowerCase();
    if (!lower.startsWith('@ai') && !lower.startsWith('@omni')) return;
    final query = text.replaceFirst(RegExp(r'^@(?:ai|omni)\s*', caseSensitive: false), '').trim();
    if (query.isEmpty) return;
    try {
      final orchestrator = getIt<AgentOrchestrator>();
      orchestrator.sendMessage(query);
    } catch (_) {}
  }
}
