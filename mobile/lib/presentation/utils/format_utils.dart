import '../theme/locale_cubit.dart';

String formatRelativeTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return localeProvider.t('just_now');
  if (diff.inHours < 1)
    return '${diff.inMinutes}${localeProvider.t('minutes_ago')}';
  if (diff.inDays < 1) return '${diff.inHours}${localeProvider.t('hours_ago')}';
  if (diff.inDays < 7) return '${diff.inDays}${localeProvider.t('days_ago')}';
  return '${dt.month}/${dt.day}';
}
