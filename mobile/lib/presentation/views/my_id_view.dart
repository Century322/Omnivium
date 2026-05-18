import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';

class MyIdView extends StatelessWidget {
  final AppProvider provider;
  const MyIdView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    final matrix = provider.matrix;
    final notLoggedIn = t('not_logged_in_short');
    final userId = matrix.userId ?? notLoggedIn;
    final homeserver = matrix.homeserver ?? '';
    return Scaffold(
      appBar: AppBar( elevation: 0,
        leading: IconButton(tooltip: localeProvider.t('back'), icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)), onPressed: () => Navigator.pop(context)),
        title: Text(t('my_id'), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 24),
          Center(child: Container(width: 100, height: 100,
            decoration: BoxDecoration(color: AppColors.sf(context), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
            child: Center(child: Text(userId != notLoggedIn && userId.isNotEmpty ? userId[1].toUpperCase() : '?',
              style: TextStyle(color: AppColors.accent, fontSize: 42, fontWeight: FontWeight.w700))))),
          const SizedBox(height: 20),
          Text(userId != notLoggedIn ? userId.split(':').first.replaceAll('@', '') : notLoggedIn,
            style: TextStyle(color: AppColors.textPrimary(context), fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(homeserver, style: TextStyle(color: AppColors.iconGray(context), fontSize: 13)),
          const SizedBox(height: 32),
          Container(width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.sf(context), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(localeProvider.t('matrix_id'), style: TextStyle(color: AppColors.textHint(context), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SelectableText(userId, style: TextStyle(color: AppColors.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                icon: Icon(LucideIcons.copy, size: 16), label: Text(t('copy_id')),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: userId));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('id_copied')), duration: const Duration(seconds: 2)));
                },
              )),
            ])),
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.sf(context), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('share_method'), style: TextStyle(color: AppColors.textHint(context), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _shareOption(context, LucideIcons.messageCircle, t('add_via_omnivium'), t('add_via_omnivium_desc')),
              const SizedBox(height: 8),
              _shareOption(context, LucideIcons.link, t('share_via_link'), t('share_via_link_desc')),
              const SizedBox(height: 8),
              _shareOption(context, LucideIcons.qrCode, t('qr_code'), t('qr_code_desc')),
            ])),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _shareOption(BuildContext context, IconData icon, String title, String subtitle) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.sfAlt(context), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.accent)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w500)),
          Text(subtitle, style: TextStyle(color: AppColors.textTertiary(context), fontSize: 12)),
        ])),
        Icon(LucideIcons.chevronRight, size: 16, color: AppColors.iconGray(context)),
      ]));
  }
}
