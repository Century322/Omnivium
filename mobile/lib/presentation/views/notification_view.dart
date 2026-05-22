import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../../presentation/utils/format_utils.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/notification/app_notification.dart';

class NotificationView extends StatelessWidget {
  final AppProvider provider;
  const NotificationView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('notification_center'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (provider.notification.notifications.isNotEmpty) ...[
            TextButton(
              onPressed: () => provider.notification.markAllAsRead(),
              child: Text(
                t('mark_all_read'),
                style: TextStyle(color: AppColors.accent, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.sf(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      t('clear_all'),
                      style: TextStyle(color: AppColors.textPrimary(context)),
                    ),
                    content: Text(
                      t('clear_all_confirm'),
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t('cancel')),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.dng(context),
                        ),
                        onPressed: () {
                          provider.notification.clear();
                          Navigator.pop(context);
                        },
                        child: Text(t('clear')),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                t('clear_all'),
                style: TextStyle(color: AppColors.dng(context), fontSize: 13),
              ),
            ),
          ],
        ],
      ),
      body: _buildBody(context, t),
    );
  }

  Widget _buildBody(BuildContext context, String Function(String) t) {
    final notifications = provider.notification.notifications;
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.bell,
              size: 48,
              color: AppColors.textDisabled(context),
            ),
            const SizedBox(height: 16),
            Text(
              t('no_notifications'),
              style: TextStyle(
                color: AppColors.textTertiary(context),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, i) => _buildNotificationTile(context, notifications[i]),
    );
  }

  Widget _buildNotificationTile(BuildContext context, AppNotification notif) {
    final icon = notif.type == NotificationType.message
        ? LucideIcons.messageCircle
        : notif.type == NotificationType.invite
        ? LucideIcons.userPlus
        : LucideIcons.bell;
    final iconColor = notif.read
        ? AppColors.iconGray(context)
        : AppColors.accent;
    return Semantics(
      button: true,
      label:
          '${notif.title}${notif.body.isNotEmpty ? ', ${notif.body}' : ''}${notif.read ? '' : ', unread'}',
      child: Dismissible(
        key: Key(notif.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => provider.notification.remove(notif.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.dng(context).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            LucideIcons.trash2,
            color: AppColors.dng(context),
            size: 20,
          ),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => provider.notification.markAsRead(notif.id),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: notif.read
                  ? AppColors.sf(context)
                  : AppColors.sfAlt(context),
              borderRadius: BorderRadius.circular(12),
              border: notif.read
                  ? null
                  : Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                color: notif.read
                                    ? AppColors.textHint(context)
                                    : AppColors.textPrimary(context),
                                fontSize: 14,
                                fontWeight: notif.read
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formatRelativeTime(notif.timestamp),
                            style: TextStyle(
                              color: AppColors.iconGray(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        style: TextStyle(
                          color: AppColors.textHint(context),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!notif.read) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
