import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:matrix/matrix.dart';
import '../../core/di/app_di.dart';
import '../../core/matrix/matrix_cubit.dart';
import '../../core/services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';
import '../../views/image_viewer.dart';

mixin FriendChatMenuActions on State {
  void showFriendChatMenu(BuildContext context, String roomId) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 180,
        MediaQuery.of(context).padding.top + 60,
        16,
        0),
      color: AppColors.sf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        _menuItem(context, LucideIcons.user, localeProvider.t('view_profile')),
        _menuItem(context, LucideIcons.shieldCheck, localeProvider.t('encrypt_info')),
        _menuItem(context, LucideIcons.bell, localeProvider.t('mute_chat')),
        _menuItem(context, LucideIcons.search, localeProvider.t('search_chat_history')),
        _menuItem(context, LucideIcons.share, localeProvider.t('share_conversation')),
        _menuItem(context, LucideIcons.trash2, localeProvider.t('clear_chat'), isDanger: true),
      ]).then((value) {
      if (value == null) return;
      if (value == localeProvider.t('view_profile')) {
        showFriendProfile(context, roomId);
      } else if (value == localeProvider.t('encrypt_info')) {
        showEncryptionInfo(context, roomId);
      } else if (value == localeProvider.t('mute_chat')) {
        toggleMute(context, roomId);
      } else if (value == localeProvider.t('search_chat_history')) {
        showChatSearch(context);
      } else if (value == localeProvider.t('share_conversation')) {
        shareConversation(context, roomId);
      } else if (value == localeProvider.t('clear_chat')) {
        clearChat(context, roomId);
      }
    });
  }

  PopupMenuItem<String> _menuItem(BuildContext context, IconData icon, String text, {bool isDanger = false}) {
    return PopupMenuItem<String>(
      value: text,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDanger ? AppColors.dng(context) : AppColors.sec(context)),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: isDanger ? AppColors.dng(context) : AppColors.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w500)),
        ]));
  }

  void showFriendProfile(BuildContext context, String roomId) {
    if (roomId.isEmpty) return;
  }

  void showEncryptionInfo(BuildContext context, String roomId) {
    final matrix = getIt<MatrixCubit>();
    final isEncrypted = roomId.isNotEmpty && matrix.isRoomEncrypted(roomId);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isEncrypted ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                color: isEncrypted ? AppColors.acc(context) : AppColors.warn(context), size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(isEncrypted ? localeProvider.t('e2e_encrypted_short') : localeProvider.t('not_encrypted_short'),
                  style: TextStyle(color: AppColors.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w600))),
          ]),
        content: Text(
          isEncrypted ? localeProvider.t('e2e_encrypted_desc') : localeProvider.t('not_encrypted_desc'),
          style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localeProvider.t('ok'), style: TextStyle(color: AppColors.acc(context)))),
        ]));
  }

  Future<void> toggleMute(BuildContext context, String roomId) async {
    if (roomId.isEmpty) return;
    final matrix = getIt<MatrixCubit>();
    final isMuted = matrix.isRoomMuted(roomId);
    await matrix.setMuteRoom(roomId, !isMuted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isMuted ? localeProvider.t('muted_off') : localeProvider.t('muted_on')),
        duration: const Duration(seconds: 2)));
  }

  void shareConversation(BuildContext context, String roomId) {
    final matrix = getIt<MatrixCubit>();
    final client = matrix.client;
    if (client == null) return;
    final room = client.getRoomById(roomId);
    if (room == null) return;
    final messages = <String>[];
    for (final event in room.timeline) {
      if (event.type == 'm.room.message') {
        final body = event.content['body'] as String? ?? '';
        if (body.isNotEmpty) {
          messages.add(body);
        }
      }
    }
    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localeProvider.t('no_messages_to_share'))));
      return;
    }
    final text = messages.take(50).join('\n');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localeProvider.t('conversation_exported'))));
  }

  Future<void> clearChat(BuildContext context, String roomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(localeProvider.t('clear_chat'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text(localeProvider.t('clear_chat_confirm'), style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(localeProvider.t('cancel'), style: TextStyle(color: AppColors.textSecondary(context)))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dng(context), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(localeProvider.t('clear'))),
        ]));
    if (confirmed != true) return;
    try {
      final matrix = getIt<MatrixCubit>();
      await matrix.clearRoomTimeline(roomId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localeProvider.t('chat_cleared')), backgroundColor: AppColors.ok(context)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.dng(context)));
      }
    }
  }

  void showChatSearch(BuildContext context) {
    showSearch(context: context, delegate: _ChatSearchDelegate());
  }
}

class _ChatSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text(query, style: TextStyle(color: AppColors.textPrimary(context))));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(child: Text(localeProvider.t('search_chat_hint'), style: TextStyle(color: AppColors.textTertiary(context))));
  }
}
