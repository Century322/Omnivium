import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_cubit.dart';

class HomeDialogs {
  static void showMoreMenu(
    BuildContext context,
    String content,
    int index, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onReport,
  }) {
    String t(String key) => localeProvider.t(key);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.sf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled(context),
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(LucideIcons.pencil, color: AppColors.sec(context)),
              title: Text(
                t('edit_query'),
                style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              }),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: AppColors.dng(context)),
              title: Text(
                t('delete_message_pair'),
                style: TextStyle(color: AppColors.dng(context))),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              }),
            ListTile(
              leading: Icon(
                LucideIcons.thumbsDown,
                color: AppColors.sec(context)),
              title: Text(
                t('report_not_helpful'),
                style: TextStyle(color: AppColors.textPrimary(context))),
              onTap: () {
                Navigator.pop(context);
                onReport();
              }),
            const SizedBox(height: 8),
          ])));
  }

  static void showPermissionDialog(
    BuildContext context,
    String skillName, {
    required VoidCallback onGrant,
    required VoidCallback onDeny,
  }) {
    String t(String key) => localeProvider.t(key);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              LucideIcons.shieldAlert,
              color: AppColors.warn(context),
              size: 20),
            const SizedBox(width: 8),
            Text(
              t('permission_confirm_title'),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 18)),
          ]),
        content: Text(
          localeProvider
              .t('ai_request_confirm')
              .replaceAll('{action}', skillName),
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeny();
            },
            child: Text(
              t('deny'),
              style: TextStyle(color: AppColors.sec(context)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.acc(context),
              foregroundColor: AppColors.textPrimary(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              onGrant();
            },
            child: Text(
              t('allow'),
              style: TextStyle(fontWeight: FontWeight.w600))),
        ]));
  }

  static void showCreateGroupChat(
    BuildContext context, {
    required Future<void> Function(String name, List<String> members) onCreate,
  }) {
    String t(String key) => localeProvider.t(key);
    final nameCtrl = TextEditingController();
    final membersCtrl = TextEditingController();
    try {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.sf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
          title: Text(
            t('new_group'),
            style: TextStyle(color: AppColors.textPrimary(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                maxLength: 100,
                style: TextStyle(color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                  labelText: t('enter_new_name'),
                  hintStyle: TextStyle(color: AppColors.textDisabled(context)),
                  filled: true,
                  fillColor: AppColors.sfAlt(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(
                controller: membersCtrl,
                maxLength: 512,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14),
                decoration: InputDecoration(
                  labelText: t('enter_matrix_id'),
                  hintStyle: TextStyle(
                    color: AppColors.textDisabled(context),
                    fontSize: 13),
                  filled: true,
                  fillColor: AppColors.sfAlt(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none))),
            ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                t('cancel'),
                style: TextStyle(color: AppColors.sec(context)))),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final members = membersCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                Navigator.pop(context);
                await onCreate(name, members);
              },
              child: Text(
                t('create'),
                style: TextStyle(color: AppColors.acc(context)))),
          ]));
    } finally {
      nameCtrl.dispose();
      membersCtrl.dispose();
    }
  }
}
