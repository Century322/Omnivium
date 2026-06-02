import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:matrix/matrix.dart';
import '../../../core/di/app_di.dart';
import '../../../core/matrix/matrix_cubit.dart';
import '../../../core/matrix/friend_chat_cubit.dart';
import '../../../core/agent/agent_orchestrator.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';
import 'chat_components.dart';

mixin FriendChatMessageActions on State {
  String get chatTargetId;
  List<FriendMessageData> get friendMessages;
  set friendMessages(List<FriendMessageData> value);

  void showMessageActions(
    BuildContext context,
    int index,
    FriendMessageData msg, {
    required VoidCallback onReply,
    required void Function(FriendMessageData) onEdit,
    required VoidCallback onRefresh,
  }) {
    HapticService.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled(context),
                  borderRadius: BorderRadius.circular(2))),
            ),
            if (!msg.isMe)
              ListTile(
                leading: Icon(LucideIcons.reply, color: AppColors.sec(context)),
                title: Text(localeProvider.t('reply'), style: TextStyle(color: AppColors.textPrimary(context))),
                onTap: () { Navigator.pop(context); onReply(); }),
            if (msg.isMe && !msg.isImage && !msg.isFile && !msg.isVoice)
              ListTile(
                leading: Icon(LucideIcons.pencil, color: AppColors.sec(context)),
                title: Text(localeProvider.t('edit_message'), style: TextStyle(color: AppColors.textPrimary(context))),
                onTap: () { Navigator.pop(context); onEdit(msg); }),
            ListTile(
              leading: Icon(LucideIcons.forward, color: AppColors.sec(context)),
              title: Text(localeProvider.t('forward_message'), style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () { Navigator.pop(context); _forwardMessage(context, msg); }),
            ListTile(
              leading: Icon(LucideIcons.share2, color: AppColors.sec(context)),
              title: Text(localeProvider.t('share_to_friend'), style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet<bool>(
                  context: context,
                  backgroundColor: AppColors.sf(context),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => ShareToFriendSheet(content: msg.content));
              }),
            ListTile(
              leading: Icon(LucideIcons.sparkles, color: AppColors.acc(context)),
              title: Text(localeProvider.t('analyze_with_ai'), style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(context);
                _triggerAI(context, '@AI 分析这条消息：${msg.content}');
              }),
            ListTile(
              leading: Icon(LucideIcons.copy, color: AppColors.sec(context)),
              title: Text(localeProvider.t('copy_message'), style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localeProvider.t('copied')), duration: const Duration(milliseconds: 1000)));
              }),
            if (msg.isMe)
              ListTile(
                leading: Icon(LucideIcons.trash2, color: AppColors.dng(context)),
                title: Text(localeProvider.t('recall_message'), style: TextStyle(color: AppColors.dng(context))),
                onTap: () {
                  Navigator.pop(context);
                  _recallMessage(context, index, onRefresh);
                }),
            const SizedBox(height: 8),
          ])));
  }

  void forwardMessage(BuildContext context, FriendMessageData msg) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ForwardSheet(
        messageContent: msg.content,
        fromRoomId: chatTargetId,
      ),
    ).then((targetRoomId) async {
      if (targetRoomId == null || !mounted) return;
      try {
        await getIt<MatrixCubit>().sendMessage(targetRoomId, msg.content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localeProvider.t('forwarded')),
              backgroundColor: AppColors.ok(context),
              duration: const Duration(milliseconds: 1500)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dng(context)));
        }
      }
    });
  }

  void _triggerAI(BuildContext context, String query) {
    try {
      final orchestrator = getIt<AgentOrchestrator>();
      orchestrator.sendMessage(query.replaceFirst(RegExp(r'^@(?:ai|omni)\s*', caseSensitive: false), '').trim());
    } catch (_) {}
  }

  void _recallMessage(BuildContext context, int index, VoidCallback onRefresh) async {
    if (index < 0 || index >= friendMessages.length) return;
    final msg = friendMessages[index];
    if (msg.eventId == null) return;
    try {
      await getIt<MatrixCubit>().redactMessage(chatTargetId, msg.eventId!);
      getIt<AnalyticsService>().logSendMessage(type: 'recall');
      onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dng(context)));
      }
    }
  }

  void editMessage(BuildContext context, FriendMessageData msg, VoidCallback onRefresh) {
    if (msg.eventId == null) return;
    final editCtrl = TextEditingController(text: msg.content);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        title: Text(localeProvider.t('edit'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: TextField(
          controller: editCtrl,
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15),
          autofocus: true,
          maxLines: 5,
          minLines: 1,
          maxLength: 4096,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bg(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localeProvider.t('cancel'), style: TextStyle(color: AppColors.textTertiary(context)))),
          TextButton(
            onPressed: () async {
              final newText = editCtrl.text.trim();
              Navigator.pop(context);
              if (newText.isEmpty || newText == msg.content) return;
              try {
                final content = <String, dynamic>{
                  'msgtype': 'm.text',
                  'body': '* $newText',
                  'm.new_content': {'msgtype': 'm.text', 'body': newText},
                  'm.relates_to': {
                    'rel_type': 'm.replace',
                    'event_id': msg.eventId,
                  },
                };
                await getIt<MatrixCubit>().sendCustomEvent(chatTargetId, content);
                onRefresh();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dng(context)));
                }
              }
            },
            child: Text(localeProvider.t('save'), style: TextStyle(color: AppColors.acc(context)))),
        ]));
  }
}
