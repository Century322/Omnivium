import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/agent/agent_reminder_service.dart';
import '../../core/di/app_di.dart';
import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';

class ReminderListPage extends StatefulWidget {
  const ReminderListPage({super.key});

  @override
  State<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    await ReminderService.instance.init();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = ReminderService.instance;
    final active = service.activeReminders;
    final all = service.allReminders;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.sf(context),
        elevation: 0,
        title: Text(
          localeProvider.t('reminders'),
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w600)),
        iconTheme: IconThemeData(color: AppColors.sec(context)),
      ),
      body: all.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.bell, size: 48, color: AppColors.mut(context)),
                  const SizedBox(height: 12),
                  Text(
                    localeProvider.t('no_reminders'),
                    style: TextStyle(color: AppColors.textTertiary(context), fontSize: 14)),
                ]))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: all.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider(context)),
              itemBuilder: (context, index) {
                final reminder = all[index];
                final isActive = reminder.status == ReminderStatus.active;
                final typeIcon = _typeIcon(reminder.type);
                return Dismissible(
                  key: ValueKey(reminder.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.dng(context),
                    child: Icon(LucideIcons.trash2, color: Colors.white)),
                  onDismissed: (_) async {
                    await service.cancelReminder(reminder.id);
                    if (mounted) setState(() {});
                  },
                  child: ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.accBg(context) : AppColors.sfAlt(context),
                        borderRadius: BorderRadius.circular(12)),
                      child: Icon(typeIcon, size: 20,
                          color: isActive ? AppColors.acc(context) : AppColors.mut(context))),
                    title: Text(
                      reminder.title,
                      style: TextStyle(
                        color: isActive ? AppColors.textPrimary(context) : AppColors.textDisabled(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: isActive ? null : TextDecoration.lineThrough)),
                    subtitle: Text(
                      _formatTriggerTime(reminder.nextTriggerAt),
                      style: TextStyle(color: AppColors.textTertiary(context), fontSize: 12)),
                    trailing: isActive
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accBg(context),
                              borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              localeProvider.t('active'),
                              style: TextStyle(color: AppColors.acc(context), fontSize: 11, fontWeight: FontWeight.w600)))
                        : Icon(LucideIcons.check, size: 16, color: AppColors.ok(context)),
                    onTap: isActive
                        ? () => _showCancelDialog(reminder)
                        : null));
              }));
  }

  IconData _typeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.scheduled:
        return LucideIcons.clock;
      case ReminderType.recurring:
        return LucideIcons.repeat;
      case ReminderType.messageNotification:
        return LucideIcons.messageCircle;
      case ReminderType.aiSmart:
        return LucideIcons.sparkles;
    }
  }

  String _formatTriggerTime(DateTime? time) {
    if (time == null) return localeProvider.t('no_trigger_time');
    final now = DateTime.now();
    final diff = time.difference(now);
    if (diff.isNegative) return localeProvider.t('overdue');
    if (diff.inMinutes < 1) return localeProvider.t('now');
    if (diff.inMinutes < 60) return '${diff.inMinutes}${localeProvider.t('min_later')}';
    if (diff.inHours < 24) return '${diff.inHours}${localeProvider.t('hr_later')}';
    return '${diff.inDays}${localeProvider.t('day_later')}';
  }

  void _showCancelDialog(Reminder reminder) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(localeProvider.t('cancel_reminder'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text('${localeProvider.t("cancel_reminder_confirm")} "${reminder.title}"?',
            style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(localeProvider.t('keep'), style: TextStyle(color: AppColors.textSecondary(context)))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dng(context), foregroundColor: Colors.white),
            onPressed: () async {
              await ReminderService.instance.cancelReminder(reminder.id);
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(localeProvider.t('cancel'))),
        ]));
  }
}
