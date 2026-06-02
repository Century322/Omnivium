import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:matrix/matrix.dart';
import '../../../core/di/app_di.dart';
import '../../../core/database_service.dart';
import '../../../core/matrix/matrix_cubit.dart';
import '../../../core/app_logger.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';
import '../../theme/wallpaper_presets.dart';
import '../home_components.dart';
import 'friend_message_bubble.dart';

class FriendChatContentView extends StatelessWidget {
  final List<FriendMessageData> messages;
  final ScrollController scrollController;
  final String chatTargetId;
  final Timeline? timeline;
  final void Function(int index, FriendMessageData msg) onLongPress;

  const FriendChatContentView({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.chatTargetId,
    this.timeline,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final wallpaper = _getWallpaperDecoration();
    if (messages.isEmpty) {
      return Container(
        decoration: wallpaper,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.messageCircle, size: 48, color: AppColors.mut(context)),
              const SizedBox(height: 12),
              Text(localeProvider.t('no_messages_yet'),
                  style: TextStyle(color: AppColors.textTertiary(context), fontSize: 14)),
            ])));
    }
    return Container(
      decoration: wallpaper,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: messages.length,
        itemBuilder: (_, i) {
          final msg = messages[i];
          final showDateHeader = i == 0 || _shouldShowDateSeparator(messages[i - 1], msg);
          return Column(
            children: [
              if (showDateHeader) _buildDateHeader(context, msg.timestamp),
              FriendMessageBubble(
                message: msg,
                index: i,
                onLongPress: () => onLongPress(i, msg),
                isRead: _isMessageRead(msg),
              ),
            ]);
        }));
  }

  BoxDecoration? _getWallpaperDecoration() {
    final db = getIt<DatabaseService>();
    final data = db.getData('chat_wallpaper');
    if (data == null) return null;
    final id = data['id'] as String?;
    if (id == null || id == 'none') return null;
    switch (id) {
      case 'gradient_sunset':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.warm));
      case 'gradient_ocean':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.ocean));
      case 'gradient_forest':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.forest));
      case 'gradient_night':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.dark));
      case 'gradient_rose':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.pink));
      case 'solid_dark':
        return const BoxDecoration(color: WallpaperPresets.darkBg);
      case 'solid_midnight':
        return const BoxDecoration(color: WallpaperPresets.darkBlueBg);
      default:
        return null;
    }
  }

  Widget _buildDateHeader(BuildContext context, DateTime? timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.sfAlt(context),
            borderRadius: BorderRadius.circular(12)),
          child: Text(
            _formatDateHeader(context, timestamp ?? DateTime.now()),
            style: TextStyle(color: AppColors.textTertiary(context), fontSize: 11, fontWeight: FontWeight.w500)))));
  }

  bool _shouldShowDateSeparator(FriendMessageData prev, FriendMessageData curr) {
    final prevTs = prev.timestamp;
    final currTs = curr.timestamp;
    if (prevTs == null || currTs == null) return false;
    return _dateOnly(prevTs) != _dateOnly(currTs);
  }

  String _dateOnly(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatDateHeader(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = _dateOnly(now);
    final yesterday = _dateOnly(now.subtract(const Duration(days: 1)));
    final dateStr = _dateOnly(dt);
    if (dateStr == today) return localeProvider.t('today');
    if (dateStr == yesterday) return localeProvider.t('yesterday');
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  bool _isMessageRead(FriendMessageData msg) {
    if (msg.eventId == null) return false;
    if (!msg.isMe) return false;
    try {
      final mRead = getIt<MatrixCubit>().getRoomNotificationCount(chatTargetId);
      final tl = timeline;
      if (tl == null) return false;
      final events = tl.events;
      if (events.isEmpty) return false;
      final msgIndex = events.indexWhere((e) => e.eventId == msg.eventId);
      if (msgIndex == -1) return false;
      return mRead > 0 && msgIndex < events.length - mRead;
    } catch (e) {
      AppLogger.instance.debug('Read receipt check failed', error: e);
      return false;
    }
  }
}
