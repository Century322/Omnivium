import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';
import '../widgets/home_components.dart';
import '../widgets/chat_search_sheet.dart';
import '../../core/di/app_di.dart';
import '../../core/session_cubit.dart';
import '../../core/navigation_cubit.dart';

mixin HomeConversationMenuMixin<T extends StatefulWidget> on State<T> { List<ChatMessageData> get messages;
  void onDeleteConversation();

  void toggleFavorite() {
    final sessionId = getIt<SessionCubit>().activeSessionId;
    if (sessionId == null) return;
    getIt<SessionCubit>().toggleFavoriteSession(sessionId);
    final session = getIt<SessionCubit>().sessions
        .where((s) => s.id == sessionId)
        .firstOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          session?.isFavorite == true
              ? localeProvider.t('favorited')
              : localeProvider.t('unfavorited')),
        duration: const Duration(seconds: 2)));
  }

  void shareConversation() {
    final msgs = messages;
    if (msgs.isEmpty) return;
    final text = msgs
        .map(
          (m) => m.role == 'user'
              ? '${localeProvider.t('me')}：${m.content}'
              : '${localeProvider.t('ai')}：${m.content}')
        .join('\n\n');
    SharePlus.instance.share(ShareParams(text: text));
  }

  void showConversationMenu(BuildContext ctx) {
    showMenu<String>(
      context: ctx,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(ctx).size.width - 180,
        MediaQuery.of(ctx).padding.top + 60,
        16,
        0),
      color: AppColors.sf(ctx),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        _menuItem(
          LucideIcons.bookmark,
          localeProvider.t('favorite_conversation'),
          key: 'favorite'),
        _menuItem(
          LucideIcons.share,
          localeProvider.t('share_conversation'),
          key: 'share'),
        _menuItem(
          LucideIcons.search,
          localeProvider.t('search_conversation'),
          key: 'search'),
        _menuItem(
          LucideIcons.shield,
          getIt<NavigationCubit>().isIncognito
              ? localeProvider.t('close_incognito')
              : localeProvider.t('incognito_mode_short'),
          key: 'incognito'),
        _menuItem(
          LucideIcons.trash2,
          localeProvider.t('delete_conversation'),
          key: 'delete',
          isDanger: true),
      ]).then((value) {
      if (value == null || !mounted) return;
      switch (value) {
        case 'favorite':
          toggleFavorite();
        case 'share':
          shareConversation();
        case 'search':
          ChatSearchSheet(messages: messages).show(context);
        case 'incognito':
          getIt<NavigationCubit>().setIsIncognito(!getIt<NavigationCubit>().isIncognito);
        case 'delete':
          onDeleteConversation();
      }
    });
  }

  PopupMenuItem<String> _menuItem(
    IconData icon,
    String text, {
    String? key,
    bool isDanger = false,
  }) {
    return PopupMenuItem<String>(
      value: key ?? text,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDanger ? AppColors.dng(context) : AppColors.sec(context)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDanger
                  ? AppColors.dng(context)
                  : AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w500)),
        ]));
  }
}
